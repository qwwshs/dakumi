local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function will_draw()
    return the_room_pos({"edit",'tracks_edit'}) and not demo_mode
end
local function do_up()
    music_speed = music_speed + 0.1
end
local function do_down()
    music_speed = math.max(music_speed - 0.1,0.1)
end
local function input_ed_finish()
    if music_speed <= 0 then
        music_speed = 1
    end
end
objact_music_speed = { --分度改变用的
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        input_box_new("music_speed","music_speed",x-50,y + h,50,h,{type = "number",will_draw = will_draw,input_ed_finish = input_ed_finish})
        button_new("speed_up",do_up,x,y,w,h,ui:up(x,y,w,h),{will_draw = will_draw})
        button_new("speed_down",do_down,x,y+h,w,h,ui:down(x,y+h,w,h),{will_draw = will_draw})
    end,
    draw = function()
        love.graphics.print(objact_language.get_string_in_languages("music_speed"),x-80,y)

    end,
    keyboard = function(key)
    end,
    mousepressed = function( x1, y1, button, istouch, presses )
    end,
    update = function(dt)
    end,
    textinput = function(input)
    end
}