
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function draw_this_button()
    ui_style:button(x,y,w,h,objact_language.get_string_in_languages("new chart"))
end
local function will_draw()
    return the_room_pos('select')
end
local function will_do()
        objact_message_box.message("new_chart")
        local name = "chart/"..chart_tab[select_music_pos].."/new_chart"
        while love.filesystem.getInfo( name..".d3" )  do
            name = name .."_new"
        end

        local file = love.filesystem.newFile(name..".d3")
        file:open("w") --为了创建谱面
        file:write(tableToString(meta_chart.__index)) --初始化
        file:close()
        chart_info.chart_name =  {}
        select_music()
end

objact_new_chart = { --分度改变用的
load = function(x1,y1,r1,w1,h1)
    x= x1 --初始化
    y = y1
    w = w1
    h = h1
    r = r1
    button_new("new_chart",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
end,
draw = function()
end,
mousepressed = function( x1, y1, button, istouch, presses )
    
end,
}
