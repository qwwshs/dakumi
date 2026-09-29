--[[
    模块名: spectrogramConfig
    描述: 声纹图参数校验、频率坐标和固定采样网格；不依赖界面或用户文件。
]]
local Config = {}

Config.defaults = {
    spectrogram_mode = 'harmonics', spectrogram_window = 'hann',
    spectrogram_scale = 'pitch', spectrogram_min_hz = 40, spectrogram_max_hz = 12000,
    spectrogram_floor_db = -84, spectrogram_ceiling_db = 0, spectrogram_gain_db = 0,
    spectrogram_opacity = 90, spectrogram_ruler = 1,
}

-- 步长以采样点计。长窗口提高分音能力；短窗口更适合判断鼓点起止。
Config.profiles = {
    transient = {size = 2048, hop = 128},
    balanced = {size = 4096, hop = 128},
    harmonics = {size = 16384, hop = 128},
    bass = {size = 32768, hop = 256},
}

local function number(value, default, low, high)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then value = default end
    return math.max(low, math.min(high, value))
end

function Config.read(source, sampleRate)
    source = source or {}
    local d, out = Config.defaults, {}
    local mode = source.spectrogram_mode
    out.mode = Config.profiles[mode] and mode or d.spectrogram_mode
    out.size, out.hop = Config.profiles[out.mode].size, Config.profiles[out.mode].hop
    out.window = source.spectrogram_window == 'blackman_harris' and 'blackman_harris' or 'hann'
    local scale = source.spectrogram_scale
    out.scale = (scale == 'linear' or scale == 'log') and scale or 'pitch'
    local nyquist = math.max(2, (sampleRate or 384000) / 2)
    out.minHz = number(source.spectrogram_min_hz, d.spectrogram_min_hz, 1, nyquist - 1)
    out.maxHz = number(source.spectrogram_max_hz, d.spectrogram_max_hz, 2, nyquist)
    if out.maxHz <= out.minHz then
        out.minHz = math.max(1, math.min(out.minHz, out.maxHz / 2))
    end
    out.floor = number(source.spectrogram_floor_db, d.spectrogram_floor_db, -180, -6)
    out.ceiling = number(source.spectrogram_ceiling_db, d.spectrogram_ceiling_db, -120, 12)
    if out.ceiling < out.floor + 6 then out.ceiling = out.floor + 6 end
    out.gain = number(source.spectrogram_gain_db, d.spectrogram_gain_db, -48, 48)
    out.opacity = number(source.spectrogram_opacity, d.spectrogram_opacity, 0, 100) / 100
    out.ruler = source.spectrogram_ruler ~= 0
    return out
end

function Config.sanitize(source)
    local o = Config.read(source)
    source.spectrogram_mode, source.spectrogram_window, source.spectrogram_scale = o.mode, o.window, o.scale
    source.spectrogram_min_hz, source.spectrogram_max_hz = o.minHz, o.maxHz
    source.spectrogram_floor_db, source.spectrogram_ceiling_db, source.spectrogram_gain_db = o.floor, o.ceiling, o.gain
    source.spectrogram_opacity, source.spectrogram_ruler = o.opacity * 100, o.ruler and 1 or 0
end

function Config.frequency(o, position)
    if o.scale == 'linear' then return o.minHz + (o.maxHz - o.minHz) * position end
    return o.minHz * (o.maxHz / o.minHz) ^ position
end

function Config.position(o, frequency)
    if o.scale == 'linear' then return (frequency - o.minHz) / (o.maxHz - o.minHz) end
    return math.log(frequency / o.minHz) / math.log(o.maxHz / o.minHz)
end

function Config.midi(frequency) return 69 + 12 * math.log(frequency / 440) / math.log(2) end
function Config.hz(midi) return 440 * 2 ^ ((midi - 69) / 12) end

local names = {'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'}
function Config.pitchName(frequency)
    local midi = Config.midi(frequency)
    local nearest = math.floor(midi + 0.5)
    return string.format('%s%d %+.0fct', names[nearest % 12 + 1], math.floor(nearest / 12) - 1,
        (midi - nearest) * 100), midi
end

-- 一个显示格可汇总连续的若干 STFT 帧。缩小时逐帧取峰值，避免跳过短促声音。
function Config.cellAt(seconds, sampleRate, hop, step)
    return math.floor((seconds * sampleRate / hop + 0.5) / step)
end

return Config
