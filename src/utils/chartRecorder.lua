--[[
    模块名: chartRecorder
    描述: 谱面变更强制记录器（撤销栈的守门人，叶子模块）。
          - 图谱面的实体 setter 经 beforeEntityChange 挂钩：自动快照旧值并累积进当前事务
          - 事务（txn）外的单次变更自动包一层单发事务，**不可自愿跳过记录**
          - 撤销/重做回放与内部定位舞步经 suspend 临时豁免（豁免期间不产生记录）
          - 成员注册表（inChart）记录哪些实体当前属于谱面，剥离副本（粘贴预览、
            Incoming 编辑副本等）的 setter 不会产生记录
    作者: qwwshs
    依赖: eventBus (require)；event_type 为运行时全局（meta 加载）
          gateway 由 ChartService 在模块尾部注入（事务提交需要读字段现值，见 commit）

    事务数据形态: {add={event={},note={}}, del={event={},note={}},
                   snap={实体=旧值副本}, fields_before={kind/key=...}}
    提交产生的操作记录: {add=..., del=..., fields_before={...}, fields_after={...}}
          与 redo:writeRevoke 的既有格式兼容，另增 fields_before/fields_after
          （{kind=, key=, value=} 列表，kind ∈ offset/info/preference/track/bpm_list）。
]]

local eventBus = require("src.utils.eventBus")

local recorder = {}

local txn = nil            -- 当前事务；nil 表示无事务
local suspendDepth = 0     -- 豁免深度（撤销回放 / 内部定位舞步）
local inChart = setmetatable({}, {__mode = 'k'})  -- 实体 -> true（当前属于谱面）

--- 构建操作记录（结构 + 实体内容快照对比）；字段部分由 ChartService 补充
local function buildOperation(t)
    local operation = {add = t.add, del = t.del, fields_before = {}, fields_after = {}}
    local function inList(list, e)
        for _, x in ipairs(list) do if rawequal(x, e) then return true end end
        return false
    end
    local function replaceInList(list, e, value)
        for i, x in ipairs(list) do
            if rawequal(x, e) then list[i] = value; return true end
        end
        return false
    end
    -- 事务内"添加后又删除"的实体：两清单相抵，不产生记录
    for _, kind in ipairs({'event', 'note'}) do
        for i = #t.add[kind], 1, -1 do
            if not inChart[t.add[kind][i]] then
                local removed = table.remove(t.add[kind], i)
                for j = #t.del[kind], 1, -1 do
                    if rawequal(t.del[kind][j], removed) then table.remove(t.del[kind], j); break end
                end
            end
        end
    end
    -- 实体内容变更：del 取事务前快照，add 取当前状态
    for e, old in pairs(t.snap) do
        local kind = table.find(event_type, e:getType()) and 'event' or 'note'
        if inChart[e] then
            if not inList(t.add[kind], e) and not old:eq(e) then
                table.insert(operation.del[kind], old)
                table.insert(operation.add[kind], e:copy())
            end
        else
            -- 修改后又被删除：del 记录应回退为事务前的旧状态
            if not inList(t.add[kind], e) then
                if not replaceInList(t.del[kind], e, old) then
                    table.insert(operation.del[kind], old)
                end
            end
        end
    end
    return operation
end

local function operationEmpty(operation)
    return #operation.add.event == 0 and #operation.add.note == 0 and
        #operation.del.event == 0 and #operation.del.note == 0 and
        #operation.fields_before == 0
end

-- ============================================================
-- 供 Note/Event setter 包装器调用的挂钩
-- ============================================================

--- 是否处于豁免期（撤销回放 / 内部舞步）
function recorder.suspended()
    return suspendDepth > 0
end

--- 实体当前是否属于谱面
function recorder.inChartEntity(e)
    return inChart[e] == true
end

--- 是否有打开中的事务
function recorder.hasTxn()
    return txn ~= nil
end

--- 当前事务数据（ChartService 提交时读取 fields_before）
function recorder.txn()
    return txn
end

--- 实体 setter 前调用：图谱面的对象快照旧值并纳入当前事务
function recorder.beforeEntityChange(e)
    if suspendDepth > 0 or not inChart[e] then return end
    if not txn then txn = {add = {event = {}, note = {}}, del = {event = {}, note = {}}, snap = {}, fields_before = {}} end
    txn.snap[e] = txn.snap[e] or e:copy()
end

--- 事务外的单次 setter 变更：自动包单发事务并立即提交（强制记录的核心）
function recorder.autoCommit(fn, e)
    if suspendDepth > 0 or not inChart[e] then return fn() end
    if txn then
        recorder.beforeEntityChange(e)
        return fn()
    end
    recorder.begin()
    recorder.beforeEntityChange(e)
    fn()
    recorder.commit()
end

-- ============================================================
-- 事务与豁免控制（ChartService / 手势层使用）
-- ============================================================

--- 打开事务（已打开则为无操作）
function recorder.begin()
    if not txn then
        txn = {add = {event = {}, note = {}}, del = {event = {}, note = {}}, snap = {}, fields_before = {}}
    end
end

--- 记录字段变更前的值（仅事务内有效；value 需调用方传副本或标量）
function recorder.touchField(kind, key, before)
    if not txn then return end
    local k = kind .. '/' .. tostring(key)
    if txn.fields_before[k] == nil then
        txn.fields_before[k] = {kind = kind, key = key, value = before}
    end
end

--- 结构变更入账（ChartService 低层增删调用）
function recorder.trackAdd(e) if txn then table.insert(txn.add[table.find(event_type, e:getType()) and 'event' or 'note'], e) end end
function recorder.trackDel(e) if txn then table.insert(txn.del[table.find(event_type, e:getType()) and 'event' or 'note'], e) end end

--- 提交当前事务：构建操作记录并经事件总栈广播 chart:committed（无实际变更则不广播）
-- actionKey 为手势说明的 i18n 键；fieldsAfter 由 ChartService 传入（读取字段现值），
-- 省略时视为无字段变更
function recorder.commit(actionKey, fieldsAfter)
    local t = txn
    if not t then return false end
    txn = nil
    local operation = buildOperation(t)
    if fieldsAfter then
        for _, entry in ipairs(fieldsAfter) do
            local before = t.fields_before[entry.kind .. '/' .. tostring(entry.key)]
            if before then
                local same = type(before.value) == 'table' and type(entry.value) == 'table' and
                    table.eq(before.value, entry.value) or before.value == entry.value
                if not same then
                    table.insert(operation.fields_before, before)
                    table.insert(operation.fields_after, entry)
                end
            end
        end
    end
    if operationEmpty(operation) then return false end
    eventBus:emit('chart:committed', operation, actionKey)
    return true
end

--- 丢弃当前事务（不产生记录）
function recorder.reset()
    txn = nil
end

--- 豁免区间（撤销回放 / 内部定位舞步）；fn 的返回值原样透传
function recorder.suspend(fn)
    suspendDepth = suspendDepth + 1
    local results = {fn()}
    suspendDepth = suspendDepth - 1
    return unpack(results, 1, #results)
end

-- ============================================================
-- 成员注册表维护（ChartService 结构变更时调用）
-- ============================================================

function recorder.markIn(e) if type(e) == 'table' then inChart[e] = true end end
function recorder.unmarkIn(e) inChart[e] = nil end
function recorder.clearIn() inChart = setmetatable({}, {__mode = 'k'}) end

return recorder
