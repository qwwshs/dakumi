--用于移动note和event的
objact_alt_note_event = {
    keyboard = function(key)
        if not isalt then
            return
        end
        if key == 'z' then --拖头
            if string.sub(displayed_content,1,4) == "note" then
                chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].beat = to_nearby_Beat(y_to_beat(mouse.y))
                note_sort()
                displayed_content = "nil"
            end
            if string.sub(displayed_content,1,5) == "event" then
                chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat = to_nearby_Beat(y_to_beat(mouse.y))
                event_sort()
                displayed_content = "nil"
            end
        end
        if key == 'x' then --拖尾
            if string.sub(displayed_content,1,4) == "note" and chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].beat2 then
                if thebeat(to_nearby_Beat(y_to_beat(mouse.y))) <= thebeat(chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].beat) then
                    return
                end
                chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].beat2 = to_nearby_Beat(y_to_beat(mouse.y))
                note_sort()
                displayed_content = "nil"
            end
            if string.sub(displayed_content,1,5) == "event" then
                if thebeat(to_nearby_Beat(y_to_beat(mouse.y))) <= thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat) then
                    return
                end
                chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat2 = to_nearby_Beat(y_to_beat(mouse.y))
                event_sort()
                displayed_content = "nil"
            end
        end
        if key == "c"  then --裁切
            if string.sub(displayed_content,1,5) == "event" and
            chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))] then
                local temp_event = {} -- 临时event表
                temp_event = copyTable(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))])
                local temp_event_int = {}--得到每个位置的event数值
                for i = 0, --算每个长条的from to值
                math.ceil((thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat2) -  
                thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat)) * (denom.denom * 2)) + 1
                do
                    local isnow_beat = (i/(denom.denom * 2)) + 
                    thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat)
                    local temp_now = {event_get(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].track,
                    isnow_beat)}
                    temp_event_int[i] = temp_now[1]
                    if temp_event.type == "w" then
                        temp_event_int[i] = temp_now[2]
                    end
                end

                for i = 0, 
                math.floor((thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat2) -  
                thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat)) * (denom.denom * 2))
                do
                    local isnow_beat =  (i /(denom.denom * 2)) +
                    thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat)
                    local event_min_denom = 0 --假设0最近
                    for k = 0, denom.denom*2 do --取分度 哪个近取哪个
                        if math.abs(isnow_beat - (math.floor(isnow_beat) + k / (denom.denom*2))) < 
                        math.abs(isnow_beat - (math.floor(isnow_beat) + event_min_denom / (denom.denom*2))) then
                            event_min_denom = k
                        end
                    end
                    local local_event = {
                        type = temp_event.type,
                        track = temp_event.track,
                        beat = {math.floor(isnow_beat),event_min_denom ,denom.denom*2},
                        beat2 = {math.floor(isnow_beat),event_min_denom + 1 ,denom.denom*2},
                        from = temp_event_int[i],
                        to = temp_event_int[i + 1],
                        trans = {[1] = 0,[2] = 0,[3] = 1,[4] = 1}
                    }
                    if isnow_beat > thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat2) then
                        local_event.beat2 = temp_event.beat2
                    end
                    chart.event[#chart.event + 1] = local_event --添加
                    objact_redo.write_revoke("event place",local_event)
                    copy_add(local_event,'event')
                end
                objact_redo.write_revoke("event delete",chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))])
                    table.remove(chart.event,tonumber(string.sub(displayed_content,6,#displayed_content))) --删除    
                event_sort()
                displayed_content = "multiple_events_edit" --界面清除
            end
        end
        if key == 'b' then --翻转
            if string.sub(displayed_content,1,5) == "event" and
            chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))] then
                log(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))])
                chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].from = 100 - chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].from
                chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].to = 100 - chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].to
            end
        end
        if key == "t" then --快速调整
            if string.sub(displayed_content,1,5) == "event" and
            chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))] then
                local fence_x = track_get_near_fence_x()
                if y_to_beat(mouse.y) < thebeat(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat) then --在event之前
                    chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].from = fence_x
                else
                    chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].to = fence_x
                end
            end
        end
    end
}