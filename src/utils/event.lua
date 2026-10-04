local TimeOffset = require('src.utils.timeOffset')
local safeInput = require("src.utils.safeInput")
--[[
    模块名: event (fEvent)
    描述: 事件处理模块，负责事件的查询、放置、删除、排序和过渡计算
    作者: qwwshs
    依赖: room/safeInput；谱面、实体工厂与坐标接口由 init 传入。
          beat/easings/bezier 与 sidebar/track/denom/transIndex 是遗留运行时状态。

    核心功能:
    - event:get(): 获取指定轨道在指定 beat 处的事件值（x, w, lpos, rpos）
    - event:click(): 点击选择事件
    - event:delete(): 删除事件
    - event:place(): 放置事件（支持长按放置头/尾）
    - event:sort(): 对事件列表排序
    - event:getTrans(): 计算事件的过渡值
]]

local event = require('src.utils.room').object:new('event')
local ChartService, Event, CoordinateService
local cachedGroups, cachedRevision = {}, -1

-- 工具只依赖传入的接口，具体服务与实体工厂由启动入口装配。
function event:init(dependencies)
    ChartService = assert(dependencies.chart, 'event requires a chart interface')
    Event = assert(dependencies.event, 'event requires an entity factory')
    CoordinateService = assert(dependencies.coordinates, 'event requires a coordinate interface')
    cachedGroups, cachedRevision = {}, -1
end

-- ============================================================
-- 贝塞尔曲线预设加载（仅此处加载一次，其他模块通过 fEvent.bezier 访问）
-- ============================================================
local bezier_file = io.open("defaultBezier.txt", "r")
if bezier_file then
    local content = bezier_file:read("*a")
    bezier_file:close()
    event.bezier = safeInput.parseBezierPresets(content)
end
if type(event.bezier) ~= "table" then
    event.bezier = {}
end

--- 局部 event 表（放置长按事件时的临时数据）
event.local_event = {}

--- 长条放置状态: 0=未放置, 1=已放头, 2=已放尾
event.hold_type = 0

-- ============================================================
-- 辅助函数
-- ============================================================

--- 清除长按事件的临时状态
function event:cleanUp()
    event.local_event = {}
    event.hold_type = 0
end

--- 计算事件的过渡值
-- @tparam Event isevent 事件对象
-- @tparam number t 过渡进度 (0~1)
-- @treturn number 过渡后的值
function event:getTrans(isevent, t)
    t = math.min(math.max(t, 0), 1)
    if isevent:getTransType() == 'bezier' then
        return bezier(0, 1, 0, 1, isevent:getTransData(), t)
    elseif isevent:getTransType() == 'easings' then
        local ease = easings[isevent:getEasings()]
        return ease and ease(t) or t
    else
        return t
    end
end

local function innerTransition(inner, progress)
    progress = math.min(math.max(progress, 0), 1)
    local trans = inner.trans or {}
    if trans.type == 'bezier' and type(trans.trans) == 'table' then
        return bezier(0, 1, 0, 1, trans.trans, progress) or progress
    end
    local ease = trans.type == 'easings' and easings[trans.easings]
    return ease and ease(progress) or progress
end

local function getCachedGroup(name)
    local revision = ChartService:getEventGroupsRevision()
    if revision ~= cachedRevision then
        cachedGroups, cachedRevision = {}, revision
    end
    if cachedGroups[name] == nil then
        cachedGroups[name] = ChartService:getEventGroup(name) or false
    end
    return cachedGroups[name] or nil
end

local function usableInner(inner)
    if type(inner) ~= 'table' or not table.find(event_property_type, inner.type) or
        type(inner.beat) ~= 'table' or type(inner.beat2) ~= 'table' or
        type(inner.from) ~= 'number' or type(inner.to) ~= 'number' then return false end
    if inner.from ~= inner.from or inner.to ~= inner.to or
        math.abs(inner.from) == math.huge or math.abs(inner.to) == math.huge then return false end
    for _, value in ipairs({inner.beat, inner.beat2}) do
        if type(value[1]) ~= 'number' or type(value[2]) ~= 'number' or
            type(value[3]) ~= 'number' or value[3] <= 0 then return false end
        for i = 1, 3 do
            if value[i] ~= value[i] or math.abs(value[i]) == math.huge then return false end
        end
    end
    return TimeOffset.shiftBeat(inner.beat2, inner.time_offset) > TimeOffset.shiftBeat(inner.beat, inner.time_offset)
end

-- 组内时间按最早起点、最晚终点归一化；各属性沿用普通事件的插值与保持规则。
local function groupValues(instance, atBeat)
    local startBeat, endBeat = instance:getBeatValue(), instance:getBeat2Value()
    local progress = math.min(math.max((atBeat - startBeat) / (endBeat - startBeat), 0), 1)
    local groupData = getCachedGroup(instance:getEventGroup())
    if not groupData or type(groupData.event) ~= 'table' or #groupData.event == 0 then
        return {x = instance:getFrom() + (instance:getTo() - instance:getFrom()) * progress}
    end
    local groupStart, groupEnd
    for _, inner in ipairs(groupData.event) do
        if usableInner(inner) then
            local first, last = TimeOffset.shiftBeat(inner.beat, inner.time_offset), TimeOffset.shiftBeat(inner.beat2, inner.time_offset)
            groupStart = groupStart and math.min(groupStart, first) or first
            groupEnd = groupEnd and math.max(groupEnd, last) or last
        end
    end
    if not groupStart or not groupEnd or groupEnd <= groupStart then
        return {x = instance:getFrom() + (instance:getTo() - instance:getFrom()) * progress}
    end
    if instance:getFlipVertically() == 1 then progress = 1 - progress end
    local innerBeat = groupStart + progress * (groupEnd - groupStart)
    local selected = {}
    for _, inner in ipairs(groupData.event) do
        if usableInner(inner) then
            local first = TimeOffset.shiftBeat(inner.beat, inner.time_offset)
            if first <= innerBeat and (not selected[inner.type] or
                first >= TimeOffset.shiftBeat(selected[inner.type].beat, selected[inner.type].time_offset)) then
                selected[inner.type] = inner
            end
        end
    end
    local result = {}
    local scale = ChartService:getPreferenceField('event_scale') or 100
    if scale == 0 then scale = 100 end
    local offset = ChartService:getPreferenceField('x_offset') or 0
    for kind, inner in pairs(selected) do
        local first, last = TimeOffset.shiftBeat(inner.beat, inner.time_offset), TimeOffset.shiftBeat(inner.beat2, inner.time_offset)
        local fraction = innerBeat >= last and 1 or (innerBeat - first) / (last - first)
        local value = inner.from + (inner.to - inner.from) * innerTransition(inner, fraction)
        local normalized = (value - (kind == 'w' and 0 or offset)) / scale
        local target = kind
        if instance:getFlipHorizontally() == 1 and kind ~= 'w' then
            normalized = 1 - normalized
            if kind == 'lpos' then target = 'rpos'
            elseif kind == 'rpos' then target = 'lpos' end
        end
        result[target] = instance:getFrom() + (instance:getTo() - instance:getFrom()) * normalized
    end
    return result
end

--- 在事件列表中查找与指定区间重叠的事件
-- 公共函数，消除 click 和 delete 中的重复逻辑
-- @tparam string eventType 事件类型 ("x", "w", "lpos", "rpos")
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number trackId 轨道 ID（可选，默认为当前轨道）
-- @treturn number|nil 找到的事件索引，未找到返回 nil
-- @treturn table|nil 找到的事件数据
local function findEventInRange(eventType, pos, trackId)
    trackId = trackId or track.track
    local pos_interval = 20 * math.min(denom.scale, 1)
    local event_beat_up = CoordinateService:yToBeat(pos - pos_interval)
    local event_beat_down = CoordinateService:yToBeat(pos + pos_interval)

    for i = 1, ChartService:getEventCount() do
        local isevent = ChartService:getEvent(i)
        local beat1 = isevent:getBeatValue()
        local beat2 = isevent:getBeat2Value() or beat1
        if (isevent:getType() == eventType or isevent:getType() == 'event_group') and
            isevent:getTrack() == trackId and
            math.intersect(beat1, beat2, event_beat_down, event_beat_up) then
            return i, isevent
        end
    end
    return nil, nil
end

-- ============================================================
-- 从 extra_chart 获取事件值（快速路径）
-- ============================================================

--- 从 extra_chart 索引中查找指定类型的事件值
-- @tparam number istrack 轨道 ID
-- @tparam string istype 事件类型
-- @tparam number isbeat 目标 beat 值
-- @treturn table {值, beat, type}
local function getValueFromExtraChart(istrack, istype, isbeat)
    local result = {0, beat = 0, type = istype}
    local eventCount = ChartService:getTrackEventCount(istrack, istype)
    if eventCount == 0 then
        return result
    end

    for i = eventCount, 1, -1 do
        local isevent = ChartService:getTrackEvent(istrack, istype, i)
        local beat1 = isevent:getBeatValue()
        local beat2 = isevent:getBeat2Value() or beat1
        if (beat1 <= isbeat and beat2 > isbeat) or beat2 <= isbeat then
            local value = isevent:getFrom() +
                (isevent:getTo() - isevent:getFrom()) * event:getTrans(isevent, (isbeat - beat1) / (beat2 - beat1))
            result = {value, beat = beat2, type = istype}
            if beat2 >= isbeat then
                result.beat = isbeat
            end
            return result
        end
    end
    return result
end

-- ============================================================
-- 从 chart 直接遍历获取事件值（慢速路径，extra_chart 缺失时使用）
-- ============================================================

--- 从 chart.event 中遍历查找指定类型的事件值
-- @tparam number istrack 轨道 ID
-- @tparam string istype 事件类型
-- @tparam number isbeat 目标 beat 值
-- @treturn table {值, beat, type}
local function getValueFromChart(istrack, istype, isbeat)
    local result = {0, beat = 0, type = istype}
    for i = ChartService:getEventCount(), 1, -1 do
        local isevent = ChartService:getEvent(i)
        if isevent:getTrack() == istrack and isevent:getType() == istype then
            local beat1 = isevent:getBeatValue()
            local beat2 = isevent:getBeat2Value() or beat1
            if (beat1 <= isbeat and beat2 > isbeat) or beat2 <= isbeat then
                local value = isevent:getFrom() +
                    (isevent:getTo() - isevent:getFrom()) * event:getTrans(isevent, (isbeat - beat1) / (beat2 - beat1))
                result = {value, beat = beat2, type = istype}
                return result
            end
        end
    end
    return result
end

-- ============================================================
-- lrpos 到 xw 的转换
-- ============================================================

--- 将 x, w, lpos, rpos 四个值合并为最终的 x, w
-- 根据可用的事件类型组合，计算出轨道的 x 坐标和宽度
-- @tparam table now 包含 x, w, lpos, rpos 四个值的表
-- @treturn number x 轨道 x 坐标
-- @treturn number w 轨道宽度
local function mergeEventValues(now)
    -- 按 beat 大小排序，取最近的两项
    local sorted = {now.x, now.w, now.lpos, now.rpos}
    table.sort(sorted, function(a, b) return a.beat > b.beat end)

    local temp = {}
    temp[sorted[1].type] = sorted[1]
    temp[sorted[2].type] = sorted[2]

    local return_x, return_w = 0, 0

    if temp.x and temp.w then
        return_x = temp.x[1]
        return_w = temp.w[1]
    elseif temp.lpos and temp.rpos then
        return_x = (temp.lpos[1] + temp.rpos[1]) / 2
        return_w = temp.rpos[1] - temp.lpos[1]
    elseif temp.x and temp.lpos then
        return_x = temp.x[1]
        return_w = (temp.x[1] - temp.lpos[1]) * 2
    elseif temp.x and temp.rpos then
        return_x = temp.x[1]
        return_w = (temp.rpos[1] - temp.x[1]) * 2
    elseif temp.w and temp.rpos then
        return_x = temp.rpos[1] - temp.w[1] / 2
        return_w = temp.w[1]
    elseif temp.w and temp.lpos then
        return_x = temp.lpos[1] + temp.w[1] / 2
        return_w = temp.w[1]
    end

    return return_x, return_w
end

-- ============================================================
-- 公共 API
-- ============================================================

--- 获取指定轨道在指定 beat 处的事件值
-- 优先从 extra_chart 索引查询（快速路径），缺失时从 chart 遍历（慢速路径）
-- 支持父轨道与边界轨道递归计算
-- @tparam number istrack 轨道 ID
-- @tparam number isbeat beat 值
-- @tparam bool original 是否获取原值（不进行父轨道 lrpos 转换）
-- @tparam table parent_tab 父轨道递归记录表（内部使用，防止死循环）
-- @tparam table boundary_tab 边界轨道递归记录表（内部使用，防止死循环）
-- @treturn number x 轨道 x 坐标
-- @treturn number w 轨道宽度
function event:get(istrack, isbeat, original, parent_tab, boundary_tab)
    original = original or false
    parent_tab = parent_tab or {}
    boundary_tab = boundary_tab or {}

    local now = {
        x = {0, beat = 0, type = "x"},
        w = {0, beat = 0, type = "w"},
        lpos = {0, beat = 0, type = "lpos"},
        rpos = {0, beat = 0, type = "rpos"},
    }

    -- 获取四种类型的事件值
    if ChartService:hasTrack(istrack) then
        -- 快速路径：从 extra_chart 索引查询
        now.x = getValueFromExtraChart(istrack, "x", isbeat)
        now.w = getValueFromExtraChart(istrack, "w", isbeat)
        now.lpos = getValueFromExtraChart(istrack, "lpos", isbeat)
        now.rpos = getValueFromExtraChart(istrack, "rpos", isbeat)
    else
        -- 慢速路径：从 chart 遍历查询
        now.x = getValueFromChart(istrack, "x", isbeat)
        now.w = getValueFromChart(istrack, "w", isbeat)
        now.lpos = getValueFromChart(istrack, "lpos", isbeat)
        now.rpos = getValueFromChart(istrack, "rpos", isbeat)
    end

    local groupResults = {}
    local count = ChartService:getTrackEventCount(istrack, 'event_group')
    for i = 1, count do
        local instance = ChartService:getTrackEvent(istrack, 'event_group', i)
        local first, last = instance:getBeatValue(), instance:getBeat2Value()
        if first <= isbeat and last > first then
            for kind, value in pairs(groupValues(instance, isbeat)) do
                groupResults[kind] = {value, beat = math.min(isbeat, last), type = kind,
                    active = isbeat < last}
            end
        end
    end
    for _, kind in ipairs(event_property_type) do
        local fromGroup = groupResults[kind]
        if fromGroup and (fromGroup.active or fromGroup.beat > now[kind].beat) then
            now[kind] = fromGroup
        end
    end

    -- 合并四种类型的值为 x, w
    local return_x, return_w = mergeEventValues(now)

    -- 处理父轨道递归
    if not original then
        local parent_track = ChartService:getTrackField(istrack, 'parent')
        local scale_with_parent = ChartService:getTrackField(istrack, 'scale_with_parent')
        if parent_track ~= 0 then
            parent_tab[istrack] = true
            -- 防止循环引用导致死循环
            if parent_tab[parent_track] then
                return return_x, return_w
            end
            local parent_x, parent_w = self:get(parent_track, isbeat, original, parent_tab, boundary_tab)

            if scale_with_parent == 1 then
                -- 跟随父轨道缩放
                local parent_l = parent_x - parent_w / 2
                local event_scale = ChartService:getPreferenceField('event_scale')
                local x_offset = ChartService:getPreferenceField('x_offset')
                return_w = return_w / event_scale * parent_w
                return_x = parent_l + (return_x + x_offset) / event_scale * parent_w
            else
                -- 仅偏移，不缩放
                return_x = return_x + parent_x
            end
        end

        -- 处理边界
        local left_boundary = ChartService:getTrackField(istrack, 'left_boundary')
        local right_boundary = ChartService:getTrackField(istrack, 'right_boundary')
        local boundary_type = ChartService:getTrackField(istrack, 'boundary_type')
        local left_reference = ChartService:getTrackField(istrack, 'left_reference')
        local right_reference = ChartService:getTrackField(istrack, 'right_reference')
        local lpos, rpos = return_x - return_w / 2, return_x + return_w / 2
        local natural_l, natural_r = lpos, rpos -- 自然区间（空交集时判断往哪边收）
        local l_limit, r_limit                  -- 本次生效的左/右边界线（nil = 该侧无边界）
        if boundary_type == 'track' then
            -- 是否启用只看 boundary_type（'nil' 才不启用）；轨道号在谱面里不存在时该侧无从解析，跳过
            if (not boundary_tab[left_boundary]) and ChartService:hasTrackData(left_boundary) then
                boundary_tab[left_boundary] = true
                -- 边界轨道按自己的父链单独解析：parent_tab 不能沿用（共享祖先时会被判成环而少算父偏移）
                local left_x, left_w = self:get(left_boundary, isbeat, original, {}, boundary_tab)
                boundary_tab[left_boundary] = nil
                if left_reference == 'x' then
                    l_limit = left_x
                elseif left_reference == 'w' then
                    l_limit = left_w
                elseif left_reference == 'lpos' then
                    l_limit = left_x - left_w / 2
                elseif left_reference == 'rpos' then
                    l_limit = left_x + left_w / 2
                end
                if l_limit then
                    lpos = math.max(lpos, l_limit)
                end
            end
            if (not boundary_tab[right_boundary]) and ChartService:hasTrackData(right_boundary) then
                boundary_tab[right_boundary] = true
                local right_x, right_w = self:get(right_boundary, isbeat, original, {}, boundary_tab)
                boundary_tab[right_boundary] = nil
                if right_reference == 'x' then
                    r_limit = right_x
                elseif right_reference == 'w' then
                    r_limit = right_w
                elseif right_reference == 'lpos' then
                    r_limit = right_x - right_w / 2
                elseif right_reference == 'rpos' then
                    r_limit = right_x + right_w / 2
                end
                if r_limit then
                    rpos = math.min(rpos, r_limit)
                end
            end
        elseif boundary_type == 'pos' then
            -- pos 模式两侧无条件按坐标生效，0 是合法坐标（两侧都填 0 就是零宽贴在坐标 0 上）
            l_limit = left_boundary
            lpos = math.max(lpos, l_limit)
            r_limit = right_boundary
            rpos = math.min(rpos, r_limit)
        end
        -- 边界夹出反向区间时压到最近的边界线（零宽），别被 abs 镜像到边界另一侧；
        -- 没配边界时不干预，保留原来的 abs 兜底（事件本身给的反向区间照旧画）
        if lpos > rpos and (l_limit or r_limit) then
            if l_limit and natural_r <= l_limit then
                lpos, rpos = l_limit, l_limit
            elseif r_limit and natural_l >= r_limit then
                lpos, rpos = r_limit, r_limit
            else
                local mid = (lpos + rpos) / 2
                lpos, rpos = mid, mid
            end
        end
        return_x = (lpos + rpos) / 2
        return_w = math.abs(rpos - lpos)
    end

    return return_x, return_w
end

--- 点击选择事件，打开侧边栏编辑界面
-- @tparam string eventType 事件类型
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number|nil trackId 指定轨道（默认 track.track）
-- @treturn number|nil 事件索引
function event:click(eventType, pos, trackId)
    sidebar:to(ChartService:isEditingEventGroup() and 'event groups' or 'nil')
    local idx, foundEvent = findEventInRange(eventType, pos, trackId)
    if idx then
        sidebar.displayed_content = "event" .. idx
        sidebar:to("event", idx)
        event:cleanUp()
        return idx
    end
end

--- 删除指定位置的事件
-- @tparam string eventType 事件类型
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number|nil trackId 指定轨道（默认 track.track）
function event:delete(eventType, pos, trackId)
    sidebar:to(ChartService:isEditingEventGroup() and 'event groups' or 'nil')
    local _, foundEvent = findEventInRange(eventType, pos, trackId)
    if foundEvent then
        ChartService:delete(foundEvent, 'history.delete_' .. foundEvent:getType() .. '_event')
    end
end

--- 放置事件（支持长按放置头/尾）
-- @tparam string eventType 事件类型 ("x", "w", "lpos", "rpos")
-- @tparam number pos 屏幕 Y 坐标
-- @tparam number|nil trackId 指定轨道（默认 track.track）
-- @treturn boolean|nil 是否放置成功
function event:place(eventType, pos, trackId)
    if not table.find(event_type, eventType) then
        log('event type is note')
        return
    end
    if self.hold_type == 1 and self.local_event:getType() ~= eventType and
        (self.local_event:getType() == 'event_group' or eventType == 'event_group') then
        return false
    end

    local event_beat = beat:toNearby(CoordinateService:yToBeat(pos))

    if event.hold_type == 0 then
        -- 放置事件头
        event.local_event = Event.new()
        event.local_event:setType(eventType)
        event.local_event:setTrack(trackId or track.track)
        event.local_event:setBeat({ event_beat[1], event_beat[2], event_beat[3] })
        if eventType == 'event_group' then
            event.local_event:setEventGroup(self.selectedGroupName or '')
            local offset = ChartService:getPreferenceField('x_offset') or 0
            local scale = ChartService:getPreferenceField('event_scale') or 100
            event.local_event:setFrom(offset)
            event.local_event:setTo(offset + scale)
        end
        event.local_event:setEasings(transIndex.easings)
        event.local_event:setTransData(table.copy(event.bezier[transIndex.bezier]) or { 0, 0, 1, 1 })

        if settings.default_trans_type == 'easings' then
            event.local_event:setTransType('easings')
        else
            event.local_event:setTransType('bezier')
        end

        event.hold_type = 1

        -- 起点位于已有事件组内部时立即拒绝。
        for i = 1, ChartService:getTrackEventCount(event.local_event:getTrack(), 'event_group') do
            local existing = ChartService:getTrackEvent(event.local_event:getTrack(), 'event_group', i)
            if existing:getBeatValue() <= event.local_event:getBeatValue() and
                event.local_event:getBeatValue() < existing:getBeat2Value() then
                messageBox:add('illegal operation')
                self:cleanUp()
                return false
            end
        end

        -- 将初始值设为当前位置的事件值
        local x, w = event:get(event.local_event:getTrack(), event.local_event:getBeatValue(), true)
        if eventType == "x" then
            event.local_event:setFrom(x)
            event.local_event:setTo(x)
        elseif eventType == "w" then
            event.local_event:setFrom(w)
            event.local_event:setTo(w)
        elseif eventType == "lpos" then
            event.local_event:setFrom(x - w / 2)
            event.local_event:setTo(x - w / 2)
        elseif eventType == "rpos" then
            event.local_event:setFrom(x + w / 2)
            event.local_event:setTo(x + w / 2)
        end

    elseif event.hold_type == 1 then
        -- 放置事件尾
        event.local_event:setBeat2({ event_beat[1], event_beat[2], event_beat[3] })
        if event.local_event:getBeat2Value() <= event.local_event:getBeatValue() then
            -- 尾巴比头早或重叠，非法操作
            messageBox:add("illegal operation")
            event:cleanUp()
            return false
        elseif not ChartService:canPlaceEvent(event.local_event) then
            messageBox:add('illegal operation')
            event:cleanUp()
            return false
        else
            -- 合法操作，添加到谱面
            local ok = ChartService:add(event.local_event, 'history.add_' .. eventType .. '_event')
            if ok == false then
                messageBox:add('illegal operation')
                event:cleanUp()
                return false
            end
            event.hold_type = 2
        end
    end

    if event.hold_type == 2 then
        -- 长条放置完成，排序并打开编辑界面
        event:sort()
        local int_theevent = 1
        for i = 1, ChartService:getEventCount() do
            if ChartService:getEvent(i) == event.local_event then
                int_theevent = i
                break
            end
        end
        sidebar:to("event", int_theevent)
        event:cleanUp()
    end
end

--- 对事件列表排序（按 beat 升序）
-- 同时对 extra_chart 中的事件列表排序
function event:sort()
    ChartService:sortEvents()
end

--- 获取当前正在放置的长按事件数据
-- @treturn table 长按事件数据表
function event:getHoldTable()
    return event.local_event
end

return event
