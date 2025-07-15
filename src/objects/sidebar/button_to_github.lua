
--设置
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local type = 'nil'
local ui_github = isImage.github
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function will_do()
    messageBox:add("github")
    love.system.openURL("https://github.com/qwwshs/daikumi_editor/")
end
object_button_togithub = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("to_github",will_do,x,y,w,h,ui_github,{will_draw = will_draw})
    end,
}