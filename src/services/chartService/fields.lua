-- 标量字段、BPM 表与轨道定义；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)
    local recorder = dependencies.recorder

    --- 获取音频偏移量
    -- @treturn number 偏移量（毫秒）
    function ChartService:getOffset()
        return state.chart.offset or 0
    end

    --- 设置音频偏移量
    -- @tparam number v 偏移量（毫秒）
    function ChartService:setOffset(v)
        self:change(nil, function()
            local before = state.chart.offset or 0
            recorder.touchField('offset', nil, before)
            state.chart.offset = v
            if internal.valuesDiffer(before, v) then
                internal.emitMutation({kind = 'field_updated', field = 'offset', before = before, after = v})
            end
        end)
    end

    --- 获取谱面信息字段（song_name / chart_name / chartor / artist）
    -- @tparam string field 字段名
    -- @treturn string|nil 字段值
    function ChartService:getInfoField(field)
        local value = state.chart.info and state.chart.info[field]
        return type(value) == 'table' and table.copy(value) or value
    end

    --- 设置谱面信息字段（song_name / chart_name / chartor / artist）
    -- @tparam string field 字段名
    -- @tparam any v 字段值
    function ChartService:setInfoField(field, v)
        self:change(nil, function()
            local before = state.chart.info and state.chart.info[field] or nil
            recorder.touchField('info', field, before)
            state.chart.info[field] = type(v) == 'table' and table.copy(v) or v
            if internal.valuesDiffer(before, v) then
                internal.emitMutation({kind = 'field_updated', field = 'info', key = field,
                    before = before, after = v})
            end
        end)
    end

    --- 获取偏好字段（x_offset / event_scale）
    -- @tparam string field 字段名
    -- @treturn number|nil 字段值
    function ChartService:getPreferenceField(field)
        local value = state.chart.preference and state.chart.preference[field]
        return type(value) == 'table' and table.copy(value) or value
    end

    --- 设置偏好字段（x_offset / event_scale）
    -- @tparam string field 字段名
    -- @tparam number v 字段值
    function ChartService:setPreferenceField(field, v)
        self:change(nil, function()
            local cur = state.chart.preference and state.chart.preference[field] or nil
            recorder.touchField('preference', field, type(cur) == 'table' and table.copy(cur) or cur)
            state.chart.preference[field] = type(v) == 'table' and table.copy(v) or v
            if internal.valuesDiffer(cur, v) then
                internal.emitMutation({kind = 'field_updated', field = 'preference', key = field,
                    before = cur, after = v})
            end
        end)
    end

    --- 整体替换 BPM 列表（chart_info 界面保存时使用）
    -- @tparam table list 新的 BPM 列表
    function ChartService:setBpmList(list)
        self:change(nil, function()
            local before = state.chart.bpm_list and table.copy(state.chart.bpm_list) or nil
            recorder.touchField('bpm_list', nil, before)
            state.chart.bpm_list = list and table.copy(list) or nil
            self:resortTimePositions()
            if internal.valuesDiffer(before, state.chart.bpm_list) then
                internal.emitMutation({kind = 'field_updated', field = 'bpm_list',
                    before = before, after = state.chart.bpm_list and table.copy(state.chart.bpm_list) or nil})
            end
        end)
    end

    -- ============================================================
    -- 轨道定义（chart.track，懒创建）
    -- ============================================================

    --- 确保轨道定义存在（不存在则创建默认定义）
    -- @tparam number trackId 轨道ID
    function ChartService:ensureTrack(trackId)
        local key = tostring(trackId)
        if state.chart.track[key] then return end
        self:change(nil, function()
            recorder.touchField('track', trackId, nil)
            state.chart.track[key] = table.copy(meta_track.__index)
            internal.emitMutation({kind = 'track_created', field = 'track', key = trackId,
                after = table.copy(state.chart.track[key])})
        end)
    end

    --- 读取缺省值也不创建轨道定义。
    function ChartService:getTrackField(trackId, field)
        local definition = state.chart.track and state.chart.track[tostring(trackId)]
        local value = definition and definition[field]
        if value == nil then value = meta_track.__index[field] end
        return type(value) == 'table' and table.copy(value) or value
    end

    --- 仅实际修改时创建轨道，创建前的缺失状态也进入撤销记录。
    function ChartService:setTrackField(trackId, field, v)
        if not internal.valuesDiffer(self:getTrackField(trackId, field), v) then return end
        self:change(nil, function()
            local key = tostring(trackId)
            local before = state.chart.track[key] and table.copy(state.chart.track[key]) or nil
            recorder.touchField('track', trackId, before)
            self:ensureTrack(trackId)
            state.chart.track[key][field] = type(v) == 'table' and table.copy(v) or v
            internal.emitMutation({kind = 'field_updated', field = 'track', key = trackId,
                before = before, after = table.copy(state.chart.track[key]), method = field})
        end)
    end

    --- 撤销/重做回放：按操作记录恢复字段值（须处于豁免期内调用）
    -- @tparam table entries fields_before 或 fields_after 列表 {kind=, key=, value=}
    function ChartService:restoreFields(entries)
        for _, entry in ipairs(entries or {}) do
            local kind, key, value = entry.kind, entry.key, entry.value
            -- 表值拷贝防污染（恢复后的修改不得写穿到撤销记录），标量直接赋值
            local function detach(v) return type(v) == 'table' and table.copy(v) or v end
            if kind == 'offset' then
                state.chart.offset = value
            elseif kind == 'info' then
                state.chart.info[key] = detach(value)
            elseif kind == 'preference' then
                state.chart.preference[key] = detach(value)
            elseif kind == 'track' then
                if value then
                    state.chart.track[tostring(key)] = detach(value)
                else
                    state.chart.track[tostring(key)] = nil
                end
            elseif kind == 'bpm_list' then
                state.chart.bpm_list = detach(value)
                if state.chart.bpm_list then self:sortBpmList() end
            end
        end
    end

end
