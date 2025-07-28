
object_note = {
    load = function(x1,y1,r1,w1,h1)
    end,
    draw = function()

    end,
    keyboard = function(key)
        if not (math.intersect(mouse.x,mouse.x,info.play.track.x,info.play.track.x + info.play.track.interval) 
            and mouse.y >= info.edit_tool.h)
        then --不在轨道范围内 not(mouse.x >= info.play.play_alea.x + info.play.play_alea.w and mouse.x <= 1000 and mouse.y >= 100)
            return
        end
        if key == "q" then -- note
            note_place("note",mouse.y)
            messageBox:add("note place")
            sidebar.displayed_content = 'nil'
        elseif key == "w" then --wipe
            note_place("wipe",mouse.y)
            messageBox:add("wipe place")
            sidebar.displayed_content = 'nil'
        elseif key == "e" then --hold
            hold_place = not hold_place
            note_place("hold",mouse.y)
            messageBox:add("hold place")
            sidebar.displayed_content = 'nil'
        elseif key == "d" then --delete
            note_delete(mouse.y)
            messageBox:add("note delete")
            sidebar.displayed_content = 'nil'
        end
    end,
    mousepressed = function(x,y,button)
        if  mouse.x >= 900 and mouse.x <= 1000 then -- 选择note
            local pos = note_click(mouse.y)
            if pos then
                sidebar:to('note',pos)
            else
                sidebar.displayed_content = 'nil'
            end
            messageBox:add("note click")
        end
    end
}