local message = {} -- 消息列表
message_window = false --打开窗口状态
local window_func = nil --消息框的函数
local window_func_no = nil --消息框的函数 如果选择否
local window_str = ""
--消息框
objact_message_box = {
    draw = function()
        if not demo_mode then
            for i = 1,#message do
                local alpha = 0.75 - 0.75 * easings.easings_use_string.out_cubic((elapsed_time-message[i][2]) /3) --透明度
                local x =-100+ 100 * easings.easings_use_string.out_cubic(math.min((elapsed_time-message[i][2]),0.5) /0.5) --透明度

                love.graphics.setColor(0.3,0.3,0.3,alpha)  -- 背景板
                love.graphics.rectangle("fill",x,300 +  (#message - i) * 35,#message[i][1]*10 + 20,25)
                love.graphics.setColor(1,1,1,alpha)  -- 背景板
                love.graphics.rectangle("line",x,295 +  (#message - i) * 35,#message[i][1]*10 + 10 + 20,35)

                love.graphics.setColor(1,1,1,alpha)  --文字
                love.graphics.print(message[i][1],x + 20,300 + (#message - i) * 35)
            end
        end
        if message_window then --消息框
            love.graphics.setColor(0,0,0,0.9)
            love.graphics.rectangle("fill",600,300,400,200)
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line",600,300,400,200)
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(window_str,600,310,400,"center")
            love.graphics.print("Y",700,450)
            love.graphics.print("N",900,450)

            if mouse.x < 800 and mouse.x > 600 and mouse.y >= 400 and mouse.y <= 500 then --鼠标所在位置的选项高亮
                love.graphics.setColor(0,1,1,0.5) --Y
                love.graphics.rectangle("fill",600,450,200,50)
                love.graphics.setColor(0,1,1,1) --Y
                love.graphics.rectangle("line",600,450,200,50)
            elseif mouse.x < 1000 and mouse.x > 800 and mouse.y >= 400 and mouse.y <= 500 then
                love.graphics.setColor(1,0,0,0.5) --N
                love.graphics.rectangle("fill",800,450,200,50)
                love.graphics.setColor(1,0,0,1) --N
                love.graphics.rectangle("line",800,450,200,50)
            end
            
        end
    end,
    message = function(mess) -- 增加信息
        message[#message + 1] = {objact_language.get_string_in_languages(tostring(mess)),elapsed_time}

        for i = 1,#message do
            if message[i] and message[i][2] - elapsed_time <= -3 then --时间超过三秒
                table.remove(message,i)
            end
        end
        
    end,
    update = function(dt)

    end,
    message_window_dlsplay = function(str,func,func_no) --打开一个消息盒子
        demo_mode = false --关闭演示模式
        message_window = true
        window_str = objact_language.get_string_in_languages(tostring(str))
        window_func = func
        window_func_no = func_no
    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        if message_window  and x1 >= 600 and x1 <= 800 and y1 >= 400 and y1 <= 500 then
            message_window = false
            window_func()
        elseif message_window  and x1 >= 800 and x1 <= 1000 and y1 >= 400 and y1 <= 500 then
            message_window = false
            window_func_no()
        end
    end,
}