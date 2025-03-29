--不再使用
--[[
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local ui_open = love.graphics.newImage("asset/ui_open_file_selector.png")
local function will_draw()
    return the_room_pos('select')
end
local function will_do()
    objact_message_box.message("open file")
        objact_selector.open() --打开文件选择器
end
objact_select_file = { --打开文件选择器的按钮用的
load = function(x1,y1,r1,w1,h1)
    x= x1 --初始化
    y = y1
    w = w1
    h = h1
    r = r1
    button_new("select_file",will_do,x,y,w,h,ui_open,{will_draw = will_draw})
end,
draw = function()
end,
mousepressed = function( x1, y1, button, istouch, presses )

end,
}
]]
