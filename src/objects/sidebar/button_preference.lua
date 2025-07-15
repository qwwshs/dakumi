--偏好
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local type = "nil"
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function draw_this_button()
    ui_style:button(x,y,w,h,i18n:get("preference"))
end
local function will_do()
    messageBox:add("preference")
    sidebar.displayed_content = "preference"
    object_preference.load(1250,100,0,150,50)
end
object_button_preference = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("preference",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
    end,
    draw = function()

    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
}