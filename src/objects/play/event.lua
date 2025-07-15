local x = 0
local y = 0
local r = 0
local w = 0
local h = 0
object_event = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
    end,
    draw = function()

    end,
    keyboard = function(key)
        if not(mouse.x >= 1000 and mouse.x <= 1175 and mouse.y >= 100) then --不在轨道范围内
            return
        end
        if key == "e" and mouse.x >= 1000 and mouse.x <= 1100 then -- x
            event_place("x",mouse.y)
            messageBox:add("event x place")
        elseif key == "e" and mouse.x >= 1100 and mouse.x <= 1175 then -- w
            event_place("w",mouse.y)
            messageBox:add("event w place")

        elseif key == "d" and mouse.x >= 1000 and mouse.x <= 1100 then -- x delete
                event_delete("x",mouse.y)
                messageBox:add("event x place")
        elseif key == "d" and mouse.x >= 1100 and mouse.x <= 1175 then -- w delete
                event_delete("w",mouse.y)
                messageBox:add("event w place")
        end
    end,
    mousepressed = function(x,y)
        if not(mouse.x >= 1000 and mouse.x <= 1175 and mouse.y >= 100) then --不在轨道范围内
            return
        end
        if  mouse.x >= 1000 and mouse.x <= 1100 then -- x
            event_click("x",mouse.y)
            messageBox:add("event x click")
        elseif  mouse.x >= 1100 and mouse.x <= 1175 then -- w
            event_click("w",mouse.y)
            messageBox:add("event w click")
        end
    end
}