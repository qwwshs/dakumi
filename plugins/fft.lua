--[[
    插件名: fft
    描述: FFT 频谱分析器插件，在菜单界面绘制音频频谱图
    作者: qwwshs
    版本: 1.0.0
    依赖: lovefft, love.thread, menu, WINDOW

    在独立线程中加载音频数据，使用 FFT 计算频谱并在菜单界面中绘制。
    当用户选择音乐时自动启动频谱分析。
]]

local FFT = object:new('FFT')
local loveFFT = require("src.utils.lovefft")

--- 是否已启动频谱分析
local fft_start = false

-- 音频加载线程
local audioThread = love.thread.newThread("src/thread/audioThread.lua")
local audioChannel = love.thread.getChannel("audio_channel")
local statusChannel = love.thread.getChannel("status_channel")

-- FFT 配置
local fftSize = 1024  -- FFT 采样数（必须是 2 的幂）
local fftArray = {}   -- 频谱数据数组
loveFFT:init(fftSize)

--- 当用户选择音乐时调用，启动音频加载线程
function FFT:select_music()
    audioThread:start(menu.musicPath)
    fft_start = false
end

--- 释放 FFT 资源（进入编辑模式时调用）
function FFT:toedit()
    loveFFT:release()
end

--- 每帧更新：从线程获取 FFT 数据
function FFT:update(dt)
    -- 检查线程状态
    local data = audioChannel:pop()
    local message = statusChannel:pop()

    if message then
        print(message)
    end

    -- 处理线程消息
    if message == "success" then
        local success = pcall(function() loveFFT:setSoundData(data) end)
        if not success then
            log("FFT data load error")
            return
        end
        fft_start = true
    elseif message == "error" then
        log("FFT data load error")
    end

    if not fft_start then return end

    -- 获取当前播放位置并触发 FFT 计算
    if not menu.chartInfo.song then return end
    local currentTime = math.min(menu.chartInfo.song:tell(), menu.chartInfo.song:getDuration())
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
