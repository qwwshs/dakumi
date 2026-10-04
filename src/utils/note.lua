--[[
    模块名: note
    描述: note（音符）操作模块，处理音符的点击、删除、放置、排序
    作者: qwwshs
    依赖: room；谱面、实体工厂与坐标接口由 init 传入。
          meta_note/beat/track/denom/messageBox 是遗留运行时状态。
]]

local note = require('src.utils.room').object:new('note')
local Note, ChartService, CoordinateService

-- 具体服务由启动入口传入，加载本模块不会向上加载服务或界面对象。
function note:init(dependencies)
    Note = assert(dependencies.note, 'note requires an entity factory')
    ChartService = assert(dependencies.chart, 'note requires a chart interface')
    CoordinateService = assert(dependencies.coordinates, 'note requires a coordinate interface')
end

note.local_hold = {} -- hold 音符临时数据（放置过程中）
note.hold_type = 0   -- hold 放置状态: 0=未放置, 1=已放头, 2=已放尾
note.local_tab = {}  -- 最近一次放置的 note 信息

--- 清除 hold 放置状态
function note:holdCleanUp()
    note.local_hold = {}
    note.local_tab = {}
    note.hold_type = 0
end
--- 在指定位置查找 note（用于点击选中）
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number|nil trackId 指定轨道（默认 track.track）
-- @treturn number|nil 找到的 note 索引，未找到返回 nil
function note:click(pos, trackId)
    --检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local note_beat_up = CoordinateService:yToBeat(pos - pos_interval)
    local note_beat_down = CoordinateService:yToBeat(pos + pos_interval)
    for i = 1, ChartService:getNoteCount() do
        local isnote = ChartService:getNote(i)
        local beatVal = isnote:getBeatValue()
        local beat2 = isnote:getBeat2()
        if isnote:getTrack() == (trackId or track.track) and
        (math.intersect(beatVal, beatVal, note_beat_down, note_beat_up)
        or (beat2 and -- 长条
        math.intersect(beatVal, isnote:getBeat2Value(), note_beat_down, note_beat_up))) then
            return i
        end
    end
end

--- 删除指定位置的 note
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number|nil trackId 指定轨道（默认 track.track）
function note:delete(pos, trackId)
    --删除检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local note_beat_up = CoordinateService:yToBeat(pos - pos_interval)
    local note_beat_down = CoordinateService:yToBeat(pos + pos_interval)
    for i = 1, ChartService:getNoteCount() do
        local isnote = ChartService:getNote(i)
        local beatVal = isnote:getBeatValue()
        local beat2 = isnote:getBeat2()
        if isnote:getTrack() == (trackId or track.track) and
        ((beatVal >= note_beat_down and beatVal <= note_beat_up)
        or (beat2 and -- 长条
        math.intersect(beatVal, isnote:getBeat2Value(), note_beat_up, note_beat_down))) then
            ChartService:delete(isnote, 'history.delete_' .. isnote:getType())
            sidebar.displayed_content = 'nil'
            return
        end
    end
end

--- 在指定位置放置 note
-- @tparam string note_type note 类型: "note", "hold", "wipe"
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number|nil trackId 指定轨道（默认 track.track）
-- @treturn boolean|nil 放置成功返回 true，失败返回 false
function note:place(note_type,pos,trackId)
    local istrack = trackId or track.track
    --根据距离反推出beat
    local note_beat = beat:toNearby(CoordinateService:yToBeat(pos))
    if note_type ~= "hold" then --不是长条
        --查表 如果重叠不给放
        local note_correct_beat = {note_beat[1],note_beat[2],note_beat[3]}
        for i = 1, ChartService:getNoteCount() do --重叠
            local isnote = ChartService:getNote(i)
            if isnote:getTrack() == istrack and isnote:getBeatValue() == beat:get(note_correct_beat) then
                messageBox:add("overlap")
                return false
            end
        end
        local isnote = Note.new({
            type = note_type,
            track = istrack,
            beat = {note_beat[1],note_beat[2],note_beat[3]},
            fake = noteFake.v,
        })
        ChartService:add(isnote, 'history.add_' .. note_type)

        note.local_tab = {type = note_type,
        track = istrack,
        beat = {note_beat[1],note_beat[2],note_beat[3]}
        ,fake = noteFake.v}
    else
        if note.hold_type == 0 then --放置头
            note.local_hold = Note.new({
                type = note_type,
                track = istrack,
                beat = {note_beat[1],note_beat[2],note_beat[3]},
                fake = noteFake.v,
                note_head = holdNoteHead.v,
                wipe_head = holdWipeHead.v,
            })
            note.hold_type = 1

            note.local_tab = table.copy(note.local_tab)
            note.local_tab.type = note_type
            note.local_tab.beat = {note_beat[1],note_beat[2],note_beat[3]}
            note.local_tab.track = istrack
            note.local_tab.fake = noteFake.v

        elseif note.hold_type == 1 then
            note.local_hold:setBeat2({note_beat[1],note_beat[2],note_beat[3]})
            note.local_tab.beat2 = {note_beat[1],note_beat[2],note_beat[3]}
            if note.local_hold:getBeat2Value() <= note.local_hold:getBeatValue() then --尾巴比头早或重叠
                messageBox:add("illegal operation")
                note:holdCleanUp()
                return false
            else -- 合法操作
                ChartService:add(note.local_hold, 'history.add_hold')
                note.hold_type = 2

            end
        end
    end
    if note_type ~= "hold" or note.hold_type == 2 then --长条尾放置完成
        note:holdCleanUp()
        note:sort()
    end
end
--- 对 note 列表按 beat 位置排序
function note:sort()
    ChartService:sortNotes()
    note.local_tab = {}
    note.local_hold = {}
    note.hold_type = 0
end
--- 获取当前 hold 放置的临时数据
-- @treturn table hold 数据表
function note:getHoldTable()
    return note.local_hold
end

return note
