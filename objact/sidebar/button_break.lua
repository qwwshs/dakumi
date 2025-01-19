--返回上一层
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function will_draw()
    return (not room_type("nil")) and the_room_pos({"edit",'tracks_edit'})
end
local function break_sidebar()
    displayed_content = "nil" --回到主界面
end
objact_button_break = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("break_sidebar",break_sidebar,x,y,w,h,ui:close(x,y,w,h),{will_draw = will_draw})
    end,
    draw = function()
    end,
    keyboard = function(key)
        if key == "escape" then
            break_sidebar() --回到主界面

        end
    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
}