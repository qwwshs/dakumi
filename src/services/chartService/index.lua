-- 实体类型判断、索引维护与列表读取；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)
    local eventBus = dependencies.eventBus
    local recorder = dependencies.recorder

    function internal.emitMutation(change)
        if not recorder.suspended() then eventBus:emit('chart:mutated', change) end
    end

    function internal.valuesDiffer(a, b)
        if type(a) == 'table' and type(b) == 'table' then return not table.eq(a, b) end
        return a ~= b
    end

    --- 判断是否为事件类型
    -- @tparam string typeName 类型名
    -- @treturn boolean
    function internal.isEventType(typeName)
        return table.find(event_type, typeName) ~= false
    end

    --- 判断是否为音符类型
    -- @tparam string typeName 类型名
    -- @treturn boolean
    function internal.isNoteType(typeName)
        return typeName == 'note' or typeName == 'hold' or typeName == 'wipe'
    end

    --- 优先按对象引用查找，兼容原有按内容相等的调用。
    function internal.findItemIndex(list, item)
        for i = 1, #list do
            if rawequal(list[i], item) then return i end
        end
        for i = 1, #list do
            if list[i] == item then return i end
        end
        return nil
    end

    --- 确保 extra_chart 中指定轨道存在
    -- @tparam number trackId 轨道ID
    function internal.ensureTrackIndex(trackId)
        if state.extra_chart.track[trackId] == nil then
            state.extra_chart.track[trackId] = table.copy(meta_extra_chart_track)
        end
    end

    --- 向 extra_chart 添加事件（内部方法）
    -- @tparam Event event 事件对象
    function internal.addEventToIndex(event)
        if type(event.getTrack) ~= "function" then return end
        local trackId = event:getTrack()
        local eventType = event:getType()
        internal.ensureTrackIndex(trackId)
        table.insert(state.extra_chart.track[trackId][eventType], event)
    end

    --- 向 extra_chart 添加音符（内部方法）
    -- @tparam Note note 音符对象
    function internal.addNoteToIndex(note)
        if type(note.getTrack) ~= "function" then return end
        local trackId = note:getTrack()
        internal.ensureTrackIndex(trackId)
        table.insert(state.extra_chart.track[trackId].note, note)
    end

    --- 从 extra_chart 删除事件（内部方法）
    -- @tparam Event event 事件对象
    function internal.removeEventFromIndex(event)
        local trackId = event:getTrack()
        local eventType = event:getType()
        if not state.extra_chart.track[trackId] then return end
        local list = state.extra_chart.track[trackId][eventType]
        if not list then return end
        local i = internal.findItemIndex(list, event)
        if i then table.remove(list, i) end
    end

    --- 从 extra_chart 删除音符（内部方法）
    -- @tparam Note note 音符对象
    function internal.removeNoteFromIndex(note)
        local trackId = note:getTrack()
        if not state.extra_chart.track[trackId] then return end
        local list = state.extra_chart.track[trackId].note
        if not list then return end
        local i = internal.findItemIndex(list, note)
        if i then table.remove(list, i) end
    end

    -- ============================================================
    -- 谱面列表读取
    -- ============================================================

    --- 获取音符数量
    -- @treturn number 音符数
    function ChartService:getNoteCount()
        return state.chart.note and #state.chart.note or 0
    end

    --- 获取指定下标的音符对象（实体，字段修改走 Note 方法）
    -- @tparam number i 下标（1 起）
    -- @treturn Note|nil 音符对象
    function ChartService:getNote(i)
        return state.chart.note and state.chart.note[i] or nil
    end

    --- 获取事件数量
    -- @treturn number 事件数
    function ChartService:getEventCount()
        return state.chart.event and #state.chart.event or 0
    end

    --- 获取指定下标的事件对象（实体，字段修改走 Event 方法）
    -- @tparam number i 下标（1 起）
    -- @treturn Event|nil 事件对象
    function ChartService:getEvent(i)
        return state.chart.event and state.chart.event[i] or nil
    end

    --- 获取 BPM 列表数量
    -- @treturn number BPM 数
    function ChartService:getBpmCount()
        return state.chart.bpm_list and #state.chart.bpm_list or 0
    end

    --- 获取指定下标的 BPM 条目
    -- @tparam number i 下标（1 起）
    -- @treturn table|nil BPM 条目 {beat={...}, bpm=..., linear_ramp=...}
    function ChartService:getBpm(i)
        return state.chart.bpm_list and state.chart.bpm_list[i] and table.copy(state.chart.bpm_list[i]) or nil
    end

    --- 获取效果数量
    -- @treturn number 效果数
    function ChartService:getEffectCount()
        return state.chart.effect and #state.chart.effect or 0
    end

    --- 获取指定下标的效果条目
    -- 注意：效果条目是普通表（非对象），当前全项目仅 play.lua 只读遍历，无写入路径
    -- @tparam number i 下标（1 起）
    -- @treturn table|nil 效果条目
    function ChartService:getEffect(i)
        return state.chart.effect and state.chart.effect[i] and table.copy(state.chart.effect[i]) or nil
    end

    -- ============================================================
    -- extra_chart 索引查询（只读，不返回内部列表）
    -- ============================================================

    --- 检查指定轨道是否存在于索引中
    -- @tparam number trackId 轨道ID
    -- @treturn boolean 是否存在
    function ChartService:hasTrack(trackId)
        return state.extra_chart.track[trackId] ~= nil
    end

    --- 检查谱面里是否已存在该轨道定义
    -- 与 hasTrack 的区别：hasTrack 查 extra_chart 索引（有事件才有条目），本函数查 chart.track 本体
    -- @tparam number trackId 轨道ID
    -- @treturn boolean 是否存在
    function ChartService:hasTrackData(trackId)
        return state.chart.track ~= nil and state.chart.track[tostring(trackId)] ~= nil
    end

    --- 获取指定轨道指定类型的事件数量
    -- @tparam number trackId 轨道ID
    -- @tparam string eventType 事件类型 ("x", "w", "lpos", "rpos")
    -- @treturn number 事件数
    function ChartService:getTrackEventCount(trackId, eventType)
        local trackData = state.extra_chart.track[trackId]
        if not trackData then return 0 end
        local list = trackData[eventType]
        return list and #list or 0
    end

    --- 获取指定轨道指定类型的第 i 个事件对象
    -- @tparam number trackId 轨道ID
    -- @tparam string eventType 事件类型 ("x", "w", "lpos", "rpos")
    -- @tparam number i 下标（1 起）
    -- @treturn Event|nil 事件对象
    function ChartService:getTrackEvent(trackId, eventType, i)
        local trackData = state.extra_chart.track[trackId]
        if not trackData then return nil end
        local list = trackData[eventType]
        return list and list[i] or nil
    end

end
