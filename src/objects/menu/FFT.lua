local FFT = object:new('FFT')
local loveFFT = require("src.utils.lovefft") -- 引入FFT模块
local fft_start = false

--音频数据读取相关
local audioThread = love.thread.newThread("src/thread/audioThread.lua")
local audioChannel = love.thread.getChannel("audio_channel")
local statusChannel = love.thread.getChannel("status_channel")

--FFt相关
-- 配置参数
local fftSize = 256 -- FFT采样数（必须是2的幂）
local fftArray = {} -- 存储频谱数据的数组
loveFFT:init(fftSize)

function FFT:select_music()
    audioThread:start(menu.musicPath) -- 启动线程并传入音频路径
    fft_start = false
end

function FFT:toedit()
    loveFFT:release()
end

function FFT:update(dt)
    local data = audioChannel:pop()
    local message = statusChannel:pop()
    if message then
        print(message)
    end
    -- 处理不同类型的消息
    if message == "success" then
        loveFFT:setSoundData(data)
        fft_start = true
    elseif message == "error" then     -- 处理错误信息
        log("FFT data load error")
    end

    if not fft_start then return end
    -- 获取当前播放位置并触发FFT计算
    local currentTime = menu.chartInfo.song:tell() -- 获取播放进度
    loveFFT:updatePlayTime(currentTime)

    -- 获取FFT结果（非阻塞）
    local newArray, hasNewData = loveFFT:get()
    fftArray = newArray -- 更新频谱数据
end

function FFT:draw()
    if not fft_start then return end
    local barHeight = WINDOW.nowH / (fftSize / 9) -- 调整条形宽度

    for i = 1, #fftArray do
        -- fftArray[i] 是第i个频段的能量值（0~1之间）
        local barWidth = fftArray[i] * WINDOW.nowW

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.rectangle(
            "fill",
            0,
            (i - 1) * barHeight,
            barWidth, -- 宽度（留一点间隙）
            barHeight -- 高度
        )
    end
end

return FFT
