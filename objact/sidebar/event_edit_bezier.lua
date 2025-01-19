local x = 0
local y = 0
local r = 0
local w = 0
local h = 0
local control_point = {} --两个控制点的坐标
local isbutton = false --按住状态
local button_control = 1 -- 按住第几个控制点

objact_event_edit_bezier = { --bezier编辑
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        if not(string.sub(displayed_content,1,5) == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        control_point = {x+w*chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[1],
        y+h-chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[2] *h,
        x+w*chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[3],
        y+h-chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[4] *h,
        }
    end,
    draw = function()
        if not(string.sub(displayed_content,1,5) == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        love.graphics.setColor(0,1,1,1)
        for i = 1,100 do --曲线绘制
            local bezier_y = bezier(1,
            100,
            y + h,
            y,
            chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans,
            i
            )
            local bezier_y_end = bezier(1,
            100,
            y + h,
            y,
            chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans,
            i + 1
            )
            love.graphics.line(w/100 * i +x,bezier_y,w/100 * (i+1) +x,bezier_y_end)
        end
        love.graphics.setColor(1,1,1,1)
        --底线
        love.graphics.rectangle("fill",x,y + h,w,2)

        --侧线
        love.graphics.rectangle("fill",x + w,y,2,h)

        --控制点
        love.graphics.setColor(1,1,1,1)
        love.graphics.circle("line",control_point[1],control_point[2],10)
        love.graphics.circle("line",control_point[3],control_point[4],10)
        love.graphics.line(control_point[1],control_point[2],x,y+h)
        love.graphics.line(control_point[3],control_point[4],x+w,y)
        love.graphics.setColor(1,1,1,0.5)
        if button_control == 1  and isbutton == true then
            love.graphics.circle("fill",control_point[1],control_point[2],10)
        elseif button_control == 2  and isbutton == true then
            love.graphics.circle("fill",control_point[3],control_point[4],10)
        end
    end,
    update = function(dt)
        if not(string.sub(displayed_content,1,5) == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        control_point = {x+w*chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[1],
        y+h-chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[2] *h,
        x+w*chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[3],
        y+h-chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans[4] *h,
        }
        
        local x1 = mouse.x
        local y1 = mouse.y

        if  y1 < y then y1 = y  end ---限制范围
        if x1 <x then   x1 = x  end
        if x1 >x+w then x1 = x + w  end
        if y1 > y + h then  y1 = y + h  end
        if isbutton == true then
            if button_control == 1 then
                control_point[1] = x1
                control_point[2] = y1
                
            else
                control_point[3] = x1
                control_point[4] = y1
            end
        end
        local trans1,trans2,trans3,trans4 = 
        (control_point[1] - x) / w, 1-(control_point[2] - y) / h, (control_point[3] - x) / w, 1-(control_point[4] - y) / h
        trans1 = math.floor(trans1 * 100) / 100
        trans2 = math.floor(trans2 * 100) / 100
        trans3 = math.floor(trans3 * 100) / 100
        trans4 = math.floor(trans4 * 100) / 100
        chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans = {trans1,trans2,trans3,trans4}
    end,
    mousepressed = function(x1,y1)
        if not (y1 >= y - 10 and x1 >= x - 10 and y1 <= y + h + 10 and x1 <= x + w + 10)  then --加减10是为了更好抓取
            return
        end
        isbutton = true
        if (x1- control_point[1]) ^2 +  (y1- control_point[2]) ^ 2 < (x1- control_point[3]) ^2 +  (y1- control_point[4]) ^ 2 then
            button_control = 1
        else
            button_control = 2
        end
    end,
    mousereleased = function(x1,y1)
        isbutton = false
    end
}