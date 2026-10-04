local AudioService = require('src.services.audioService')
--[[
    插件名: fft
    描述: FFT 频谱分析器插件，在菜单界面绘制音频频谱图
    作者: qwwshs
    版本: 1.0.0
    依赖: lovefft, AudioService, menu, WINDOW

    复用音频服务的解码数据，使用 FFT 计算频谱并在菜单界面中绘制。
    当用户选择音乐时自动启动频谱分析。
]]

local FFT = object:new('FFT')
local loveFFT = require("src.utils.lovefft")

--- 是否已启动频谱分析
local fft_start = false

local boundData

-- FFT 配置
local fftSize = 1024  -- FFT 采样数（必须是 2 的幂）
local fftArray = {}   -- 频谱数据数组
loveFFT:init(fftSize)

--- 当用户选择音乐时调用，启动音频加载线程
function FFT:select_music()
    boundData, fft_start, fftArray = nil, false, {}
    AudioService:requestSoundData()
end

--- 进入编辑模式后停止分析，保留唯一 FFT 工作线程供返回菜单时复用。
function FFT:toedit()
    boundData, fft_start, fftArray = nil, false, {}
end

--- 每帧更新：从线程获取 FFT 数据
function FFT:update(dt)
    local data = AudioService:getSoundData()
    if data ~= boundData then
        boundData, fft_start = data, false
        if data then
            fft_start = pcall(function() loveFFT:setSoundData(data) end)
            if not fft_start then log('FFT data load error') end
        end
    end
    if not fft_start or data:getSampleCount() < fftSize then return end
    local currentTime = math.min(AudioService:getAudioTime(),
        (data:getSampleCount() - fftSize) / data:getSampleRate())
    local success = pcall(function() loveFFT:updatePlayTime(currentTime) end)
    if not success then
        fft_start = false
        loveFFT:release()
        return
    end

    -- 获取 FFT 结果（非阻塞）
    local s, newArray, hasNewData = pcall(function() return loveFFT:get() end)
    if newArray then
        fftArray = newArray
    end
    if not s then
        fft_start = false
        loveFFT:release()
    end
end

--- 绘制频谱图
function FFT:draw()
    if not fft_start then return end
    local barHeight = WINDOW.nowH / (fftSize / 10)
    love.graphics.setColor(menu.color.white_half)
    for i = 1, #fftArray - 1 do
        local barWidth = fftArray[i] * WINDOW.nowW
        local barWidth_next = fftArray[i + 1] * WINDOW.nowW
        love.graphics.line(barWidth, (i - 1) * barHeight + 1, barWidth_next, i * barHeight)
    end
end

-- 注册信息由 plugins/init.lua 读取；生命周期仍使用对象的冒号方法。
FFT.plugin = {
    name = 'fft',
    version = '1.0.0',
    target = 'menu',
    layer = 30,
}

return FFT
