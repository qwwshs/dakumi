require "love.filesystem"
require "love.sound"
-- 获取传入的参数
local audioPath = ...

-- 获取通信通道
local audioChannel = love.thread.getChannel("audio_channel")
local statusChannel = love.thread.getChannel("status_channel")

statusChannel:push("Loading audio: " .. audioPath)

-- 检查文件是否存在
local fileInfo = love.filesystem.getInfo(audioPath)
if not fileInfo then
    statusChannel:push("error:file not found: " .. audioPath)
    return
end

-- 尝试加载音频
local success,audioSource,result
success,result = pcall(function() audioSource = love.sound.newSoundData(audioPath) end) 
if success and audioSource then
    -- 加载成功，发送音频数据
    audioChannel:push(audioSource)
    statusChannel:push("success")
else
    statusChannel:push("error: "..result)
end