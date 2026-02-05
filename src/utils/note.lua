local note = object:new('note')
note.__index = meta_note.__index

note.local_hold = {} -- 局部hold表
note.hold_type = 0 --长条状态 0没放 1头 2尾
note.local_tab =  {} --局部note表
function note:holdCleanUp() --长条清除
    note.local_hold = {}
    note.hold_type = 0
end
-- note函数
function note:click(pos)
    --检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local note_beat_up = beat:yToBeat(pos - pos_interval)
    local note_beat_down = beat:yToBeat(pos + pos_interval)
    for i = 1,#chart.note do
        if chart.note[i].track == track.track and 
        (math.intersect(beat:get(chart.note[i].beat),beat:get(chart.note[i].beat),note_beat_down,note_beat_up)
        or (chart.note[i].beat2 and -- 长条
        math.intersect(beat:get(chart.note[i].beat),beat:get(chart.note[i].beat2),note_beat_down,note_beat_up))) then
            return i
        end
    end
end

function note:delete(pos)
    --删除检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local note_beat_up = beat:yToBeat(pos - pos_interval)
    local note_beat_down = beat:yToBeat(pos + pos_interval)
    for i = 1,#chart.note do
        local isnote = chart.note[i]
        if isnote.track == track.track and 
        ((beat:get(isnote.beat) >= note_beat_down and beat:get(isnote.beat) <= note_beat_up)
        or (isnote.beat2 and -- 长条
        math.intersect(beat:get(isnote.beat), beat:get(isnote.beat2), note_beat_up, note_beat_down))) then
            chart:delete(isnote)
            sidebar.displayed_content = 'nil'
            return
        end
    end
end

function note:place(note_type,pos)
    --根据距离反推出beat
    local note_beat = beat:toNearby(beat:yToBeat(pos))
    if note_type ~= "hold" then --不是长条
        --查表 如果重叠不给放
        local note_correct_beat = {note_beat[1],note_beat[2],note_beat[3]}
        for i = 1,#chart.note do --重叠
            if chart.note[i].track == track.track and beat:get(chart.note[i].beat) == beat:get(note_correct_beat) then
                messageBox:add("overlap")
                return false
            end
        end
        local isnote
        isnote = table.copy(note.__index)
        isnote.type = note_type
        isnote.track = track.track
        isnote.beat = {note_beat[1],note_beat[2],note_beat[3]}
        isnote.fake = noteFake.v
        chart:add(isnote)

        note.local_tab = {type = note_type,
        track = track.track,
        beat = {note_beat[1],note_beat[2],note_beat[3]}
        ,fake = noteFake.v}
    else
        if note.hold_type == 0 then --放置头
            note.local_hold = {
                type = note_type,
                track = track.track,
                beat = {note_beat[1],note_beat[2],note_beat[3]},
                fake = noteFake.v,
                note_head = holdNoteHead.v,
                wipe_head = holdWipeHead.v,
            }
            note.hold_type = 1
            
            note.local_tab = table.copy(note.local_tab)
            note.local_tab.type = note_type
            note.local_tab.beat = {note_beat[1],note_beat[2],note_beat[3]}
            note.local_tab.track = track.track
            note.local_tab.fake = noteFake.v
            
        elseif note.hold_type == 1 then
            note.local_hold.beat2 = {note_beat[1],note_beat[2],note_beat[3]} 
            note.local_tab.beat2 = {note_beat[1],note_beat[2],note_beat[3]} 
            if beat:get(note.local_hold.beat2) <= beat:get(note.local_hold.beat) then --尾巴比头早或重叠
                messageBox:add("illegal operation")
                note:holdCleanUp()
                return false
            else -- 合法操作
                chart:add(note.local_hold)
                note.hold_type = 2

            end
        end
    end
    if note_type ~= "hold" or note.hold_type == 2 then --长条尾放置完成
        note:holdCleanUp()
        note:sort()
    end
end
function note:sort()
        table.sort(chart.note,function(a,b) return beat:get(a.beat) < beat:get(b.beat) end)
        note.local_tab = {}
end
function note:getHoldTable()
    return note.local_hold
end

return note