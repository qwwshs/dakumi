local TimeOffset = require('src.utils.timeOffset')
-- 谱面加载、格式迁移、保存与序列化；由 init.lua 注入唯一私有状态。
return function(ChartService, state, internal, dependencies)
    local Note = dependencies.Note
    local Event = dependencies.Event
    local eventBus = dependencies.eventBus
    local recorder = dependencies.recorder

    --- 替换整张谱面数据（菜单选谱/导入旧格式时调用）
    -- 深拷贝数据并补齐默认字段，同时清空旧索引（由 load() 重建）
    -- @tparam table data 谱面数据表
    function ChartService:setChart(data)
        if state.activeGroupEdit then
            local groups = sidebar and sidebar:getGroup('event groups')
            local ok
            if groups then ok = groups:exitGroup(true) else ok = self:finishEventGroupEdit() end
            if not ok then return false end
        end
        state.chart = table.copy(data or {})
        table.fill(state.chart, meta_chart.__index)
        if type(state.chart.custom_trans)~='table' then state.chart.custom_trans={} end
        if type(state.chart.event_groups) ~= 'table' then state.chart.event_groups = {} end
        state.eventGroupsRevision = state.eventGroupsRevision + 1
        state.extra_chart = { track = {} }
        recorder.reset()
        internal.rebuildRegistry()
        eventBus:emit('chart:replaced')
        eventBus:emit('chart:changed', {kind = 'replace'})
    end

    --- 更新谱面数据（版本迁移和字段填充）
    -- 修复旧版本数据格式，填充缺失字段
    function ChartService:update()
        -- 修复旧版本的 "form" 拼写错误（应为 "from"）
        local find_form = false
        for i = 1, #state.chart.event do
            if state.chart.event[i].form then
                state.chart.event[i].from = state.chart.event[i].form
                state.chart.event[i].form = nil
                find_form = true
            end
        end

        -- 为 note 填充 fake 字段（默认值 0）
        for i = 1, #state.chart.note do
            state.chart.note[i].fake = state.chart.note[i].fake or 0
        end

        -- 迁移 event 的 trans 数据格式
        -- 旧格式: trans = {0, 0, 1, 1}（数组）
        -- 新格式: trans = {trans = {0, 0, 1, 1}, type = "bezier", easings = 1}
        for i = 1, #state.chart.event do
            local trans = state.chart.event[i].trans
            if type(trans) ~= 'table' then
                trans = table.copy(meta_event.__index.trans)
                state.chart.event[i].trans = trans
            end
            if #trans > 0 then
                local trans_tab = {}
                for j = 1, #trans do
                    trans_tab[j] = trans[j]
                end
                for j = 1, #trans do
                    state.chart.event[i].trans[j] = nil
                end
                state.chart.event[i].trans.trans = trans_tab
            end
            trans.type = trans.type or 'bezier'
            trans.easings = trans.easings or 1
        end

        -- 组内事件使用与谱面事件相同的过渡数据格式。
        for name, groupData in pairs(state.chart.event_groups) do
            if not internal.validGroupName(name) or type(groupData) ~= 'table' then
                state.chart.event_groups[name] = nil
            else
                groupData.name = name
                if type(groupData.event) ~= 'table' then groupData.event = {} end
                for index, inner in ipairs(groupData.event) do
                    if type(inner) ~= 'table' then
                        groupData.event[index] = nil
                    else
                        inner.time_offset = TimeOffset.normalize(inner.time_offset)
                        if type(inner.trans) ~= 'table' then
                            inner.trans = table.copy(meta_event.__index.trans)
                        elseif #inner.trans > 0 then
                            inner.trans = {trans = table.copy(inner.trans), type = 'bezier', easings = 1}
                        end
                        inner.trans.type = inner.trans.type or 'bezier'
                        inner.trans.easings = inner.trans.easings or 1
                    end
                end
            end
        end

        -- 为 hold 类型 note 填充 note_head 和 wipe_head 字段
        for i = 1, #state.chart.note do
            if state.chart.note[i].type == 'hold' then
                state.chart.note[i].note_head = state.chart.note[i].note_head or 0
                state.chart.note[i].wipe_head = state.chart.note[i].wipe_head or 0
            end
        end

        -- 为 track 填充默认字段
        for i, v in pairs(state.chart.track) do
            table.fill(v, meta_track.__index)
        end

        -- 为 BPM 列表填充默认字段
        for i, v in pairs(state.chart.bpm_list) do
            table.fill(v, meta_bpm.__index)
        end
    end

    --- 加载谱面数据（构建 extra_chart 索引）
    -- 仅在内存中迁移格式、转换对象并构建索引；持久化由 save 显式执行
    function ChartService:load()
        if state.activeGroupEdit then
            local groups = sidebar and sidebar:getGroup('event groups')
            local ok
            if groups then ok = groups:exitGroup(true) else ok = self:finishEventGroupEdit() end
            if not ok then return false end
        end
        self:update()

        -- 将 note 纯 table 转为 Note 对象
        for i = 1, #state.chart.note do
            local n = state.chart.note[i]
            if type(n) ~= "table" or type(n.getTrack) ~= "function" then
                local data = type(n) == "table" and (n._data or n) or {}
                state.chart.note[i] = Note.new(data)
            end
        end

        -- 将 event 纯 table 转为 Event 对象
        for i = 1, #state.chart.event do
            local e = state.chart.event[i]
            if type(e) ~= "table" or type(e.getTrack) ~= "function" then
                local data = type(e) == "table" and (e._data or e) or {}
                state.chart.event[i] = Event.new(data)
            end
        end

        -- 重建 extra_chart 索引
        state.extra_chart = { track = {} }
        for i = 1, #state.chart.event do
            local e = state.chart.event[i]
            internal.addEventToIndex(e)
        end
        for i = 1, #state.chart.note do
            local n = state.chart.note[i]
            internal.addNoteToIndex(n)
        end
        self:resortTimePositions()
        -- 纯表转为模型后重新注册，否则载入的事件 setter 不会进入撤销栈。
        internal.rebuildRegistry()
        eventBus:emit('chart:changed', {kind = 'load'})
        return true
    end

    --- 序列化保存谱面（内部把私有 chart 交给 save 处理）
    -- @tparam string name 保存文件名（"chart.json" / "chart.json.auto" / 其它路径）
    function ChartService:save(name)
        if state.activeGroupEdit then
            local ok = self:syncEventGroupEdit()
            if not ok then return false, 'event group could not be synchronized' end
        end
        return save(state.activeGroupEdit and state.activeGroupEdit.mainChart or state.chart, name)
    end

    --- 将谱面编码为 JSON 字符串（拖入旧格式谱面时重写文件用）
    -- @treturn string JSON 字符串
    function ChartService:encodeJson()
        local source = state.activeGroupEdit and state.activeGroupEdit.mainChart or state.chart
        local snapshot = source
        if state.activeGroupEdit then
            snapshot = {}
            for key, value in pairs(source) do snapshot[key] = value end
            snapshot.event_groups = table.copy(source.event_groups)
        end
        if state.activeGroupEdit then
            local events = self:copyEditingGroupEvents()
            if not events then return nil end
            snapshot.event_groups[state.activeGroupEdit.name].event = events
        end
        return dkjson.encode(snapshot)
    end
end
