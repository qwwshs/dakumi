--设置
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local type = 'nil'
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function draw_this_button()
    ui_style:button(x,y,w,h,i18n:get("settings"))
end
local function will_do()
    messageBox:add("settings")
    sidebar.displayed_content = "settings"
    object_settings.load(1250,100,0,150,50)
end
object_button_settings = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("settings",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
    end,
    draw = function()

    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
}