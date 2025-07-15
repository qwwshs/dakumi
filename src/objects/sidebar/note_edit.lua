 local x = 0
local y = 0
local r = 0
local w = 0
local h = 0
local function get_displayed_content_1_4() --得到界面
    return string.sub(sidebar.displayed_content,1,4)
end
local function will_draw()
    return get_displayed_content_1_4() == "note" and the_room_pos({"edit",'tracks_edit'})
end
local function input_ed()
    sidebar.displayed_content = "nil"
    note_sort()
end
object_note_edit = {  --编辑界面
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        messageBox:add(get_displayed_content_1_4())
        if not(get_displayed_content_1_4() == "note") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        input_box_new(get_displayed_content_1_4().."track","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].track",x +140 ,y+50,110,30,{type = "number",will_draw = will_draw})
        input_box_new(get_displayed_content_1_4().."beat_start1","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].beat[1]",x + 140,y + 100,30,30,{type = "number",will_draw = will_draw,input_ed_finish = input_ed})
        input_box_new(get_displayed_content_1_4().."beat_start2","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].beat[2]",x + 180,y + 100,30,30,{type = "number",will_draw = will_draw,input_ed_finish = input_ed})
        input_box_new(get_displayed_content_1_4().."beat_start3","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].beat[3]",x + 220,y + 100,30,30,{type = "number",will_draw = will_draw,input_ed_finish = input_ed})
        if chart.note[tonumber(string.sub(sidebar.displayed_content,5,#sidebar.displayed_content))].type == "hold" then
            input_box_new(get_displayed_content_1_4().."beat_end1","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].beat2[1]",x + 140,y + 150,30,30,{type = "number",will_draw = will_draw,input_ed_finish = input_ed})
            input_box_new(get_displayed_content_1_4().."beat_end2","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].beat2[2]",x + 180,y + 150,30,30,{type = "number",will_draw = will_draw,input_ed_finish = input_ed})
            input_box_new(get_displayed_content_1_4().."beat_end3","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].beat2[3]",x + 220,y + 150,30,30,{type = "number",will_draw = will_draw,input_ed_finish = input_ed})
        else
            input_box_delete(get_displayed_content_1_4().."beat_end1")
            input_box_delete(get_displayed_content_1_4().."beat_end2")
            input_box_delete(get_displayed_content_1_4().."beat_end3")
        end
        if not chart.note[tonumber(string.sub(sidebar.displayed_content,5,#sidebar.displayed_content))].fake then
            chart.note[tonumber(string.sub(sidebar.displayed_content,5,#sidebar.displayed_content))].fake = 0
        end
        switch_new(get_displayed_content_1_4().."fake","chart.note["..string.sub(sidebar.displayed_content,5,#sidebar.displayed_content).."].fake",x +140,y + 200,110,30,1,{will_draw = will_draw})
    end,
    draw = function() -- sidebar里的
        if not(get_displayed_content_1_4() == "note") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        if not chart.note[tonumber(string.sub(sidebar.displayed_content,5,#sidebar.displayed_content))] then
            sidebar.displayed_content = 'nil'
            return
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(i18n:get("track"),x+40,y+50)
        love.graphics.print(i18n:get("beat_start"),x+40,y+100)
        if chart.note[tonumber(string.sub(sidebar.displayed_content,5,#sidebar.displayed_content))].type == "hold" then
            love.graphics.print(i18n:get("beat_end"),x+40,y+150)
        end
        love.graphics.print(i18n:get("fake"),x+40,y+200)
        if chart.note[tonumber(string.sub(sidebar.displayed_content,5,#sidebar.displayed_content))].fake == 0 then
            love.graphics.setColor(0,1,1,0.8)
            love.graphics.print(i18n:get("true"),x+100,y+200)
        else
            love.graphics.setColor(1,0,0,0.8)
            love.graphics.print(i18n:get("false"),x+100,y+200)
        end
    end,
}