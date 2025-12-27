--love.graphics.setColor的封装
function setColor(...)
    local args = {...}
    if #args == 3 then
        love.graphics.setColor(args[1],args[2],args[3],1)
    elseif #args == 4 then
        love.graphics.setColor(args[1],args[2],args[3],args[4])
    elseif #args == 1 and type(args[1]) == "table" then
        args[1][4] = args[1][4] or 1
        love.graphics.setColor(args[1])
    elseif #args == 1 and type(args[1]) == "string" then
        local color_str = args[1]
        if color_str:sub(1,1) == '#' then
            color_str = color_str:sub(2)
            local r = 1
            local g = 1
            local b = 1
            local a = 1
            if #color_str == 6 then
                r = tonumber(color_str:sub(1,2),16) / 255
                g = tonumber(color_str:sub(3,4),16) / 255
                b = tonumber(color_str:sub(5,6),16) / 255
                a = 1
            elseif #color_str == 8 then
                r = tonumber(color_str:sub(3,4),16) / 255
                g = tonumber(color_str:sub(5,6),16) / 255
                b = tonumber(color_str:sub(7,8),16) / 255
                a = tonumber(color_str:sub(1,2),16) / 255
            end
            love.graphics.setColor(r,g,b,a)
        else
            --常用颜色表
            if color_str == "white" then
                love.graphics.setColor(1,1,1,1)
            elseif color_str == "black" then
                love.graphics.setColor(0,0,0,1)
            end
        end
        
    end
end