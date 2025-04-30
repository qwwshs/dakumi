
objact_note = {
    load = function(x1,y1,r1,w1,h1)
    end,
    draw = function()

    end,
    keyboard = function(key)
        if not (intervals_intersect(mouse.x,mouse.x,info.play.track.x,info.play.track.x + info.play.track.interval) 
            and mouse.y >= info.edit_tool.h)
        then --不在轨道范围内 not(mouse.x >= info.play.play_alea.x + info.play.play_alea.w and mouse.x <= 1000 and mouse.y >= 100)
            return
        end
        if key == "q" then -- note
            note_place("note",mouse.y)
            objact_message_box.message("note place")
            displayed_content = 'nil'
        elseif key == "w" then --wipe
            note_place("wipe",mouse.y)
            objact_message_box.message("wipe place")
            displayed_content = 'nil'
        elseif key == "e" then --hold
            hold_place = not hold_place
            note_place("hold",mouse.y)
            objact_message_box.message("hold place")
            displayed_content = 'nil'
        elseif key == "d" then --delete
            note_delete(mouse.y)
            objact_message_box.message("note delete")
            displayed_content = 'nil'
        end
    end,
    mousepressed = function(x,y,button)
        if  mouse.x >= 900 and mouse.x <= 1000 then -- 选择note
            local pos = note_click(mouse.y)
            if pos then
                displayed_content = 'note'..pos
                objact_note_edit.load(1200,40,0,30,30) --调用编辑界面
            else
                displayed_content = 'nil'
            end
            objact_message_box.message("note click")
        end
    end
}