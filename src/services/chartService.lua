--[[
    模块名: ChartService
    描述: 谱面数据服务层，chart 和 extra_chart 的唯一持有者
    作者: qwwshs
    依赖: meta_chart/event_type/meta_track/meta_extra_chart_track (全局, isRequire 加载),
          table/beat/save/dkjson (全局), fNote/fEvent/PluginManager (全局, 调用时存在),
          eventBus/chartRecorder (require)

    撤销强制记录（chartRecorder）:
    - 所有谱面变更必须发生在 recorder 事务内；事务外的低层增删/字段修改自动包单发事务，
      **调用方无法跳过撤销记录**（唯一豁免是撤销回放与内部定位舞步：recorder.suspend）
    - 实体内容变更经 Note/Event setter 拦截自动快照（旧值在事务内只取第一次）
    - 字段变更（offset/info/preference/track/bpm_list）经 touchField 记录前后值
    - change(actionKey, fn) 供手势层开显式事务（一个手势一条记录）

    设计原则:
    - chart 与 extra_chart 是本模块的私有状态（module-local），不再有全局变量
    - 不提供任何返回内部表引用的接口：读取走 计数+下标+字段访问器，
      Note/Event 对象本身按实体返回（getNote/getEvent 等，其字段修改走对象方法）
    - 所有对谱面数据的写入必须通过本服务的方法
    - extra_chart 是内部索引，完全不对外暴露
]]

local ChartService = {}
local Note = require("src.objects.Note")
local Event = require("src.objects.Event")
local eventBus = require("src.utils.eventBus")
local recorder = require("src.utils.chartRecorder")

local function emitMutation(change)
    if not recorder.suspended() then eventBus:emit('chart:mutated', change) end
end

local function valuesDiffer(a, b)
    if type(a) == 'table' and type(b) == 'table' then return not table.eq(a, b) end
    return a ~= b
end

-- ============================================================
-- 私有状态
-- ============================================================

--- 当前谱面数据（由 setChart / load 填充默认字段）
local chart = {}
local eventGroupsRevision = 0
local activeGroupEdit

--- 谱面索引：{ track = { [trackId] = { x={}, w={}, lpos={}, rpos={}, note={} } } }
local extra_chart = { track = {} }
local validGroupName

-- ============================================================
-- 撤销强制记录（变更事务）
-- ============================================================

--- 重建成员注册表（哪些实体当前属于谱面——setter 拦截据此决定是否记录）
local function rebuildRegistry()
    recorder.clearIn()
    for i = 1, #(chart.event or {}) do recorder.markIn(chart.event[i]) end
    for i = 1, #(chart.note or {}) do recorder.markIn(chart.note[i]) end
end

--- 读取字段现值（事务提交时与 fields_before 对比）
local function currentFieldValue(kind, key)
    if kind == 'offset' then return chart.offset or 0 end
    if kind == 'info' then return chart.info and chart.info[key] or nil end
    if kind == 'preference' then return chart.preference and chart.preference[key] or nil end
    if kind == 'track' then
        return chart.track and chart.track[tostring(key)] and table.copy(chart.track[tostring(key)]) or nil
    end
    if kind == 'bpm_list' then return chart.bpm_list and table.copy(chart.bpm_list) or nil end
end

--- 提交当前事务：补齐字段前后值后广播 chart:committed（无实际变更则不产生记录）
local function commitTxn(actionKey)
    local t = recorder.txn and recorder.txn() or nil
    if not t then return false end
    local fieldsAfter = {}
    for _, entry in pairs(t.fields_before) do
        fieldsAfter[#fieldsAfter + 1] = {kind = entry.kind, key = entry.key,
            value = currentFieldValue(entry.kind, entry.key)}
    end
    return recorder.commit(actionKey, fieldsAfter)
end

--- 在变更事务中执行 fn：无事务时自动开一个并在结束后提交（强制记录的统一入口）
-- 已有事务（手势批量 / push 批量）时 fn 直接执行，记录归入外层事务
-- @treturn any fn 的返回值原样透传
function ChartService:change(actionKey, fn)
    if recorder.suspended() then return fn() end
    local had = recorder.hasTxn()
    if not had then recorder.begin() end
    local results = {fn()}
    if not had then commitTxn(actionKey) end
    return unpack(results, 1, #results)
end

--- 打开/提交一个跨帧的事务（拖拽等无法用 change 包住的手势）
function ChartService:beginChange()
    recorder.begin()
end

--- 提交当前事务（通常与 beginChange 配对；由手势层提供 actionKey）
function ChartService:commitChange(actionKey)
    if recorder.suspended() then recorder.reset(); return false end
    return commitTxn(actionKey)
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
-- 内部辅助函数
-- ============================================================

--- 判断是否为事件类型
-- @tparam string typeName 类型名
-- @treturn boolean
local function isEventType(typeName)
    return table.find(event_type, typeName) ~= false
end

--- 判断是否为音符类型
-- @tparam string typeName 类型名
-- @treturn boolean
local function isNoteType(typeName)
    return typeName == 'note' or typeName == 'hold' or typeName == 'wipe'
end

--- 优先按对象引用查找，兼容原有按内容相等的调用。
local function findItemIndex(list, item)
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
local function ensureTrackIndex(trackId)
    if extra_chart.track[trackId] == nil then
        extra_chart.track[trackId] = table.copy(meta_extra_chart_track)
    end
end

--- 向 extra_chart 添加事件（内部方法）
-- @tparam Event event 事件对象
local function addEventToIndex(event)
    if type(event.getTrack) ~= "function" then return end
    local trackId = event:getTrack()
    local eventType = event:getType()
    ensureTrackIndex(trackId)
    table.insert(extra_chart.track[trackId][eventType], event)
end

--- 向 extra_chart 添加音符（内部方法）
-- @tparam Note note 音符对象
local function addNoteToIndex(note)
    if type(note.getTrack) ~= "function" then return end
    local trackId = note:getTrack()
    ensureTrackIndex(trackId)
    table.insert(extra_chart.track[trackId].note, note)
end

--- 从 extra_chart 删除事件（内部方法）
-- @tparam Event event 事件对象
local function removeEventFromIndex(event)
    local trackId = event:getTrack()
    local eventType = event:getType()
    if not extra_chart.track[trackId] then return end
    local list = extra_chart.track[trackId][eventType]
    if not list then return end
    local i = findItemIndex(list, event)
    if i then table.remove(list, i) end
end

--- 从 extra_chart 删除音符（内部方法）
-- @tparam Note note 音符对象
local function removeNoteFromIndex(note)
    local trackId = note:getTrack()
    if not extra_chart.track[trackId] then return end
    local list = extra_chart.track[trackId].note
    if not list then return end
    local i = findItemIndex(list, note)
    if i then table.remove(list, i) end
end

-- ============================================================
-- 谱面替换与生命周期
-- ============================================================

--- 替换整张谱面数据（菜单选谱/导入旧格式时调用）
-- 深拷贝数据并补齐默认字段，同时清空旧索引（由 load() 重建）
-- @tparam table data 谱面数据表
function ChartService:setChart(data)
    if activeGroupEdit then
        local groups = sidebar and sidebar:getGroup('event groups')
        local ok
        if groups then ok = groups:exitGroup(true) else ok = self:finishEventGroupEdit() end
        if not ok then return false end
    end
    chart = table.copy(data or {})
    table.fill(chart, meta_chart.__index)
    if type(chart.event_groups) ~= 'table' then chart.event_groups = {} end
    eventGroupsRevision = eventGroupsRevision + 1
    extra_chart = { track = {} }
    recorder.reset()
    rebuildRegistry()
    eventBus:emit('chart:replaced')
    eventBus:emit('chart:changed', {kind = 'replace'})
end

--- 更新谱面数据（版本迁移和字段填充）
-- 修复旧版本数据格式，填充缺失字段
function ChartService:update()
    -- 修复旧版本的 "form" 拼写错误（应为 "from"）
    local find_form = false
    for i = 1, #chart.event do
        if chart.event[i].form then
            chart.event[i].from = chart.event[i].form
            chart.event[i].form = nil
            find_form = true
        end
    end

    -- 为 note 填充 fake 字段（默认值 0）
    for i = 1, #chart.note do
        chart.note[i].fake = chart.note[i].fake or 0
    end

    -- 迁移 event 的 trans 数据格式
    -- 旧格式: trans = {0, 0, 1, 1}（数组）
    -- 新格式: trans = {trans = {0, 0, 1, 1}, type = "bezier", easings = 1}
    for i = 1, #chart.event do
        local trans = chart.event[i].trans
        if type(trans) ~= 'table' then
            trans = table.copy(meta_event.__index.trans)
            chart.event[i].trans = trans
        end
        if #trans > 0 then
            local trans_tab = {}
            for j = 1, #trans do
                trans_tab[j] = trans[j]
            end
            for j = 1, #trans do
                chart.event[i].trans[j] = nil
            end
            chart.event[i].trans.trans = trans_tab
        end
        trans.type = trans.type or 'bezier'
        trans.easings = trans.easings or 1
    end

    -- 组内事件使用与谱面事件相同的过渡数据格式。
    for name, groupData in pairs(chart.event_groups) do
        if not validGroupName(name) or type(groupData) ~= 'table' then
            chart.event_groups[name] = nil
        else
            groupData.name = name
            if type(groupData.event) ~= 'table' then groupData.event = {} end
            for index, inner in ipairs(groupData.event) do
                if type(inner) ~= 'table' then
                    groupData.event[index] = nil
                else
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
    for i = 1, #chart.note do
        if chart.note[i].type == 'hold' then
            chart.note[i].note_head = chart.note[i].note_head or 0
            chart.note[i].wipe_head = chart.note[i].wipe_head or 0
        end
    end

    -- 为 track 填充默认字段
    for i, v in pairs(chart.track) do
        table.fill(v, meta_track.__index)
    end

    -- 为 BPM 列表填充默认字段
    for i, v in pairs(chart.bpm_list) do
        table.fill(v, meta_bpm.__index)
    end
end

--- 加载谱面数据（构建 extra_chart 索引）
-- 先更新数据格式并保存，再转换为 Note/Event 对象，最后构建索引
function ChartService:load()
    if activeGroupEdit then
        local groups = sidebar and sidebar:getGroup('event groups')
        local ok
        if groups then ok = groups:exitGroup(true) else ok = self:finishEventGroupEdit() end
        if not ok then return false end
    end
    self:update()
    save(chart, 'chart.json')

    -- 将 note 纯 table 转为 Note 对象
    for i = 1, #chart.note do
        local n = chart.note[i]
        if type(n) ~= "table" or type(n.getTrack) ~= "function" then
            local data = type(n) == "table" and (n._data or n) or {}
            chart.note[i] = Note.new(data)
        end
    end

    -- 将 event 纯 table 转为 Event 对象
    for i = 1, #chart.event do
        local e = chart.event[i]
        if type(e) ~= "table" or type(e.getTrack) ~= "function" then
            local data = type(e) == "table" and (e._data or e) or {}
            chart.event[i] = Event.new(data)
        end
    end

    -- 重建 extra_chart 索引
    extra_chart = { track = {} }
    for i = 1, #chart.event do
        local e = chart.event[i]
        addEventToIndex(e)
    end
    for i = 1, #chart.note do
        local n = chart.note[i]
        addNoteToIndex(n)
    end
    eventBus:emit('chart:changed', {kind = 'load'})
    return true
end

--- 序列化保存谱面（内部把私有 chart 交给 save 处理）
-- @tparam string name 保存文件名（"chart.json" / "chart.json.auto" / 其它路径）
function ChartService:save(name)
    if activeGroupEdit then
        local ok = self:syncEventGroupEdit()
        if not ok then return false end
    end
    save(activeGroupEdit and activeGroupEdit.mainChart or chart, name)
    return true
end

--- 将谱面编码为 JSON 字符串（拖入旧格式谱面时重写文件用）
-- @treturn string JSON 字符串
function ChartService:encodeJson()
    if activeGroupEdit then
        local ok = self:syncEventGroupEdit()
        if not ok then return nil end
    end
    return dkjson.encode(activeGroupEdit and activeGroupEdit.mainChart or chart)
end

-- 事件组名称直接作为 JSON 字典键使用，不参与代码执行。
validGroupName = function(name)
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
        not finiteNumber(value.from) or not finiteNumber(value.to) then return false end
    local trans = value.trans
    if type(trans) ~= 'table' or (trans.type ~= 'bezier' and trans.type ~= 'easings') then return false end
    if trans.type == 'bezier' then
        if type(trans.trans) ~= 'table' or #trans.trans ~= 4 then return false end
        for _, point in ipairs(trans.trans) do if not finiteNumber(point) then return false end end
    elseif not finiteNumber(trans.easings) or trans.easings < 1 or
        trans.easings > #easings or trans.easings % 1 ~= 0 then return false end
    return true
end

local function groupChart()
    return activeGroupEdit and activeGroupEdit.mainChart or chart
end

function ChartService:isEditingEventGroup()
    return activeGroupEdit and activeGroupEdit.name or nil
end

-- 编辑时临时切换到只含组内事件的一条轨道。原谱面与索引原样保留。
function ChartService:beginEventGroupEdit(name)
    if activeGroupEdit then return false end
    local definition = chart.event_groups and chart.event_groups[name]
    if not definition then return false end
    local events = {}
    for _, data in ipairs(definition.event or {}) do
        if not validInnerEvent(data) then return false end
        local copy = table.copy(data)
        copy.track = 1
        events[#events + 1] = Event.new(copy)
    end
    activeGroupEdit = {
        name = name, mainChart = chart, mainIndex = extra_chart,
        before = table.copy(chart.event_groups),
    }
    local editTrack = table.copy(meta_track.__index)
    editTrack.w0thenShow = 1
    chart = {
        event = events, note = {}, effect = {}, event_groups = {},
        bpm_list = table.copy(activeGroupEdit.mainChart.bpm_list),
        preference = table.copy(activeGroupEdit.mainChart.preference),
        info = table.copy(activeGroupEdit.mainChart.info),
        offset = activeGroupEdit.mainChart.offset,
        track = {['1'] = editTrack},
    }
    extra_chart = {track = {}}
    for _, event in ipairs(events) do addEventToIndex(event) end
    self:sortEvents()
    recorder.reset()
    rebuildRegistry()
    -- 通知订阅方挂起自身状态（如撤销栈），组内编辑使用独立状态
    eventBus:emit('chart:group_edit_begin')
    eventBus:emit('chart:changed', {kind = 'group_edit_begin', group = name})
    eventGroupsRevision = eventGroupsRevision + 1
    return true
end

-- 自动保存和手动保存都从当前编辑轨道同步到原谱面。
function ChartService:syncEventGroupEdit()
    local session = activeGroupEdit
    if not session then return true end
    local events = {}
    for _, event in ipairs(chart.event) do
        local value = event:toTable()
        local data = {
            type = value.type, beat = table.copy(value.beat), beat2 = table.copy(value.beat2),
            from = value.from, to = value.to, trans = table.copy(value.trans),
        }
        if not validInnerEvent(data) then return false end
        data.track = nil
        events[#events + 1] = data
    end
    local definition = session.mainChart.event_groups[session.name]
    if not definition then return false end
    if not table.eq(definition.event, events) then
        local before = table.copy(session.mainChart.event_groups)
        definition.event = events
        eventGroupsRevision = eventGroupsRevision + 1
        emitMutation({kind = 'group_updated', group = session.name,
            before = before[session.name], after = table.copy(definition)})
        eventBus:emit('chart:changed', {kind = 'group_sync', group = session.name,
            operation = {add = {event = {}, note = {}}, del = {event = {}, note = {}},
                groups_before = before, groups_after = table.copy(session.mainChart.event_groups)}})
    end
    return true
end

function ChartService:finishEventGroupEdit()
    local session = activeGroupEdit
    if not session then return true end
    local ok = self:syncEventGroupEdit()
    if not ok then return false end
    chart, extra_chart = session.mainChart, session.mainIndex
    activeGroupEdit = nil
    recorder.reset()
    rebuildRegistry()
    -- 通知订阅方恢复挂起的状态，并带上组定义变更供撤销记录
    local operation = {
        add = {event = {}, note = {}}, del = {event = {}, note = {}},
        groups_before = session.before, groups_after = table.copy(chart.event_groups),
    }
    eventBus:emit('chart:group_edit_end', operation, 'history.edit_event_group')
    eventBus:emit('chart:changed', {kind = 'group_edit_end', group = session.name,
        operation = operation, actionKey = 'history.edit_event_group'})
    eventGroupsRevision = eventGroupsRevision + 1
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
    return eventGroupsRevision
end

-- 仅供撤销/重做恢复整份组定义，调用者不能取得内部表引用。
function ChartService:copyEventGroups()
    return table.copy(groupChart().event_groups or {})
end
function ChartService:setEventGroups(value)
    if activeGroupEdit then return false end
    local nextGroups = table.copy(value or {})
    if table.eq(chart.event_groups, nextGroups) then return false end
    chart.event_groups = nextGroups
    eventGroupsRevision = eventGroupsRevision + 1
    if not recorder.suspended() then
        emitMutation({kind = 'group_definitions_updated'})
        eventBus:emit('chart:changed', {kind = 'group_definitions'})
    end
    return true
end

-- 一个操作提交一个组定义；改名时同步更新谱面中的所有引用。
function ChartService:putEventGroup(name, value, oldName, actionKey)
    if activeGroupEdit then return false, 'finish editing first' end
    if not validGroupName(name) or type(value) ~= 'table' or type(value.event) ~= 'table' then
        return false, 'invalid name or event list'
    end
    oldName = oldName or name
    if oldName ~= name and chart.event_groups[name] then return false, 'name already exists' end
    for _, inner in ipairs(value.event) do
        if not validInnerEvent(inner) then return false, 'invalid event' end
    end
    if oldName == name and table.eq(chart.event_groups[name],
        {name = name, event = value.event}) then return true end
    local before = self:copyEventGroups()
    local oldRefs, newRefs = {}, {}
    if oldName ~= name then
        self:suspend(function()
            for _, e in ipairs(chart.event) do
                if e:getType() == 'event_group' and e:getEventGroup() == oldName then
                    oldRefs[#oldRefs + 1] = e:copy()
                    e:setEventGroup(name)
                    newRefs[#newRefs + 1] = e:copy()
                end
            end
        end)
        chart.event_groups[oldName] = nil
    end
    chart.event_groups[name] = {name = name, event = table.copy(value.event)}
    eventGroupsRevision = eventGroupsRevision + 1
    emitMutation({kind = 'group_updated', group = name, before = before[oldName],
        after = table.copy(chart.event_groups[name])})
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
    if activeGroupEdit then return false end
    if not chart.event_groups[name] then return false end
    local before = self:copyEventGroups()
    chart.event_groups[name] = nil
    eventGroupsRevision = eventGroupsRevision + 1
    emitMutation({kind = 'group_deleted', group = name, before = before[name]})
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
    if activeGroupEdit and kind == 'event_group' then return false end
    local from, to = candidate:getBeatValue(), candidate:getBeat2Value()
    if not finiteNumber(from) or not finiteNumber(to) or to <= from then return false end
    local function conflicts(existing)
        if rawequal(existing, ignored) or (type(ignored) == 'table' and ignored[existing]) or
            rawequal(existing, candidate) or
            existing:getTrack() ~= candidate:getTrack() then return false end
        if kind ~= 'event_group' and existing:getType() ~= 'event_group' then return false end
        return from < existing:getBeat2Value() and to > existing:getBeatValue()
    end
    for _, existing in ipairs(chart.event) do
        if conflicts(existing) then return false end
    end
    return true
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
    fNote:sort()
    fEvent:sort()
    commitTxn(actionKey)
end

-- ============================================================
-- 增删操作（同步 chart 与 extra_chart）
-- ============================================================

--- 添加音符到谱面（自动同步索引；强制入撤销事务）
-- @tparam Note note 音符对象
-- @tparam string|nil actionKey 事务外调用时的记录说明键
function ChartService:addNote(note, actionKey)
    if activeGroupEdit then return false end
    return self:change(actionKey, function()
        table.insert(chart.note, note)
        addNoteToIndex(note)
        recorder.markIn(note)
        recorder.trackAdd(note)
        emitMutation({kind = 'note_added', entity = note})
    end)
end

--- 从谱面删除音符（自动同步索引；强制入撤销事务）
-- @tparam Note note 音符对象
-- @tparam string|nil actionKey 事务外调用时的记录说明键
-- @treturn boolean 是否删除成功
function ChartService:deleteNote(note, actionKey)
    if activeGroupEdit then return false end
    return self:change(actionKey, function()
        local i = findItemIndex(chart.note, note)
        if not i then return false end
        local actual = chart.note[i]
        table.remove(chart.note, i)
        removeNoteFromIndex(actual)
        recorder.unmarkIn(actual)
        recorder.trackDel(actual)
        emitMutation({kind = 'note_deleted', entity = actual})
        return true
    end)
end

--- 添加事件到谱面（自动同步索引；强制入撤销事务）
-- @tparam Event event 事件对象
-- @tparam string|nil actionKey 事务外调用时的记录说明键
function ChartService:addEvent(event, actionKey)
    return self:change(actionKey, function()
        table.insert(chart.event, event)
        addEventToIndex(event)
        recorder.markIn(event)
        recorder.trackAdd(event)
        emitMutation({kind = 'event_added', entity = event})
    end)
end

--- 从谱面删除事件（自动同步索引；强制入撤销事务）
-- @tparam Event event 事件对象
-- @tparam string|nil actionKey 事务外调用时的记录说明键
-- @treturn boolean 是否删除成功
function ChartService:deleteEvent(event, actionKey)
    return self:change(actionKey, function()
        local i = findItemIndex(chart.event, event)
        if not i then return false end
        local actual = chart.event[i]
        table.remove(chart.event, i)
        removeEventFromIndex(actual)
        recorder.unmarkIn(actual)
        recorder.trackDel(actual)
        emitMutation({kind = 'event_deleted', entity = actual})
        return true
    end)
end

--- 添加 note 或 event 到谱面（强制入撤销事务）
-- @tparam Note|Event noteorevent 要添加的音符或事件数据
-- @tparam string|nil actionKey 记录说明键
function ChartService:add(noteorevent, actionKey)
    local typeName = noteorevent.type or (noteorevent._data and noteorevent:getType())
    local isEvent = isEventType(typeName)
    local isNote = isNoteType(typeName)
    if activeGroupEdit and isNote then return false end

    if not isEvent and not isNote then
        return -- 未知类型，忽略
    end

    local result
    if isEvent then
        if not self:canPlaceEvent(noteorevent) then return false, 'event group overlap' end
        result = self:change(actionKey, function()
            local added = self:addEvent(noteorevent)
            fEvent:sort()
            return added
        end)
    else
        result = self:change(actionKey, function()
            local added = self:addNote(noteorevent)
            fNote:sort()
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
    local isEvent = isEventType(typeName)
    local isNote = isNoteType(typeName)
    if activeGroupEdit and isNote then return false end

    if not isEvent and not isNote then
        return -- 未知类型，忽略
    end

    local result
    if isEvent then
        local i = findItemIndex(chart.event, noteorevent)
        if i then result = self:deleteEvent(chart.event[i], actionKey) end
    else
        local i = findItemIndex(chart.note, noteorevent)
        if i then result = self:deleteNote(chart.note[i], actionKey) end
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

-- ============================================================
-- 列表读取（计数 + 下标，不返回内部表引用）
-- ============================================================

--- 获取音符数量
-- @treturn number 音符数
function ChartService:getNoteCount()
    return chart.note and #chart.note or 0
end

--- 获取指定下标的音符对象（实体，字段修改走 Note 方法）
-- @tparam number i 下标（1 起）
-- @treturn Note|nil 音符对象
function ChartService:getNote(i)
    return chart.note and chart.note[i] or nil
end

--- 获取事件数量
-- @treturn number 事件数
function ChartService:getEventCount()
    return chart.event and #chart.event or 0
end

--- 获取指定下标的事件对象（实体，字段修改走 Event 方法）
-- @tparam number i 下标（1 起）
-- @treturn Event|nil 事件对象
function ChartService:getEvent(i)
    return chart.event and chart.event[i] or nil
end

--- 获取 BPM 列表数量
-- @treturn number BPM 数
function ChartService:getBpmCount()
    return chart.bpm_list and #chart.bpm_list or 0
end

--- 获取指定下标的 BPM 条目
-- @tparam number i 下标（1 起）
-- @treturn table|nil BPM 条目 {beat={...}, bpm=..., linear_ramp=...}
function ChartService:getBpm(i)
    return chart.bpm_list and chart.bpm_list[i] and table.copy(chart.bpm_list[i]) or nil
end

--- 获取效果数量
-- @treturn number 效果数
function ChartService:getEffectCount()
    return chart.effect and #chart.effect or 0
end

--- 获取指定下标的效果条目
-- 注意：效果条目是普通表（非对象），当前全项目仅 play.lua 只读遍历，无写入路径
-- @tparam number i 下标（1 起）
-- @treturn table|nil 效果条目
function ChartService:getEffect(i)
    return chart.effect and chart.effect[i] and table.copy(chart.effect[i]) or nil
end

-- ============================================================
-- extra_chart 索引查询（只读，不返回内部列表）
-- ============================================================

--- 检查指定轨道是否存在于索引中
-- @tparam number trackId 轨道ID
-- @treturn boolean 是否存在
function ChartService:hasTrack(trackId)
    return extra_chart.track[trackId] ~= nil
end

--- 检查谱面里是否已存在该轨道定义
-- 与 hasTrack 的区别：hasTrack 查 extra_chart 索引（有事件才有条目），本函数查 chart.track 本体
-- @tparam number trackId 轨道ID
-- @treturn boolean 是否存在
function ChartService:hasTrackData(trackId)
    return chart.track ~= nil and chart.track[tostring(trackId)] ~= nil
end

--- 获取指定轨道指定类型的事件数量
-- @tparam number trackId 轨道ID
-- @tparam string eventType 事件类型 ("x", "w", "lpos", "rpos")
-- @treturn number 事件数
function ChartService:getTrackEventCount(trackId, eventType)
    local trackData = extra_chart.track[trackId]
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
    local trackData = extra_chart.track[trackId]
    if not trackData then return nil end
    local list = trackData[eventType]
    return list and list[i] or nil
end

-- ============================================================
-- 标量字段读取与写入
-- ============================================================

--- 获取音频偏移量
-- @treturn number 偏移量（毫秒）
function ChartService:getOffset()
    return chart.offset or 0
end

--- 设置音频偏移量
-- @tparam number v 偏移量（毫秒）
function ChartService:setOffset(v)
    self:change(nil, function()
        local before = chart.offset or 0
        recorder.touchField('offset', nil, before)
        chart.offset = v
        if valuesDiffer(before, v) then
            emitMutation({kind = 'field_updated', field = 'offset', before = before, after = v})
        end
    end)
end

--- 获取谱面信息字段（song_name / chart_name / chartor / artist）
-- @tparam string field 字段名
-- @treturn string|nil 字段值
function ChartService:getInfoField(field)
    return chart.info and chart.info[field] or nil
end

--- 设置谱面信息字段（song_name / chart_name / chartor / artist）
-- @tparam string field 字段名
-- @tparam any v 字段值
function ChartService:setInfoField(field, v)
    self:change(nil, function()
        local before = chart.info and chart.info[field] or nil
        recorder.touchField('info', field, before)
        chart.info[field] = v
        if valuesDiffer(before, v) then
            emitMutation({kind = 'field_updated', field = 'info', key = field,
                before = before, after = v})
        end
    end)
end

--- 获取偏好字段（x_offset / event_scale）
-- @tparam string field 字段名
-- @treturn number|nil 字段值
function ChartService:getPreferenceField(field)
    return chart.preference and chart.preference[field] or nil
end

--- 设置偏好字段（x_offset / event_scale）
-- @tparam string field 字段名
-- @tparam number v 字段值
function ChartService:setPreferenceField(field, v)
    self:change(nil, function()
        local cur = chart.preference and chart.preference[field] or nil
        recorder.touchField('preference', field, type(cur) == 'table' and table.copy(cur) or cur)
        chart.preference[field] = v
        if valuesDiffer(cur, v) then
            emitMutation({kind = 'field_updated', field = 'preference', key = field,
                before = cur, after = v})
        end
    end)
end

--- 整体替换 BPM 列表（chart_info 界面保存时使用）
-- @tparam table list 新的 BPM 列表
function ChartService:setBpmList(list)
    self:change(nil, function()
        local before = chart.bpm_list and table.copy(chart.bpm_list) or nil
        recorder.touchField('bpm_list', nil, before)
        chart.bpm_list = list and table.copy(list) or nil
        if valuesDiffer(before, chart.bpm_list) then
            emitMutation({kind = 'field_updated', field = 'bpm_list',
                before = before, after = chart.bpm_list and table.copy(chart.bpm_list) or nil})
        end
    end)
end

-- ============================================================
-- 轨道定义（chart.track，懒创建）
-- ============================================================

--- 确保轨道定义存在（不存在则创建默认定义）
-- @tparam number trackId 轨道ID
function ChartService:ensureTrack(trackId)
    if not chart.track[tostring(trackId)] then
        chart.track[tostring(trackId)] = table.copy(meta_track.__index)
        emitMutation({kind = 'track_created', field = 'track', key = trackId,
            after = table.copy(chart.track[tostring(trackId)])})
        if not recorder.hasTxn() and not recorder.suspended() then
            eventBus:emit('chart:changed', {kind = 'track_created', track = trackId})
        end
    end
end

--- 获取轨道定义字段（name / w0thenShow / type / parent / scale_with_parent）
-- @tparam number trackId 轨道ID
-- @tparam string field 字段名
-- @treturn any 字段值
function ChartService:getTrackField(trackId, field)
    self:ensureTrack(trackId)
    return chart.track[tostring(trackId)][field]
end

--- 设置轨道定义字段（name / w0thenShow / type / parent / scale_with_parent / zindex / left_boundary / right_boundary / boundary_type）
-- @tparam number trackId 轨道ID
-- @tparam string field 字段名
-- @tparam any v 字段值
function ChartService:setTrackField(trackId, field, v)
    self:change(nil, function()
        self:ensureTrack(trackId)
        local before = table.copy(chart.track[tostring(trackId)])
        recorder.touchField('track', trackId, before)
        chart.track[tostring(trackId)][field] = v
        if valuesDiffer(before, chart.track[tostring(trackId)]) then
            emitMutation({kind = 'field_updated', field = 'track', key = trackId,
                before = before, after = table.copy(chart.track[tostring(trackId)]), method = field})
        end
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
            chart.offset = value
        elseif kind == 'info' then
            chart.info[key] = detach(value)
        elseif kind == 'preference' then
            chart.preference[key] = detach(value)
        elseif kind == 'track' then
            if value then
                self:ensureTrack(key)
                chart.track[tostring(key)] = detach(value)
            else
                chart.track[tostring(key)] = nil
            end
        elseif kind == 'bpm_list' then
            chart.bpm_list = detach(value)
            if chart.bpm_list then self:sortBpmList() end
        end
    end
end

-- ============================================================
-- beat 桥接（内部把 chart.bpm_list 喂给 beat 模块）
-- ============================================================

--- 将时间转换为 beat 值（基于当前谱面 BPM 列表）
-- @tparam number nowtime 时间（秒）
-- @treturn number beat 值
function ChartService:toBeat(nowtime)
    return beat:toBeat(chart.bpm_list or {}, nowtime)
end

--- 将 beat 值转换为时间（基于当前谱面 BPM 列表）
-- @tparam number|table isbeat beat 值
-- @treturn number 时间（秒）
function ChartService:toTime(isbeat)
    return beat:toTime(chart.bpm_list or {}, isbeat)
end

-- ============================================================
-- 排序（同步排序 chart 和 extra_chart）
-- ============================================================

--- 对 BPM 列表按 beat 位置排序
function ChartService:sortBpmList()
    local bpmlist = {}
    while #chart.bpm_list > 0 do
        local bpm_beat_min = 1
        for i = 1, #chart.bpm_list do
            if beat:get(chart.bpm_list[i].beat) < beat:get(chart.bpm_list[bpm_beat_min].beat) then
                bpm_beat_min = i
            end
        end
        bpmlist[#bpmlist + 1] = chart.bpm_list[bpm_beat_min]
        table.remove(chart.bpm_list, bpm_beat_min)
    end
    for i = 1, #bpmlist do
        chart.bpm_list[i] = bpmlist[i]
    end
    beat.allbeat = beat:toBeat(chart.bpm_list, time.alltime)
end

--- 对事件列表排序（按 beat 升序，同步排序 chart 和 extra_chart）
function ChartService:sortEvents()
    table.sort(chart.event, function(a, b) return a:getBeatValue() < b:getBeatValue() end)
    for _, trackData in pairs(extra_chart.track) do
        for _, eventType in ipairs(event_type) do
            if trackData[eventType] then
                table.sort(trackData[eventType], function(a, b) return a:getBeatValue() < b:getBeatValue() end)
            end
        end
    end
end

--- 对音符列表排序（按 beat 升序，同步排序 chart 和 extra_chart）
function ChartService:sortNotes()
    table.sort(chart.note, function(a, b) return a:getBeatValue() < b:getBeatValue() end)
    for _, trackData in pairs(extra_chart.track) do
        table.sort(trackData.note, function(a, b) return a:getBeatValue() < b:getBeatValue() end)
    end
end

return ChartService
