
--设置
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local type = 'nil'
local ui_github = love.graphics.newImage("asset/github-mark-white.png")
local function will_draw()
    return room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function will_do()
    objact_message_box.message("github")
    love.system.openURL("https://github.com/qwwshs/daikumi_editor/")
end
objact_button_togithub = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("to_github",will_do,x,y,w,h,ui_github,{will_draw = will_draw})
    end,
}