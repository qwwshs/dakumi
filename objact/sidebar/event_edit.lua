local x = 0
local y = 0
local r = 0
local w = 0
local h = 0
local function get_displayed_content_1_5() --得到现在界面的前5个字符
    return string.sub(displayed_content,1,5)
end

local function will_draw()
    return get_displayed_content_1_5() == "event" and the_room_pos({"edit",'tracks_edit'})
end
local function ditto() --同上
    chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].to = chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].from
end
local function same_as_below() --同下
    chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].from = chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].to
end
local function endow() --赋予bezier
    chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].trans = {default_bezier[bezier_index][1],default_bezier[bezier_index][2],default_bezier[bezier_index][3],default_bezier[bezier_index][4]}
end

objact_event_edit = {  --编辑界面
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        objact_message_box.message(get_displayed_content_1_5())
        if not(get_displayed_content_1_5() == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        objact_event_edit_bezier.load(x+50,y+400,0,300,300)
        
        input_box_new(get_displayed_content_1_5().."track","chart.event["..string.sub(displayed_content,6,#displayed_content).."].track",x + 240,y,30,30,{type = "number",will_draw = will_draw})

        button_new(get_displayed_content_1_5().."same_as_below",same_as_below,x+300,y+50,100,30,ui:draw(x+300,y+50,100,30,objact_language.get_string_in_languages("same_as_below")),{will_draw = will_draw}) --同下
        button_new(get_displayed_content_1_5().."ditto",ditto,x+300,y+100,100,30,ui:draw(x+300,y+100,100,30,objact_language.get_string_in_languages("ditto")),{will_draw = will_draw}) --同上
        button_new(get_displayed_content_1_5().."endow",endow,x+125,y+300,100,30,ui:draw(x+125,y+300,100,30,objact_language.get_string_in_languages("endow")),{will_draw = will_draw}) --同下

        input_box_new(get_displayed_content_1_5().."from","chart.event["..string.sub(displayed_content,6,#displayed_content).."].from",x + 140,y + 50,100,30,{type = "number",will_draw = will_draw})
        input_box_new(get_displayed_content_1_5().."to","chart.event["..string.sub(displayed_content,6,#displayed_content).."].to",x + 140,y + 100,100,30,{type = "number",will_draw = will_draw})

        input_box_new(get_displayed_content_1_5().."beat_start1","chart.event["..string.sub(displayed_content,6,#displayed_content).."].beat[1]",x + 140,y + 150,30,30,{type = "number",will_draw = will_draw,input_ed_finish = event_sort})
        input_box_new(get_displayed_content_1_5().."beat_start2","chart.event["..string.sub(displayed_content,6,#displayed_content).."].beat[2]",x + 180,y + 150,30,30,{type = "number",will_draw = will_draw,input_ed_finish = event_sort})
        input_box_new(get_displayed_content_1_5().."beat_start3","chart.event["..string.sub(displayed_content,6,#displayed_content).."].beat[3]",x + 220,y + 150,30,30,{type = "number",will_draw = will_draw,input_ed_finish = event_sort})
        input_box_new(get_displayed_content_1_5().."beat_end1","chart.event["..string.sub(displayed_content,6,#displayed_content).."].beat2[1]",x + 140,y + 200,30,30,{type = "number",will_draw = will_draw,input_ed_finish = event_sort})
        input_box_new(get_displayed_content_1_5().."beat_end2","chart.event["..string.sub(displayed_content,6,#displayed_content).."].beat2[2]",x + 180,y + 200,30,30,{type = "number",will_draw = will_draw,input_ed_finish = event_sort})
        input_box_new(get_displayed_content_1_5().."beat_end3","chart.event["..string.sub(displayed_content,6,#displayed_content).."].beat2[3]",x + 220,y + 200,30,30,{type = "number",will_draw = will_draw,input_ed_finish = event_sort})
        input_box_new(get_displayed_content_1_5().."trans1","chart.event["..string.sub(displayed_content,6,#displayed_content).."].trans[1]",x + 140,y + 250,30,30,{type = "number",will_draw = will_draw})
        input_box_new(get_displayed_content_1_5().."trans2","chart.event["..string.sub(displayed_content,6,#displayed_content).."].trans[2]",x + 180,y + 250,30,30,{type = "number",will_draw = will_draw})
        input_box_new(get_displayed_content_1_5().."trans3","chart.event["..string.sub(displayed_content,6,#displayed_content).."].trans[3]",x + 220,y + 250,30,30,{type = "number",will_draw = will_draw})
        input_box_new(get_displayed_content_1_5().."trans4","chart.event["..string.sub(displayed_content,6,#displayed_content).."].trans[4]",x + 260,y + 250,30,30,{type = "number",will_draw = will_draw})

        objact_event_edit_default_bezier.load(x + 100,y + 300,0,30,30)
    end,
    draw = function() -- sidebar里的
        if not(get_displayed_content_1_5() == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(objact_language.get_string_in_languages("track"),x+200,y)
        love.graphics.print(objact_language.get_string_in_languages("from"),x+40,y+50)
        love.graphics.print(objact_language.get_string_in_languages("to"),x+40,y+100)
        love.graphics.print(objact_language.get_string_in_languages("beat_start"),x+40,y+150)
        love.graphics.print(objact_language.get_string_in_languages("beat_end"),x+40,y+200)
        love.graphics.print(objact_language.get_string_in_languages("trans"),x+40,y+250)

        objact_event_edit_bezier.draw()
        objact_event_edit_default_bezier.draw()
    end,
    update = function(dt)
        if not(get_displayed_content_1_5() == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        objact_event_edit_bezier.update(dt)
    end,
    mousepressed = function(x1, y1, button, istouch, presses)
        if not(get_displayed_content_1_5() == "event")then
            return
        end
        
        objact_event_edit_bezier.mousepressed(x1,y1)
        objact_event_edit_default_bezier.mousepressed(x1,y1)
    end,
    mousereleased = function(x1, y1, button, istouch, presses)
        objact_event_edit_bezier.mousereleased(x1,y1)
    end,
    keypressed = function(key)
        objact_event_edit_default_bezier.keyboard(key)
    end
}