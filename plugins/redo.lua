--[[
    模块名: redo
    描述: 撤销/重做管理模块
    作者: qwwshs
    依赖: object, chart, ChartService, event_type, fNote, fEvent, sidebar, input

    实现了基于操作记录的撤销/重做系统。
    每次操作记录包含 add 和 del 两个分组，每个分组包含 note 和 event 两个列表。
    撤销时：将 add 的元素删除，将 del 的元素恢复。
    重做时：将 add 的元素恢复，将 del 的元素删除。
]]

local ChartService = require("src.services.chartService")
local Note = require("src.objects.Note")
local Event = require("src.objects.Event")

local redo = object:new('redo')

--- 深拷贝可能包含 Note/Event 对象的表
local function deepCopyWithNotes(tab)
    if tab._data then return tab:copy() end
    local result = {}
    for k, v in pairs(tab) do
        if type(v) == 'table' then
            if v._data then
                result[k] = v:copy()
            else
                result[k] = deepCopyWithNotes(v)
            end
        else
            result[k] = v
        end
    end
    return result
end

--- 撤销操作栈
redo.revoke = {}

--- 重做操作栈
redo.redo = {}

--- 计算一次操作影响的完整节拍范围（包括修改前和修改后的对象）。
local function getBeatRange(operation)
    local first, last
    local function include(item)
        local data = item._data or item
        for _, value in ipairs({data.beat, data.beat2}) do
            if type(value) == 'table' then
                local number = beat:get(value)
                if type(number) == 'number' then
                    first = first and math.min(first, number) or number
                    last = last and math.max(last, number) or number
                end
            end
        end
    end
    for _, change in ipairs({operation.add, operation.del}) do
        for _, kind in ipairs({'note', 'event'}) do
            for _, item in ipairs(change[kind] or {}) do include(item) end
        end
    end
    local before, after = operation.groups_before or {}, operation.groups_after or {}
    local names = {}
    for name in pairs(before) do names[name] = true end
    for name in pairs(after) do names[name] = true end
    for name in pairs(names) do
        if not table.eq(before[name], after[name]) then
            if before[name] then
                for _, item in ipairs(before[name].event or {}) do include(item) end
            end
            if after[name] then
                for _, item in ipairs(after[name].event or {}) do include(item) end
            end
        end
    end
    return first, last
end

local function hasItems(operation)
    if operation.groups_before and operation.groups_after and
        not table.eq(operation.groups_before, operation.groups_after) then return true end
    for _, change in ipairs({operation.add, operation.del}) do
        if #(change.note or {}) > 0 or #(change.event or {}) > 0 then return true end
    end
    return false
end

--- 从谱面删除元素列表（通过 ChartService 自动同步 extra_chart）
-- @tparam table list 要删除的元素列表
-- @tparam function deleteFunc 删除函数 (ChartService:deleteNote 或 ChartService:deleteEvent)
local function removeFromChart(list, deleteFunc)
    for _, item in ipairs(list) do
        deleteFunc(ChartService, item)
    end
end

--- 向谱面添加元素列表（通过 ChartService 自动同步 extra_chart）
-- @tparam table list 要添加的元素列表
-- @tparam function addFunc 添加函数 (ChartService:addNote 或 ChartService:addEvent)
local function addToChart(list, addFunc)
    for _, item in ipairs(list) do
        if item._data and type(item.copy) == "function" then
            addFunc(ChartService, item:copy())
        elseif item._data then
            -- Plain table with _data (from serialization), reconstruct as proper object
            local typeName = item._data.type or item.type
            local isEvent = table.find(event_type, typeName)
            if isEvent then
                addFunc(ChartService, Event.new(item._data))
            else
                addFunc(ChartService, Note.new(item._data))
            end
        else
            -- Legacy plain table format
            local typeName = item.type
            local isEvent = table.find(event_type, typeName)
            if isEvent then
                addFunc(ChartService, Event.new(item))
            else
                addFunc(ChartService, Note.new(item))
            end
        end
    end
end

--- 对 chart 执行批量操作（撤销或重做）
-- @tparam table operation 操作记录 {add={note={}, event={}}, del={note={}, event={}}}
-- @tparam boolean isUndo true 表示撤销（反转操作），false 表示重做（重放操作）
local function applyOperation(operation, isUndo)
    if operation.groups_before and operation.groups_after then
        ChartService:setEventGroups(isUndo and operation.groups_before or operation.groups_after)
    end
    if isUndo then
        -- 撤销：先删除 add 的，再恢复 del 的
        removeFromChart(operation.add.note, ChartService.deleteNote)
        removeFromChart(operation.add.event, ChartService.deleteEvent)
        addToChart(operation.del.note, ChartService.addNote)
        addToChart(operation.del.event, ChartService.addEvent)
    else
        -- 重做：先恢复 add 的，再删除 del 的
        addToChart(operation.add.note, ChartService.addNote)
        addToChart(operation.add.event, ChartService.addEvent)
        removeFromChart(operation.del.note, ChartService.deleteNote)
        removeFromChart(operation.del.event, ChartService.deleteEvent)
    end

    fNote:sort()
    fEvent:sort()
end

--- 先提交侧边栏中尚未离开的编辑，避免撤销时额外写入一条记录。
local function leaveEditableSidebar()
    if sidebar and sidebar.displayed_content ~= 'nil' and
        sidebar.displayed_content ~= 'operation history' then
        sidebar:to('nil')
    end
end

--- 写入撤销记录
-- @tparam table tab 操作数据，可以是：
--   1. 单个 Note/Event 对象（需配合 istype 参数）
--   2. 批量操作表 {add={note={}, event={}}, del={note={}, event={}}}
-- @tparam string istype 操作类型 ("add" 或 "del")，仅对单个元素有效
-- @tparam string actionKey 操作说明的 i18n 键，由写入方提交
function redo:writeRevoke(tab, istype, actionKey)
    local revoke_tab

    if tab._data and type(tab.copy) == "function" then
        -- 单个 Note 或 Event 对象，封装为标准操作格式
        revoke_tab = {
            add = { event = {}, note = {} },
            del = { event = {}, note = {} }
        }
        local typeName = tab:getType()
        local isEvt = table.find(event_type, typeName)
        if isEvt then
            if istype == 'add' then
                table.insert(revoke_tab.add.event, tab:copy())
            elseif istype == 'del' then
                table.insert(revoke_tab.del.event, tab:copy())
            end
        else
            if istype == 'add' then
                table.insert(revoke_tab.add.note, tab:copy())
            elseif istype == 'del' then
                table.insert(revoke_tab.del.note, tab:copy())
            end
        end
    elseif tab.type then
        -- 单个 event 元素（纯 table，兼容旧数据），封装为标准操作格式
        revoke_tab = {
            add = { event = {}, note = {} },
            del = { event = {}, note = {} }
        }
        local isEventType = table.find(event_type, tab.type)
        if isEventType then
            if istype == 'add' then
                table.insert(revoke_tab.add.event, table.copy(tab))
            elseif istype == 'del' then
                table.insert(revoke_tab.del.event, table.copy(tab))
            end
        end
    else
        -- 批量操作，直接深拷贝
        revoke_tab = deepCopyWithNotes and deepCopyWithNotes(tab) or table.copy(tab)
    end

    if not hasItems(revoke_tab) then return false end
    revoke_tab.action_key = actionKey or 'history.other'
    revoke_tab.beat_start, revoke_tab.beat_end = getBeatRange(revoke_tab)

    -- 新操作会清空重做栈
    self.redo = {}
    table.insert(self.revoke, revoke_tab)
    return true
end

--- 清空当前谱面的历史。
function redo:clear()
    self.revoke = {}
    self.redo = {}
end

--- 按发生顺序读取全部仍可到达的记录；cursor 是当前所处的位置。
function redo:getHistory()
    local history = {}
    for _, operation in ipairs(self.revoke) do history[#history + 1] = operation end
    for i = #self.redo, 1, -1 do history[#history + 1] = self.redo[i] end
    return history, #self.revoke
end

function redo:undo()
    leaveEditableSidebar()
    local operation = table.remove(self.revoke)
    if not operation then return false end
    applyOperation(operation, true)
    self.redo[#self.redo + 1] = operation
    return true
end

function redo:redoOne()
    if not self.redo[#self.redo] then return false end
    leaveEditableSidebar()
    local operation = table.remove(self.redo)
    if not operation then return false end
    applyOperation(operation, false)
    self.revoke[#self.revoke + 1] = operation
    return true
end

--- 跳到第 index 次操作之后；0 表示所有记录之前。
function redo:jumpTo(index)
    if type(index) ~= 'number' or index ~= math.floor(index) then return false end
    local total = #self.revoke + #self.redo
    if index < 0 or index > total then return false end
    while #self.revoke > index do
        if not self:undo() then return false end
    end
    while #self.revoke < index do
        if not self:redoOne() then return false end
    end
    return true
end

--- 键盘事件处理：执行撤销或重做
-- @tparam string key 按下的键名
function redo:keypressed(key)
    if input('undo') then
        self:undo()
    elseif input('redoing') then
        self:redoOne()
    end
end

-- 注册信息由 plugins/init.lua 读取；生命周期仍使用对象的冒号方法。
redo.plugin = {
    name = 'redo',
    version = '1.0.0',
    target = 'edit/play',
    layer = 90,
    export = 'redo', -- 保留编辑器现有对象引用
}

return redo
