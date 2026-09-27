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
            isnote:setBeat(beat:toNearby(CoordinateService:yToBeat(mouse.y)))
            ChartService:push()
            ChartService:add(isnote)
            ChartService:delete(ChartService:getNote(note_or_event_index))
            ChartService:pop()
            sidebar:to("nil")
        end
        if is_event then
            local isevent = ChartService:getEvent(note_or_event_index):copy()
            isevent:setBeat(beat:toNearby(CoordinateService:yToBeat(mouse.y)))
            ChartService:push()
            ChartService:add(isevent)
            ChartService:delete(ChartService:getEvent(note_or_event_index))
            ChartService:pop()
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
            isnote:setBeat2(beat:toNearby(CoordinateService:yToBeat(mouse.y)))
            ChartService:push()
            ChartService:add(isnote)
            ChartService:delete(ChartService:getNote(note_or_event_index))
            ChartService:pop()

            sidebar:to("nil")
        end
        if is_event then
            if beat:get(beat:toNearby(CoordinateService:yToBeat(mouse.y))) <= ChartService:getEvent(note_or_event_index):getBeatValue() then
                return
            end
            local isevent = ChartService:getEvent(note_or_event_index):copy()
            isevent:setBeat2(beat:toNearby(CoordinateService:yToBeat(mouse.y)))
            ChartService:push()
            ChartService:add(isevent)
            ChartService:delete(ChartService:getEvent(note_or_event_index))
            ChartService:pop()

            sidebar:to("nil")
        end
    end
    if input('cutEventOrHold') then --裁切
        log('cut')
        if is_event and ChartService:getEvent(note_or_event_index) then
            local isevent = ChartService:getEvent(note_or_event_index)
            local temp_event = isevent:copy() -- 临时event表
            local temp_event_int = {}--得到每个位置的event数值
            for i = 0, --算每个长条的from to值
            math.ceil((isevent:getBeat2Value() -
            isevent:getBeatValue()) * (denom.denom * 2)) + 1
            do
                local isnow_beat = (i/(denom.denom * 2)) +
                isevent:getBeatValue()
                local temp_now = {fEvent:get(isevent:getTrack(),
                isnow_beat)}
                temp_event_int[i] = temp_now[1]
                if temp_event:getType() == "w" then
                    temp_event_int[i] = temp_now[2]
                end
            end

            ChartService:push() --开始记录
            for i = 0, math.floor((isevent:getBeat2Value() - isevent:getBeatValue()) * (denom.denom * 2)) do
                local isnow_beat =  (i /(denom.denom * 2)) +
                isevent:getBeatValue()
                local event_min_denom = 0 --假设0最近
                for k = 0, denom.denom*2 do --取分度 哪个近取哪个
                    if math.abs(isnow_beat - (math.floor(isnow_beat) + k / (denom.denom*2))) <
                    math.abs(isnow_beat - (math.floor(isnow_beat) + event_min_denom / (denom.denom*2))) then
                        event_min_denom = k
                    end
                end
                local local_event = Event.new()
                local_event:setType(temp_event:getType())
                local_event:setTrack(temp_event:getTrack())
                local_event:setBeat({math.floor(isnow_beat),event_min_denom ,denom.denom*2})
                local_event:setBeat2({math.floor(isnow_beat),event_min_denom + 1 ,denom.denom*2})
                local_event:setFrom(temp_event_int[i])
                local_event:setTo(temp_event_int[i + 1])

                if isnow_beat > isevent:getBeat2Value() then
                    local_event:setBeat2(isevent:getBeat2())
                end
                ChartService:add(local_event)
                if ctrl then ctrl:copy_add(local_event,'event') end
            end
            ChartService:delete(isevent)
            ChartService:pop() --结束记录

            fEvent:sort()
            sidebar:to('events')
        end
    end
    if input('flipEvent') then --翻转
        if is_event and ChartService:getEvent(note_or_event_index) then
            local e = ChartService:getEvent(note_or_event_index)
            local center = 2*(ChartService:getPreferenceField('x_offset') + ChartService:getPreferenceField('event_scale')/2)
            e:setFrom(center - e:getFrom())
            e:setTo(center - e:getTo())
            log('flip')
            sidebar:to('event',note_or_event_index)
        end
    end
    if input('adjustEventValue') then --快速调整
        if is_event and ChartService:getEvent(note_or_event_index) then
            local e = ChartService:getEvent(note_or_event_index)
            local fence_x = fTrack:track_get_near_fence_x()
            if CoordinateService:yToBeat(mouse.y) < e:getBeatValue() then --在event之前
                e:setFrom(fence_x)
            else
                e:setTo(fence_x)
            end
            sidebar:to('event',note_or_event_index)
        end
    end
    if input('flipUpsideDownEvent') then
        if is_event and ChartService:getEvent(note_or_event_index) then
            local e = ChartService:getEvent(note_or_event_index)
            local from, to = e:getTo(), e:getFrom()
            e:setFrom(from)
            e:setTo(to)
            log('flip')
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
