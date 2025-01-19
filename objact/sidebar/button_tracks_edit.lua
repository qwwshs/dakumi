--进入谱面基本信息显示与修改
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local type = "nil"
local function will_draw()
    return room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function draw_this_button()
    ui_style:button(x,y,w,h,objact_language.get_string_in_languages("tracks_edit"))
end
local function will_do()
    objact_message_box.message("tracks_edit")
    displayed_content = "tracks_edit"
    room_pos = "tracks_edit"
    objact_tracks_edit.load(1250,0,0,400,800)
end
objact_button_tracks_edit = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("tracks_edit",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
    end,
    draw = function()

    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
}