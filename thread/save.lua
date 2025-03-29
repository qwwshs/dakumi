serpent = require("function/serpent") --lua序列化
require("function/save")
require("function/log")
require("function/table")
require("function/string")
require("function/note")
require("function/event")
require("function/beat_and_time")
require("love.timer")
require("objact/meta")
chart = {}
path = ""
local the_save_start = false --减少休眠时间
        setmetatable(chart,meta_chart) --防谱报废
        fillMissingElements(chart,meta_chart.__index)

--线程用来保存的

function love.threaderror(thread, message)  
    print("Thread error: " .. message)  
end  

-- 获取主线程传递的频道  
local channel = ...  

function extractBetweenSlashes(str) -- 提取两个斜杠之间的内容
    local lastSlash = str:match(".*()/")
    if not lastSlash then return nil end  -- 如果没有斜杠，返回nil
    
    local secondLastSlash = str:sub(1, lastSlash - 1):match(".*()/")
    if not secondLastSlash then return nil end  -- 如果只有一个斜杠，返回nil
    
    return str:sub(secondLastSlash + 1, lastSlash - 1)
end


-- 从主线程接收消息  
while true do  
    local msg = love.thread.getChannel( 'save' ):pop()  --得到表
    
    if msg and msg[1] == 'start' then  
        path = msg[2]
        log("save:"..msg[1])
        the_save_start = true
    elseif msg and msg[1] == 'end' then
        the_save_start = false
        fillMissingElements(chart,meta_chart.__index)
        if type(path) == "string" and #path > 0 then
            local s = love.filesystem.write(path , tableToString(chart) )
            local nowdate = os.date("%Y-%m-%d %H %M %S")

            love.filesystem.newFile('auto_save/'..nowdate.."music "..extractBetweenSlashes(path)..".d3")
            log(love.filesystem.write('auto_save/'..nowdate.."music "..extractBetweenSlashes(path)..".d3" , tableToString(chart) ))
            if s then
                log("save:"..tostring(s))
            end
            love.thread.getChannel( 'save completed' ):push(s)
        end
        log("save:"..msg[1])
        
    elseif msg and msg[1] and msg[2] then
        loadstring("chart."..msg[1].." = "..msg[2])() --执行
    end 
    if not the_save_start then
        love.timer.sleep(1)
    else
        love.timer.sleep(0.001)
    end
end