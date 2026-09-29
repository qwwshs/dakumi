--[[
    模块名: spectrogramAnalyzer
    描述: LuaJIT/FFI 短时傅里叶分析。输出完整单边线性功率，不进行调色、压缩频率或截断分贝。
    帧中心固定为 frame * hop，音频首尾补零。左右声道合并能量，反相音频不会抵消。
]]
local Config = require('src.services.spectrogramConfig')
local Analyzer = {}
Analyzer.__index = Analyzer
local hasFFI, ffi = pcall(require, 'ffi')

function Analyzer.array(size, kind)
    if hasFFI then return ffi.new((kind or 'float') .. '[?]', size) end
    local result = {}
    for i = 0, size - 1 do result[i] = 0 end
    return result
end

function Analyzer.new(mode, window)
    local p = Config.profiles[mode] or Config.profiles.harmonics
    local size = p.size
    local self = setmetatable({size = size, hop = p.hop, bins = size / 2 + 1,
        window = Analyzer.array(size, 'double'), reverse = Analyzer.array(size, 'int'),
        real = Analyzer.array(size, 'double'), imaginary = Analyzer.array(size, 'double'),
        cosine = Analyzer.array(size / 2, 'double'), sine = Analyzer.array(size / 2, 'double')}, Analyzer)
    local sum = 0
    for i = 0, size - 1 do
        local phase = 2 * math.pi * i / size
        local w = 0.5 - 0.5 * math.cos(phase)
        if window == 'blackman_harris' then
            w = 0.35875 - 0.48829 * math.cos(phase) + 0.14128 * math.cos(2 * phase) - 0.01168 * math.cos(3 * phase)
        end
        self.window[i], sum = w, sum + w
        local value, reversed, remaining = i, 0, size
        while remaining > 1 do
            reversed, value, remaining = reversed * 2 + value % 2, math.floor(value / 2), remaining / 2
        end
        self.reverse[i] = reversed
    end
    for i = 0, size / 2 - 1 do
        self.cosine[i], self.sine[i] = math.cos(2 * math.pi * i / size), -math.sin(2 * math.pi * i / size)
    end
    self.gainSquared = (2 / sum) ^ 2
    return self
end

function Analyzer:analyze(sound, frame, output, offset)
    output, offset = output or Analyzer.array(self.bins), offset or 0
    local center = frame * self.hop
    local size, count, channels = self.size, sound:getSampleCount(), sound:getChannelCount()
    if center < 0 or center >= count then
        for bin = 0, self.bins - 1 do output[offset + bin] = 0 end
        return output
    end
    if self.source ~= sound then
        self.source, self.pointer = sound, nil
        if hasFFI and sound.getPointer and sound.getBitDepth then
            self.bits = sound:getBitDepth()
            if self.bits == 8 or self.bits == 16 then
                self.pointer = ffi.cast(self.bits == 16 and 'const int16_t*' or 'const uint8_t*', sound:getPointer())
            end
        end
    end
    local real, imaginary, pointer = self.real, self.imaginary, self.pointer
    for i = 0, size - 1 do
        local position, left, right = center - size / 2 + i, 0, 0
        if position >= 0 and position < count then
            if pointer then
                local index = position * channels
                left, right = pointer[index], channels >= 2 and pointer[index + 1] or 0
                if self.bits == 16 then
                    left, right = left / 32767, right / 32767
                else
                    left, right = (left - 128) / 127, channels >= 2 and (right - 128) / 127 or 0
                end
            else
                left = sound:getSample(position, 1)
                if channels >= 2 then right = sound:getSample(position, 2) end
            end
        end
        local target, w = self.reverse[i], self.window[i]
        real[target], imaginary[target] = left * w, right * w
    end
    local length = 2
    while length <= size do
        local half, stride = length / 2, size / length
        for first = 0, size - 1, length do
            for j = 0, half - 1 do
                local a, b, twiddle = first + j, first + j + half, j * stride
                local shiftedReal = self.cosine[twiddle] * real[b] - self.sine[twiddle] * imaginary[b]
                local shiftedImaginary = self.sine[twiddle] * real[b] + self.cosine[twiddle] * imaginary[b]
                real[b], imaginary[b] = real[a] - shiftedReal, imaginary[a] - shiftedImaginary
                real[a], imaginary[a] = real[a] + shiftedReal, imaginary[a] + shiftedImaginary
            end
        end
        length = length * 2
    end
    for bin = 0, self.bins - 1 do
        local energy = real[bin] * real[bin] + imaginary[bin] * imaginary[bin]
        local edge = bin == 0 or bin == size / 2
        if channels >= 2 then
            if edge then
                energy = energy * 0.5
            else
                local mirror = size - bin
                energy = (energy + real[mirror] * real[mirror] + imaginary[mirror] * imaginary[mirror]) * 0.25
            end
        end
        -- 满幅、整频点正弦的峰为 0 dBFS；直流与奈奎斯特频点不能乘双边补偿。
        output[offset + bin] = energy * self.gainSquared * (edge and 0.25 or 1)
    end
    return output
end

return Analyzer
