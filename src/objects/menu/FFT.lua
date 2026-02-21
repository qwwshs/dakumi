local FFT = object:new('FFT')
local loveFFT = require("src.utils.lovefft") -- 引入FFT模块
local fft_start = false

--音频数据读取相关
local audioThread = love.thread.newThread("src/thread/audioThread.lua")
local audioChannel = love.thread.getChannel("audio_channel")
local statusChannel = love.thread.getChannel("status_channel")

--FFt相关
-- 配置参数
local fftSize = 1024 -- FFT采样数（必须是2的幂）
local fftArray = {}  -- 存储频谱数据的数组
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
    elseif message == "error" then -- 处理错误信息
        log("FFT data load error")
    end

    if not fft_start then return end
    -- 获取当前播放位置并触发FFT计算
    local currentTime = math.min(menu.chartInfo.song:tell(), menu.chartInfo.song:getDuration()) -- 获取播放进度
    local s = pcall(function() loveFFT:updatePlayTime(currentTime) end)                         -- 更新播放时间并触发FFT计算，使用pcall捕获可能的错误
    if not s then
        fft_start = false
        loveFFT:release()
        return
    end
    -- 获取FFT结果（非阻塞）
    local s, newArray, hasNewData = pcall(function() return loveFFT:get() end)
    if newArray then
        fftArray = newArray -- 更新频谱数据
    end
    if not s then
        fft_start = false
        loveFFT:release()
    end
end

function FFT:draw()
    if not fft_start then return end
    local barHeight = WINDOW.nowH / (fftSize / 10) -- 调整条形宽度
    love.graphics.setColor(menu.color.fft)
    for i = 1, #fftArray - 1 do
        -- fftArray[i] 是第i个频段的能量值（0~1之间）
        local barWidth = fftArray[i] * WINDOW.nowW
        local barWidth_next = fftArray[i + 1] * WINDOW.nowW
        love.graphics.line(barWidth, (i - 1) * barHeight + 1, barWidth_next, i * barHeight) --各点之间连线 +1 为了避免重合
    end
end

return FFT
