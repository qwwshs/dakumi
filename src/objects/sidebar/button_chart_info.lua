--进入谱面基本信息显示与修改
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
    ui_style:button(x,y,w,h,i18n:get("info"))
end
local function will_do()
    messageBox:add("info")
    sidebar.displayed_content = "info"
    object_chart_info.load(1250,100,0,150,50)
end
object_button_chart_info = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("chart_info",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
    end,
    draw = function()

    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
}