-- 音符与事件的增删；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)
    local recorder = dependencies.recorder

    --- 添加音符到谱面（自动同步索引；强制入撤销事务）
    -- @tparam Note note 音符对象
    -- @tparam string|nil actionKey 事务外调用时的记录说明键
    function ChartService:addNote(note, actionKey)
        if state.activeGroupEdit then return false end
        return self:change(actionKey, function()
            table.insert(state.chart.note, note)
            recorder.trackAdd(note)
            recorder.markIn(note)
            internal.addNoteToIndex(note)
            internal.emitMutation({kind = 'note_added', entity = note})
        end)
    end

    --- 从谱面删除音符（自动同步索引；强制入撤销事务）
    -- @tparam Note note 音符对象
    -- @tparam string|nil actionKey 事务外调用时的记录说明键
    -- @treturn boolean 是否删除成功
    function ChartService:deleteNote(note, actionKey)
        if state.activeGroupEdit then return false end
        return self:change(actionKey, function()
            local i = internal.findItemIndex(state.chart.note, note)
            if not i then return false end
            local actual = state.chart.note[i]
            recorder.trackDel(actual, i)
            table.remove(state.chart.note, i)
            recorder.unmarkIn(actual)
            internal.removeNoteFromIndex(actual)
            internal.emitMutation({kind = 'note_deleted', entity = actual})
            return true
        end)
    end

    --- 添加事件到谱面（自动同步索引；强制入撤销事务）
    -- @tparam Event event 事件对象
    -- @tparam string|nil actionKey 事务外调用时的记录说明键
    function ChartService:addEvent(event, actionKey)
        return self:change(actionKey, function()
            table.insert(state.chart.event, event)
            recorder.trackAdd(event)
            recorder.markIn(event)
            internal.addEventToIndex(event)
            internal.emitMutation({kind = 'event_added', entity = event})
        end)
    end

    --- 从谱面删除事件（自动同步索引；强制入撤销事务）
    -- @tparam Event event 事件对象
    -- @tparam string|nil actionKey 事务外调用时的记录说明键
    -- @treturn boolean 是否删除成功
    function ChartService:deleteEvent(event, actionKey)
        return self:change(actionKey, function()
            local i = internal.findItemIndex(state.chart.event, event)
            if not i then return false end
            local actual = state.chart.event[i]
            recorder.trackDel(actual, i)
            table.remove(state.chart.event, i)
            recorder.unmarkIn(actual)
            internal.removeEventFromIndex(actual)
            internal.emitMutation({kind = 'event_deleted', entity = actual})
            return true
        end)
    end

    --- 添加 note 或 event 到谱面（强制入撤销事务）
    -- @tparam Note|Event noteorevent 要添加的音符或事件数据
    -- @tparam string|nil actionKey 记录说明键
    function ChartService:add(noteorevent, actionKey)
        local typeName = noteorevent.type or (noteorevent._data and noteorevent:getType())
        local isEvent = internal.isEventType(typeName)
        local isNote = internal.isNoteType(typeName)
        if state.activeGroupEdit and isNote then return false end

        if not isEvent and not isNote then
            return -- 未知类型，忽略
        end

        local result
        if isEvent then
            if not self:canPlaceEvent(noteorevent) then return false, 'event group overlap' end
            result = self:change(actionKey, function()
                local added = self:addEvent(noteorevent)
                self:sortEvents()
                return added
            end)
        else
            result = self:change(actionKey, function()
                local added = self:addNote(noteorevent)
                self:sortNotes()
                return added
            end)
        end

        -- 触发插件钩子
        if PluginManager then
            if isEvent then
                PluginManager:emit('onEventAdd', noteorevent)
            else
                PluginManager:emit('onNoteAdd', noteorevent)
            end
        end
        return result
    end

    --- 从谱面删除 note 或 event（强制入撤销事务）
    -- @tparam Note|Event noteorevent 要删除的音符或事件数据
    -- @tparam string|nil actionKey 记录说明键
    function ChartService:delete(noteorevent, actionKey)
        local typeName = noteorevent.type or (noteorevent._data and noteorevent:getType())
        local isEvent = internal.isEventType(typeName)
        local isNote = internal.isNoteType(typeName)
        if state.activeGroupEdit and isNote then return false end

        if not isEvent and not isNote then
            return -- 未知类型，忽略
        end

        local result
        if isEvent then
            local i = internal.findItemIndex(state.chart.event, noteorevent)
            if i then result = self:deleteEvent(state.chart.event[i], actionKey) end
        else
            local i = internal.findItemIndex(state.chart.note, noteorevent)
            if i then result = self:deleteNote(state.chart.note[i], actionKey) end
        end

        -- 触发插件钩子
        if PluginManager then
            if isEvent then
                PluginManager:emit('onEventDelete', noteorevent)
            else
                PluginManager:emit('onNoteDelete', noteorevent)
            end
        end
        return result
    end

end
