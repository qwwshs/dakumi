local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function will_draw()
    return the_room_pos({"edit",'tracks_edit'})
end
local function do_up()
    track.track = track.track + 1
end
local function do_down()
    track.track = math.abs(track.track - 2) + 1--防止非自然数
end
objact_track = { --改变现在显示的轨道
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1

        input_box_new("track","track.track",x-50,y + h,50,h,{type = "number",will_draw = will_draw})
        button_new("track_up",do_up,x,y,w,h,ui:up(x,y,w,h),{will_draw = will_draw})
        button_new("track_down",do_down,x,y+h,w,h,ui:down(x,y+h,w,h),{will_draw = will_draw})
    end,
    draw = function()
        love.graphics.print(objact_language.get_string_in_languages("track"),x-50,y)
    end,
    keyboard = function(key)
        if key == "right" and mouse.x < 1200 then
            do_up()
        elseif key == "left" and mouse.x < 1200 then
            do_down()
        end

    end,
    mousepressed = function( x1, y1, button, istouch, presses )
    end,
    textinput = function(input)

    end,
    update = function(dt) --数据更新
    end,
}