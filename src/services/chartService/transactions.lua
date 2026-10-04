-- 变更事务、成员注册与失败回滚；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)
    local eventBus = dependencies.eventBus
    local recorder = dependencies.recorder

    --- 重建成员注册表（哪些实体当前属于谱面——setter 拦截据此决定是否记录）
    function internal.rebuildRegistry()
        recorder.clearIn()
        for i = 1, #(state.chart.event or {}) do recorder.markIn(state.chart.event[i]) end
        for i = 1, #(state.chart.note or {}) do recorder.markIn(state.chart.note[i]) end
    end

    --- 读取字段现值（事务提交时与 fields_before 对比）
    function internal.currentFieldValue(kind, key)
        if kind == 'offset' then return state.chart.offset or 0 end
        if kind == 'info' then return state.chart.info and state.chart.info[key] or nil end
        if kind == 'preference' then return state.chart.preference and state.chart.preference[key] or nil end
        if kind == 'track' then
            return state.chart.track and state.chart.track[tostring(key)] and table.copy(state.chart.track[tostring(key)]) or nil
        end
        if kind == 'bpm_list' then return state.chart.bpm_list and table.copy(state.chart.bpm_list) or nil end
    end

    --- 提交当前事务：补齐字段前后值后广播 chart:committed（无实际变更则不产生记录）
    function internal.commitTxn(actionKey)
        local t = recorder.txn and recorder.txn() or nil
        if not t then return false end
        local fieldsAfter = {}
        for _, entry in pairs(t.fields_before) do
            fieldsAfter[#fieldsAfter + 1] = {kind = entry.kind, key = entry.key,
                value = internal.currentFieldValue(entry.kind, entry.key)}
        end
        return recorder.commit(actionKey, fieldsAfter)
    end

    --- 在变更事务中执行 fn：无事务时自动开一个并在结束后提交（强制记录的统一入口）
    -- 已有事务（手势批量 / push 批量）时 fn 直接执行，记录归入外层事务
    -- @treturn any fn 的返回值原样透传
    function ChartService:change(actionKey, fn)
        if recorder.suspended() then return fn() end
        return recorder.protect(function()
            local had = recorder.hasTxn()
            if not had then recorder.begin() end
            local results = {n = 0}
            local function collect(...)
                results = {n = select('#', ...), ...}
            end
            collect(fn())
            if not had then internal.commitTxn(actionKey) end
            return unpack(results, 1, results.n)
        end)
    end

    --- 打开/提交一个跨帧的事务（拖拽等无法用 change 包住的手势）
    function ChartService:beginChange()
        recorder.begin()
    end

    --- 提交当前事务（通常与 beginChange 配对；由手势层提供 actionKey）
    function ChartService:commitChange(actionKey)
        if recorder.suspended() then recorder.reset(); return false end
        return recorder.protect(function() return internal.commitTxn(actionKey) end)
    end

    --- 放弃当前事务（不产生记录；调用方需自行把谱面恢复原状）
    function ChartService:abortChange()
        recorder.reset()
    end

    --- 手动快照一个图谱面实体（内容经嵌套表直接修改而未经 setter 的场景，先调本函数）
    function ChartService:snapshotEntity(e)
        recorder.beforeEntityChange(e)
    end

    --- 豁免区间：fn 内的谱面变更不产生撤销记录（撤销回放 / 内部定位舞步专用）
    function ChartService:suspend(fn)
        return recorder.suspend(fn)
    end

    -- ============================================================
    -- 批量操作
    -- ============================================================

    --- 开始批量操作：push 与 pop 之间的所有变更（增删/内容/字段）归入同一事务，
    --- pop 时合并为一条撤销记录。变更在事务期间即时生效（chart 即实时状态）
    function ChartService:push()
        recorder.begin()
    end

    --- 结束批量操作：合并为一条撤销记录并排序
    -- @tparam string actionKey 本次操作的 i18n 说明键
    function ChartService:pop(actionKey)
        self:sortNotes()
        self:sortEvents()
        internal.commitTxn(actionKey)
    end

    -- ============================================================
    -- 失败回滚
    -- ============================================================

    -- 恢复失败事务时保留实体引用，并重建索引，避免插件继续读取中间状态。
    recorder.setRollbackHandler(function(t)
        recorder.suspend(function()
            for e, old in pairs(t.snap) do e._data = table.copy(old._data) end
            for i = #t.journal, 1, -1 do
                local entry = t.journal[i]
                local list = state.chart[entry.kind]
                if entry.added then
                    for j = #list, 1, -1 do
                        if rawequal(list[j], entry.entity) then table.remove(list, j); break end
                    end
                else
                    table.insert(list, entry.index or (#list + 1), entry.entity)
                end
            end
            local fields = {}
            for _, entry in pairs(t.fields_before) do fields[#fields + 1] = entry end
            ChartService:restoreFields(fields)
            state.extra_chart = {track = {}}
            for _, e in ipairs(state.chart.event or {}) do internal.addEventToIndex(e) end
            for _, n in ipairs(state.chart.note or {}) do internal.addNoteToIndex(n) end
            internal.rebuildRegistry()
        end)
        eventBus:emit('chart:changed', {kind = 'rollback'})
    end)
end
