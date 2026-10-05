-- 时间换算与谱面及索引排序；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)

    --- 将时间转换为 beat 值（基于当前谱面 BPM 列表）
    -- @tparam number nowtime 时间（秒）
    -- @treturn number beat 值
    function ChartService:toBeat(nowtime)
        return beat:toBeat(state.chart.bpm_list or {}, nowtime)
    end

    --- 将 beat 值转换为时间（基于当前谱面 BPM 列表）
    -- @tparam number|table isbeat beat 值
    -- @treturn number 时间（秒）
    function ChartService:toTime(isbeat)
        return beat:toTime(state.chart.bpm_list or {}, isbeat)
    end

    -- 偏移会改变实际时间排序；选择状态由订阅排序通知的界面维护。
    function ChartService:resortTimePositions()
        for _, list in ipairs({state.chart.note or {}, state.chart.event or {}}) do
            for _, entity in ipairs(list) do
                if type(entity.getBeatValue) ~= 'function' then return end
            end
        end
        self:sortNotes()
        self:sortEvents()

    end

    function ChartService:onTimeOffsetChanged(entity)
        if dependencies.recorder.inChartEntity(entity) then self:resortTimePositions() end
    end

    -- ============================================================
    -- 排序（同步排序 chart 和 extra_chart）
    -- ============================================================

    --- 对 BPM 列表按 beat 位置排序
    function ChartService:sortBpmList()
        local bpmlist = {}
        while #state.chart.bpm_list > 0 do
            local bpm_beat_min = 1
            for i = 1, #state.chart.bpm_list do
                if beat:get(state.chart.bpm_list[i].beat) < beat:get(state.chart.bpm_list[bpm_beat_min].beat) then
                    bpm_beat_min = i
                end
            end
            bpmlist[#bpmlist + 1] = state.chart.bpm_list[bpm_beat_min]
            table.remove(state.chart.bpm_list, bpm_beat_min)
        end
        for i = 1, #bpmlist do
            state.chart.bpm_list[i] = bpmlist[i]
        end
    end

    -- 发出旧索引到新索引的映射，不持有界面或选择状态。
    internal.sortWithIndexMap = function(list, kind)
        local before = {}
        for i, entity in ipairs(list) do before[i] = entity end
        table.sort(list, function(a, b) return a:getBeatValue() < b:getBeatValue() end)
        local indices, mapping = {}, {}
        for i, entity in ipairs(list) do indices[entity] = i end
        for i, entity in ipairs(before) do mapping[i] = indices[entity] end
        dependencies.eventBus:emit('chart:indices_changed', kind, mapping)
    end

    --- 对事件列表排序（按 beat 升序，同步排序 chart 和 extra_chart）
    function ChartService:sortEvents()
        internal.sortWithIndexMap(state.chart.event, 'event')
        for _, trackData in pairs(state.extra_chart.track) do
            for _, eventType in ipairs(event_type) do
                if trackData[eventType] then
                    table.sort(trackData[eventType], function(a, b) return a:getBeatValue() < b:getBeatValue() end)
                end
            end
        end
    end

    --- 对音符列表排序（按 beat 升序，同步排序 chart 和 extra_chart）
    function ChartService:sortNotes()
        internal.sortWithIndexMap(state.chart.note, 'note')
        for _, trackData in pairs(state.extra_chart.track) do
            table.sort(trackData.note, function(a, b) return a:getBeatValue() < b:getBeatValue() end)
        end
    end
end
