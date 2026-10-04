local TimeOffset = require('src.utils.timeOffset')
local alt = object:new('alt')
local ChartService = require("src.services.chartService")
local Event = require("src.objects.Event")
local CoordinateService = require("src.services.coordinateService")

function alt:keypressed(key)
    if not iskeyboard.alt then
        return
    end
    local is_note = sidebar.displayed_content == "note"
    local is_event = sidebar.displayed_content == "event"
    local note_or_event_index = sidebar.incoming[1]
    if input('dragHead') then --拖头
        if is_note then
            local isnote = ChartService:getNote(note_or_event_index):copy()
            isnote:setBeat(TimeOffset.baseBeat(beat:toNearby(CoordinateService:yToBeat(mouse.y)), isnote:getTimeOffset()))
            ChartService:push()
            ChartService:add(isnote)
            ChartService:delete(ChartService:getNote(note_or_event_index))
            ChartService:pop('history.move_note_start')
            sidebar:to("nil")
        end
        if is_event then
            local original = ChartService:getEvent(note_or_event_index)
            local isevent = original:copy()
            isevent:setBeat(TimeOffset.baseBeat(beat:toNearby(CoordinateService:yToBeat(mouse.y)), isevent:getTimeOffset()))
            if not ChartService:canPlaceEvent(isevent, original) then
                messageBox:add('illegal operation')
                return
            end
            ChartService:push()
            ChartService:delete(original)
            ChartService:add(isevent)
            ChartService:pop('history.move_event_start')
            sidebar:to("nil")
        end
        sidebar:to("nil")
    end
    if input('dragTail') then --拖尾
        if is_note and ChartService:getNote(note_or_event_index):getBeat2() then
            if beat:get(beat:toNearby(CoordinateService:yToBeat(mouse.y))) <= ChartService:getNote(note_or_event_index):getBeatValue() then
                return
            end
            local isnote = ChartService:getNote(note_or_event_index):copy()
            isnote:setBeat2(TimeOffset.baseBeat(beat:toNearby(CoordinateService:yToBeat(mouse.y)), isnote:getTimeOffset()))
            ChartService:push()
            ChartService:add(isnote)
            ChartService:delete(ChartService:getNote(note_or_event_index))
            ChartService:pop('history.move_hold_end')

            sidebar:to("nil")
        end
        if is_event then
            if beat:get(beat:toNearby(CoordinateService:yToBeat(mouse.y))) <= ChartService:getEvent(note_or_event_index):getBeatValue() then
                return
            end
            local original = ChartService:getEvent(note_or_event_index)
            local isevent = original:copy()
            isevent:setBeat2(TimeOffset.baseBeat(beat:toNearby(CoordinateService:yToBeat(mouse.y)), isevent:getTimeOffset()))
            if not ChartService:canPlaceEvent(isevent, original) then
                messageBox:add('illegal operation')
                return
            end
            ChartService:push()
            ChartService:delete(original)
            ChartService:add(isevent)
            ChartService:pop('history.move_event_end')

            sidebar:to("nil")
        end
    end
    if input('cutEventOrHold') then --裁切
        log('cut')
        if is_event and ChartService:getEvent(note_or_event_index) and
            ChartService:getEvent(note_or_event_index):getType() ~= 'event_group' then
            local isevent = ChartService:getEvent(note_or_event_index)
            local baseStart, baseEnd = beat:get(isevent:getBeat()), beat:get(isevent:getBeat2())
            local offset = isevent:getTimeOffset()
            local temp_event = isevent:copy() -- 临时event表
            local temp_event_int = {}--得到每个位置的event数值
            local steps = math.ceil((baseEnd - baseStart) * denom.denom * 2)
            for i = 0, steps do
                local sampleBeat = math.min(baseEnd, baseStart + i / (denom.denom * 2))
                local x, w = fEvent:get(isevent:getTrack(), TimeOffset.shiftBeat(sampleBeat, offset))
                temp_event_int[i] = temp_event:getType() == 'w' and w or x
            end

            ChartService:push()
            for i = 0, steps - 1 do
                local first = baseStart + i / (denom.denom * 2)
                local last = math.min(baseEnd, baseStart + (i + 1) / (denom.denom * 2))
                local local_event = Event.new({
                    type = temp_event:getType(), track = temp_event:getTrack(),
                    beat = TimeOffset.baseBeat(first, 0), beat2 = TimeOffset.baseBeat(last, 0),
                    time_offset = offset > 0 and offset or nil,
                    from = temp_event_int[i], to = temp_event_int[i + 1],
                })
                ChartService:add(local_event)
                if ctrl then ctrl:copy_add(local_event, 'event') end
            end
            ChartService:delete(isevent)
            ChartService:pop('history.cut_event') --结束记录

            fEvent:sort()
            sidebar:to('events')
        end
    end
    if input('flipEvent') then --翻转
        if is_event and ChartService:getEvent(note_or_event_index) then
            local e = ChartService:getEvent(note_or_event_index)
            local center = 2*(ChartService:getPreferenceField('x_offset') + ChartService:getPreferenceField('event_scale')/2)
            ChartService:change('history.flip_event', function()
                e:setFrom(center - e:getFrom())
                e:setTo(center - e:getTo())
            end)
            log('flip')
            sidebar:getGroup('event').historyAction = 'history.flip_event'
            sidebar:to('event',note_or_event_index)
        end
    end
    if input('adjustEventValue') then --快速调整
        if is_event and ChartService:getEvent(note_or_event_index) then
            local e = ChartService:getEvent(note_or_event_index)
            local fence_x = fTrack:track_get_near_fence_x()
            ChartService:change('history.adjust_event_value', function()
                if CoordinateService:yToBeat(mouse.y) < e:getBeatValue() then --在event之前
                    e:setFrom(fence_x)
                else
                    e:setTo(fence_x)
                end
            end)
            sidebar:getGroup('event').historyAction = 'history.adjust_event_value'
            sidebar:to('event',note_or_event_index)
        end
    end
    if input('flipUpsideDownEvent') then
        if is_event and ChartService:getEvent(note_or_event_index) then
            local e = ChartService:getEvent(note_or_event_index)
            ChartService:change('history.flip_event_vertical', function()
                local from, to = e:getTo(), e:getFrom()
                e:setFrom(from)
                e:setTo(to)
            end)
            log('flip')
            sidebar:getGroup('event').historyAction = 'history.flip_event_vertical'
            sidebar:to('event',note_or_event_index)
        end
    end
end

-- 注册信息由 plugins/init.lua 读取；生命周期仍使用对象的冒号方法。
alt.plugin = {
    name = 'alt',
    version = '1.0.0',
    target = 'edit/play',
    layer = 100,
}

return alt
