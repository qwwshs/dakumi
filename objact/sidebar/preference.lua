--子房间 就写成对象了
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local input_type = false --输入状态
local type = "preference"
local ui_break = love.graphics.newImage("asset/ui_break.png")
local preference_pos_y = 0 --位移
local offset_x_ed = 0 --旧的偏移值
local function will_draw()
    return room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function input_ed() --记录旧的偏移
    offset_x_ed = chart.preference.x_offset
end

local function input_ed_finish() --应用偏移
    local function yes_offset()
        for i = 1,#chart.event do
            if chart.event[i].type == "x" then
                chart.event[i].from = chart.event[i].from - chart.preference.x_offset + offset_x_ed
                chart.event[i].to = chart.event[i].to - chart.preference.x_offset + offset_x_ed
            end
        end
    end
    objact_message_box.message_window_dlsplay("Whether to offset the previously written event value", yes_offset,function() end)
end

objact_preference = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        preference_pos_y = 0
        if not room_type(type) then
            return
        else

            input_box_new("x_offset","chart.preference.x_offset",x,y+40 + preference_pos_y,w,20,{type ="string",will_draw = will_draw,input_ed = input_ed, input_ed_finish = input_ed_finish})
        end

        
    end,
    draw = function()
        if not room_type(type) then
            return
        end
        

        love.graphics.setColor(1,1,1,1)
        love.graphics.print(objact_language.get_string_in_languages("x_offset"),x,y+20 + preference_pos_y) 
    end,
    mousepressed = function( x1, y1, button, istouch, presses )
    end,
    keypressed = function(key)
        if not room_type(type) then
            return
        end

        
    end,
    wheelmoved = function(x,y)
        if not room_type(type) then
            return
        end
        local scroll = 40
        if y < 0 then
            scroll = - scroll
        end
        input_box_wheelmoved(x,scroll,"x_offset")
        preference_pos_y = preference_pos_y + scroll
    end
}