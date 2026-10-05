local TimeOffset = require('src.utils.timeOffset')
-- 事件组定义、独立编辑与范围互斥；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)
    local Event = dependencies.Event
    local eventBus = dependencies.eventBus
    local recorder = dependencies.recorder

    -- 事件组名称直接作为 JSON 字典键使用，不参与代码执行。
    internal.validGroupName = function(name)
        return type(name) == 'string' and #name > 0 and #name <= 128 and
            not name:match('^%s*$') and not name:find('[%c/\\]') and
            name ~= '__index' and name ~= '__newindex' and name ~= '__metatable'
    end

    local function finiteNumber(value)
        return type(value) == 'number' and value == value and
            value ~= math.huge and value ~= -math.huge
    end

    local function validBeat(value)
        return type(value) == 'table' and finiteNumber(value[1]) and
            finiteNumber(value[2]) and finiteNumber(value[3]) and value[3] > 0 and
            value[1] % 1 == 0 and value[2] % 1 == 0 and value[3] % 1 == 0
    end

    local function validInnerEvent(value)
        if type(value) ~= 'table' or not table.find(event_property_type, value.type) or
            not validBeat(value.beat) or not validBeat(value.beat2) or
            beat:get(value.beat2) <= beat:get(value.beat) or
            not finiteNumber(value.from) or not finiteNumber(value.to) or
            (value.time_offset ~= nil and not TimeOffset.valid(value.time_offset)) then return false end
        local trans = value.trans
        if type(trans) ~= 'table' or (trans.type ~= 'bezier' and trans.type ~= 'easings' and trans.type ~= 'custom') then return false end
        if trans.type == 'bezier' then
            if type(trans.trans) ~= 'table' or #trans.trans ~= 4 then return false end
            for _, point in ipairs(trans.trans) do if not finiteNumber(point) then return false end end
        elseif trans.type=='custom' then
            if type(trans.custom)~='string' or #trans.custom>128 then return false end
        elseif not finiteNumber(trans.easings) or trans.easings < 1 or
            trans.easings > #easings or trans.easings % 1 ~= 0 then return false end
        return true
    end

    local function groupChart()
        return state.activeGroupEdit and state.activeGroupEdit.mainChart or state.chart
    end

    function ChartService:isEditingEventGroup()
        return state.activeGroupEdit and state.activeGroupEdit.name or nil
    end

    -- 编辑时临时切换到只含组内事件的一条轨道。原谱面与索引原样保留。
    function ChartService:beginEventGroupEdit(name)
        if state.activeGroupEdit then return false end
        local definition = state.chart.event_groups and state.chart.event_groups[name]
        if not definition then return false end
        local events = {}
        for _, data in ipairs(definition.event or {}) do
            if not validInnerEvent(data) then return false end
            local copy = table.copy(data)
            copy.track = 1
            events[#events + 1] = Event.new(copy)
        end
        state.activeGroupEdit = {
            name = name, mainChart = state.chart, mainIndex = state.extra_chart,
            before = table.copy(state.chart.event_groups),
        }
        local editTrack = table.copy(meta_track.__index)
        editTrack.w0thenShow = 1
        state.chart = {
            event = events, note = {}, effect = {}, event_groups = {},
            bpm_list = table.copy(state.activeGroupEdit.mainChart.bpm_list),
            preference = table.copy(state.activeGroupEdit.mainChart.preference),
            info = table.copy(state.activeGroupEdit.mainChart.info),
            offset = state.activeGroupEdit.mainChart.offset,
            track = {['1'] = editTrack},
        }
        state.extra_chart = {track = {}}
        for _, event in ipairs(events) do internal.addEventToIndex(event) end
        self:sortEvents()
        recorder.reset()
        internal.rebuildRegistry()
        -- 通知订阅方挂起自身状态（如撤销栈），组内编辑使用独立状态
        eventBus:emit('chart:group_edit_begin')
        eventBus:emit('chart:changed', {kind = 'group_edit_begin', group = name})
        state.eventGroupsRevision = state.eventGroupsRevision + 1
        return true
    end

    -- 读取当前组内事件的独立快照，不同步或发送修改通知。
    function ChartService:copyEditingGroupEvents()
        local events = {}
        for _, event in ipairs(state.chart.event) do
            local value = event:toTable()
            local data = {
                type = value.type, beat = table.copy(value.beat), beat2 = table.copy(value.beat2),
                from = value.from, to = value.to, trans = table.copy(value.trans),
                time_offset = value.time_offset,
            }
            if not validInnerEvent(data) then return nil end
            data.track = nil
            events[#events + 1] = data
        end
        return events
    end

    -- 自动保存和手动保存显式同步当前编辑轨道到原谱面。
    function ChartService:syncEventGroupEdit()
        local session = state.activeGroupEdit
        if not session then return true end
        local events = self:copyEditingGroupEvents()
        if not events then return false end
        local definition = session.mainChart.event_groups[session.name]
        if not definition then return false end
        if not table.eq(definition.event, events) then
            local before = table.copy(session.mainChart.event_groups)
            definition.event = events
            state.eventGroupsRevision = state.eventGroupsRevision + 1
            internal.emitMutation({kind = 'group_updated', group = session.name,
                before = before[session.name], after = table.copy(definition)})
            eventBus:emit('chart:changed', {kind = 'group_sync', group = session.name,
                operation = {add = {event = {}, note = {}}, del = {event = {}, note = {}},
                    groups_before = before, groups_after = table.copy(session.mainChart.event_groups)}})
        end
        return true
    end

    function ChartService:finishEventGroupEdit()
        local session = state.activeGroupEdit
        if not session then return true end
        eventBus:emit('chart:group_edit_ending')
        local ok = self:syncEventGroupEdit()
        if not ok then return false end
        state.chart, state.extra_chart = session.mainChart, session.mainIndex
        state.activeGroupEdit = nil
        recorder.reset()
        internal.rebuildRegistry()
        -- 通知订阅方恢复挂起的状态，并带上组定义变更供撤销记录
        local operation = {
            add = {event = {}, note = {}}, del = {event = {}, note = {}},
            groups_before = session.before, groups_after = table.copy(state.chart.event_groups),
        }
        eventBus:emit('chart:group_edit_end', operation, 'history.edit_event_group')
        eventBus:emit('chart:changed', {kind = 'group_edit_end', group = session.name,
            operation = operation, actionKey = 'history.edit_event_group'})
        state.eventGroupsRevision = state.eventGroupsRevision + 1
        return true
    end

    function ChartService:getEventGroupNames()
        local names = {}
        for name in pairs(groupChart().event_groups or {}) do names[#names + 1] = name end
        table.sort(names)
        return names
    end

    function ChartService:getEventGroup(name)
        local groups = groupChart().event_groups
        local value = groups and groups[name]
        return type(value) == 'table' and table.copy(value) or nil
    end
    function ChartService:getEventGroupsRevision()
        return state.eventGroupsRevision
    end

    -- 仅供撤销/重做恢复整份组定义，调用者不能取得内部表引用。
    function ChartService:copyEventGroups()
        return table.copy(groupChart().event_groups or {})
    end
    function ChartService:setEventGroups(value)
        if state.activeGroupEdit then return false end
        local nextGroups = table.copy(value or {})
        if table.eq(state.chart.event_groups, nextGroups) then return false end
        state.chart.event_groups = nextGroups
        state.eventGroupsRevision = state.eventGroupsRevision + 1
        if not recorder.suspended() then
            internal.emitMutation({kind = 'group_definitions_updated'})
            eventBus:emit('chart:changed', {kind = 'group_definitions'})
        end
        return true
    end

    -- 一个操作提交一个组定义；改名时同步更新谱面中的所有引用。
    function ChartService:putEventGroup(name, value, oldName, actionKey)
        if state.activeGroupEdit then return false, 'finish editing first' end
        if not internal.validGroupName(name) or type(value) ~= 'table' or type(value.event) ~= 'table' then
            return false, 'invalid name or event list'
        end
        oldName = oldName or name
        if oldName ~= name and state.chart.event_groups[name] then return false, 'name already exists' end
        for _, inner in ipairs(value.event) do
            if not validInnerEvent(inner) then return false, 'invalid event' end
        end
        if oldName == name and table.eq(state.chart.event_groups[name],
            {name = name, event = value.event}) then return true end
        local before = self:copyEventGroups()
        local oldRefs, newRefs = {}, {}
        if oldName ~= name then
            self:suspend(function()
                for _, e in ipairs(state.chart.event) do
                    if e:getType() == 'event_group' and e:getEventGroup() == oldName then
                        oldRefs[#oldRefs + 1] = e:copy()
                        e:setEventGroup(name)
                        newRefs[#newRefs + 1] = e:copy()
                    end
                end
            end)
            state.chart.event_groups[oldName] = nil
        end
        state.chart.event_groups[name] = {name = name, event = table.copy(value.event)}
        state.eventGroupsRevision = state.eventGroupsRevision + 1
        internal.emitMutation({kind = 'group_updated', group = name, before = before[oldName],
            after = table.copy(state.chart.event_groups[name])})
        local operation = {
            add = {event = newRefs, note = {}}, del = {event = oldRefs, note = {}},
            groups_before = before, groups_after = self:copyEventGroups(),
        }
        eventBus:emit('chart:committed', operation, actionKey or 'history.edit_event_group')
        eventBus:emit('chart:changed', {kind = 'commit', operation = operation,
            actionKey = actionKey or 'history.edit_event_group'})
        return true
    end

    function ChartService:deleteEventGroup(name)
        if state.activeGroupEdit then return false end
        if not state.chart.event_groups[name] then return false end
        local before = self:copyEventGroups()
        state.chart.event_groups[name] = nil
        state.eventGroupsRevision = state.eventGroupsRevision + 1
        internal.emitMutation({kind = 'group_deleted', group = name, before = before[name]})
        local operation = {
            add = {event = {}, note = {}}, del = {event = {}, note = {}},
            groups_before = before, groups_after = self:copyEventGroups(),
        }
        eventBus:emit('chart:committed', operation, 'history.delete_event_group')
        eventBus:emit('chart:changed', {kind = 'commit', operation = operation,
            actionKey = 'history.delete_event_group'})
        return true
    end

    -- 组引用独占当前轨道的时间段；普通事件只与组引用互斥。
    function ChartService:canPlaceEvent(candidate, ignored)
        local kind = candidate:getType()
        if state.activeGroupEdit and kind == 'event_group' then return false end
        local from, to = candidate:getBeatValue(), candidate:getBeat2Value()
        if not finiteNumber(from) or not finiteNumber(to) or to <= from then return false end
        local function conflicts(existing)
            if rawequal(existing, ignored) or (type(ignored) == 'table' and ignored[existing]) or
                rawequal(existing, candidate) or
                existing:getTrack() ~= candidate:getTrack() then return false end
            if kind ~= 'event_group' and existing:getType() ~= 'event_group' then return false end
            return from < existing:getBeat2Value() and to > existing:getBeatValue()
        end
        for _, existing in ipairs(state.chart.event) do
            if conflicts(existing) then return false end
        end
        return true
    end

end
