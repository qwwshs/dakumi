-- 后台解码只返回当前任务的结果，不持有应用状态或共享的命名通道。
require('love.sound')
local input, output = ...
local ok, data = pcall(love.sound.newSoundData, input)
if ok then output:push({data = data})
else output:push({error = tostring(data)}) end
