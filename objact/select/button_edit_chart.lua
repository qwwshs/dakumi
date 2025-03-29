
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function draw_this_button()
    ui_style:button(x,y,w,h,objact_language.get_string_in_languages("edit"))
end
local function will_draw()
    return the_room_pos('select')
end
local function will_do()
    love.audio.stop( ) --停止歌曲
    if not chart_info.chart_name[select_chart_pos] then
        objact_message_box.message_window_dlsplay('Not music',function() end,function() end)
        return
    end
    if not chart_info.chart_name[select_chart_pos].is_true_chart then 
        objact_message_box.message_window_dlsplay('Error chart',function() end,function() end)
        return
    end
    if not chart_info.chart_name[select_chart_pos] then
        objact_message_box.message_window_dlsplay('Create a chart first',function() end,function() end)
        return
    end
    local find_form = false
    for i = 1,#chart.event do
        if chart.event[i].form then --遗留问题 当时打错字了
            chart.event[i].from = chart.event[i].form --更新
            chart.event[i].form = nil
            find_form = true
        end
    end
    if find_form then
        save(chart,'chart.d3')
    end

    room_pos = 'edit' --进入编辑
    love.window.setTitle(chart.info.song_name.."-"..chart.info.chart_name)
end
objact_edit_chart = { --进入谱面用的
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("edit_chart",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
    end,
    draw = function()

    end,
    mousepressed = function( x1, y1, button, istouch, presses )
    end,
}