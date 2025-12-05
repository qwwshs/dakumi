local alt = object:new('alt')

function alt:keypressed(key)
    if not isalt then
        return
    end
    local is_note = sidebar.displayed_content == "note"
    local is_event = sidebar.displayed_content == "event"
    local note_or_event_index = sidebar.incoming[1]
    if key == 'z' then --拖头
        if is_note then
            chart.note[note_or_event_index].beat = beat:toNearby(beat:yToBeat(mouse.y))
            fNote:sort()
            sidebar:to("nil")
        end
        if is_event then
            chart.event[note_or_event_index].beat = beat:toNearby(beat:yToBeat(mouse.y))
            fEvent:sort()
            sidebar:to("nil")
        end
    end
    if key == 'x' then --拖尾
        if is_note and chart.note[note_or_event_index].beat2 then
            if beat:get(beat:toNearby(beat:yToBeat(mouse.y))) <= beat:get(chart.note[note_or_event_index].beat) then
                return
            end
            chart.note[note_or_event_index].beat2 = beat:toNearby(beat:yToBeat(mouse.y))
            fNote:sort()
            sidebar:to("nil")
        end
        if is_event then
            if beat:get(beat:toNearby(beat:yToBeat(mouse.y))) <= beat:get(chart.event[note_or_event_index].beat) then
                return
            end
            chart.event[note_or_event_index].beat2 = beat:toNearby(beat:yToBeat(mouse.y))
            fEvent:sort()
            sidebar:to("nil")
        end
    end
    if key == "c" then --裁切
        log('cut')
        if is_event and chart.event[note_or_event_index] then
            local temp_event = {} -- 临时event表
            temp_event = table.copy(chart.event[note_or_event_index])
            local temp_event_int = {}--得到每个位置的event数值
            for i = 0, --算每个长条的from to值
            math.ceil((beat:get(chart.event[note_or_event_index].beat2) -  
            beat:get(chart.event[note_or_event_index].beat)) * (denom.denom * 2)) + 1
            do
                local isnow_beat = (i/(denom.denom * 2)) + 
                beat:get(chart.event[note_or_event_index].beat)
                local temp_now = {fEvent:get(chart.event[note_or_event_index].track,
                isnow_beat)}
                temp_event_int[i] = temp_now[1]
                if temp_event.type == "w" then
                    temp_event_int[i] = temp_now[2]
                end
            end

            for i = 0, math.floor((beat:get(chart.event[note_or_event_index].beat2) -  beat:get(chart.event[note_or_event_index].beat)) * (denom.denom * 2)) do
                local isnow_beat =  (i /(denom.denom * 2)) +
                beat:get(chart.event[note_or_event_index].beat)
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
                if isnow_beat > beat:get(chart.event[note_or_event_index].beat2) then
                    local_event.beat2 = temp_event.beat2
                end
                chart.event[#chart.event + 1] = local_event --添加
                redo:writeRevoke("event place",local_event)
                ctrl:copy_add(local_event,'event')
            end
            redo:writeRevoke("event delete",chart.event[note_or_event_index])
                table.remove(chart.event,note_or_event_index) --删除    
            fEvent:sort()
            sidebar:to('events')
        end
    end
    if key == 'b' then --翻转
        if is_event and chart.event[note_or_event_index] then
            chart.event[note_or_event_index].from = 2*(chart.preference.x_offset + chart.preference.event_scale/2) - chart.event[note_or_event_index].from
            chart.event[note_or_event_index].to = 2*(chart.preference.x_offset + chart.preference.event_scale/2) - chart.event[note_or_event_index].to
            log('flip')
            sidebar:to('nil')
        end
    end
    if key == "t" then --快速调整
        if is_event and chart.event[note_or_event_index] then
            local fence_x = fTrack:track_get_near_fence_x()
            if beat:yToBeat(mouse.y) < beat:get(chart.event[note_or_event_index].beat) then --在event之前
                chart.event[note_or_event_index].from = fence_x
            else
                chart.event[note_or_event_index].to = fence_x
            end
            sidebar:to('nil')
        end
     end
end

return alt