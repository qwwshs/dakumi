--[[
    模块名: redo
    描述: 撤销/重做管理模块
    作者: qwwshs
    依赖: object, chart, ChartService, event_type, fNote, fEvent, sidebar, input, eventBus

    实现了基于操作记录的撤销/重做系统。
    每次操作记录包含 add 和 del 两个分组，每个分组包含 note 和 event 两个列表。
    撤销时：将 add 的元素删除，将 del 的元素恢复。
    重做时：将 add 的元素恢复，将 del 的元素删除。

    谱面变更不直接来自服务层调用：ChartService 只经事件总栈广播 chart:* 领域事件，
    本模块在加载时订阅（见文件末尾），模块互不持有引用。
]]

local ChartService = require("src.services.chartService")
local Note = require("src.objects.Note")
local Event = require("src.objects.Event")
local eventBus = require("src.utils.eventBus")

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

--- 撤销操作栈（当前分支：初始状态 → 当前位置）
redo.revoke = {}

--- 重做操作栈（当前分支：当前位置 → 活跃子链末端；逆序存放，末位为下一步）
redo.redo = {}

--- 历史树：完整记录每一次分叉。
-- 节点 {id=, parent=, children={}, active_child=, operation=}；root 为初始状态（operation 为 nil）。
-- 撤销/重做只移动 current；被放弃的分支留在父节点的 children 上，不再像线性栈那样被丢弃。
redo.tree = {root = nil, current = nil}
redo.next_id = 0

--- 重置历史树（切换谱面或显式清空）
local function resetTree(owner)
    local root = {id = 0, parent = nil, children = {}, active_child = nil, operation = nil}
    owner.tree = {root = root, current = root}
    owner.next_id = 0
    owner.rev = (owner.rev or 0) + 1 -- 版本号：UI 据此判断树是否变化
    owner.revoke, owner.redo = {}, {}
end

--- 由树重建当前分支视图（revoke / redo）；树是唯一数据源
local function rebuildBranch(owner)
    local revoke = {}
    local path, node = {}, owner.tree.current
    while node and node.parent do
        path[#path + 1] = node
        node = node.parent
    end
    for i = #path, 1, -1 do revoke[#revoke + 1] = path[i].operation end

    local ahead, tip = {}, owner.tree.current
    while tip.active_child do
        tip = tip.active_child
        ahead[#ahead + 1] = tip.operation
    end
    local forward = {}
    for i = #ahead, 1, -1 do forward[#forward + 1] = ahead[i] end

    owner.rev = (owner.rev or 0) + 1
    owner.revoke, owner.redo = revoke, forward
end

resetTree(redo)

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
    if operation.fields_before and #operation.fields_before > 0 then return true end
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
-- 全程处于豁免期：回放本身的增删不写入撤销记录
-- @tparam table operation 操作记录 {add={note={}, event={}}, del={note={}, event={}},
--                                groups_before=?, groups_after=?,
--                                fields_before=?, fields_after=?}
-- @tparam boolean isUndo true 表示撤销（反转操作），false 表示重做（重放操作）
local function applyOperation(operation, isUndo)
    return ChartService:suspend(function()
        if operation.groups_before and operation.groups_after then
            ChartService:setEventGroups(isUndo and operation.groups_before or operation.groups_after)
        end
        -- 字段快照（offset/info/preference/track/bpm_list）
        ChartService:restoreFields(isUndo and operation.fields_before or operation.fields_after)
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
    end)
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

    -- 新操作挂在当前位置下并成为活跃子节点；此前的撤销链不再丢弃，作为兄弟分支留在树上
    local parent = self.tree.current
    self.next_id = self.next_id + 1
    local node = {
        id = self.next_id,
        parent = parent,
        children = {},
        active_child = nil,
        operation = revoke_tab,
    }
    parent.children[#parent.children + 1] = node
    parent.active_child = node
    self.tree.current = node
    rebuildBranch(self)
    return true
end

--- 清空当前谱面的历史。
function redo:clear()
    resetTree(self)
end

--- 挂起撤销栈（进入事件组编辑时由 chart:group_edit_begin 触发），组内编辑使用独立栈
function redo:suspend()
    self._suspended = {tree = self.tree, next_id = self.next_id}
    resetTree(self)
end

--- 恢复挂起的撤销栈并写入一条组编辑记录（退出事件组编辑时由 chart:group_edit_end 触发）
function redo:resume(operation, actionKey)
    if self._suspended then
        self.tree, self.next_id = self._suspended.tree, self._suspended.next_id
        self._suspended = nil
        rebuildBranch(self)
    end
    return self:writeRevoke(operation, nil, actionKey)
end

--- 按发生顺序读取全部仍可到达的记录；cursor 是当前所处的位置。
function redo:getHistory()
    local history = {}
    for _, operation in ipairs(self.revoke) do history[#history + 1] = operation end
    for i = #self.redo, 1, -1 do history[#history + 1] = self.redo[i] end
    return history, #self.revoke
end

--- 遍历整棵历史树（先序、非递归，避免深链爆栈）。
-- @treturn table 行列表，每行 {node=, depth=, status=, is_fork=, is_root=, operation=}
--   status: 'current' 当前位置 / 'applied' 当前分支上已完成 / 'undone' 当前分支上已撤销（可重做）
--           / 'branch' 其它分支（被撤销后放弃的内容，可点击切换过去）
function redo:getTreeView()
    local path_nodes = {}
    local walker = self.tree.current
    while walker do
        path_nodes[walker] = true
        walker = walker.parent
    end
    local ahead = {}
    walker = self.tree.current
    while walker and walker.active_child do
        walker = walker.active_child
        ahead[walker] = true
    end

    local rows = {}
    local stack = {{node = self.tree.root, depth = 0}}
    while #stack > 0 do
        local top = table.remove(stack)
        local node = top.node
        local status = 'branch'
        if node == self.tree.current then
            status = 'current'
        elseif path_nodes[node] then
            status = 'applied'
        elseif ahead[node] then
            status = 'undone'
        end
        rows[#rows + 1] = {
            node = node,
            depth = top.depth,
            status = status,
            is_fork = #node.children > 1,
            is_root = node == self.tree.root,
            operation = node.operation,
        }
        for i = #node.children, 1, -1 do
            stack[#stack + 1] = {node = node.children[i], depth = top.depth + 1}
        end
    end
    return rows
end

function redo:undo()
    leaveEditableSidebar()
    local node = self.tree.current -- leave 可能已提交待编辑内容，取最新位置
    if not (node and node.parent) then return false end
    local ok, err = pcall(applyOperation, node.operation, true)
    if not ok then
        -- 回放失败时保留记录（弹出后丢弃会让撤销栈凭空少一步）
        log('[redo] undo failed: ' .. tostring(err))
        return false
    end
    -- 记住来路：重做沿这条子链返回；同一父节点下的其它分支仍留在树上
    node.parent.active_child = node
    self.tree.current = node.parent
    rebuildBranch(self)
    return true
end

function redo:redoOne()
    leaveEditableSidebar()
    local node = self.tree.current -- leave 可能已提交待编辑内容，重做应沿新位置的活跃子节点前进
    local child = node and node.active_child
    if not child then return false end
    local ok, err = pcall(applyOperation, child.operation, false)
    if not ok then
        log('[redo] redo failed: ' .. tostring(err))
        return false
    end
    self.tree.current = child
    rebuildBranch(self)
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

--- 判断节点是否属于当前这棵历史树。
function redo:isNode(node)
    if type(node) ~= 'table' then return false end
    while node and node.parent do node = node.parent end
    return node == self.tree.root
end

--- 定位到任意节点（可跨分支）：先退回公共祖先，再沿目标路径的活跃子链前进。
-- @tparam table node getTreeView() 行里的 node
function redo:jumpToNode(node)
    if not self:isNode(node) then return false end

    -- 目标路径：根 → 目标节点
    local path = {}
    local walker = node
    while walker and walker.parent do
        path[#path + 1] = walker
        walker = walker.parent
    end
    for i = 1, math.floor(#path / 2) do
        path[i], path[#path - i + 1] = path[#path - i + 1], path[i]
    end
    local position = {}
    for i = 1, #path do position[path[i]] = i end

    -- 上升：退到目标路径上的最近节点（或根）
    local current = self.tree.current
    while current ~= self.tree.root and not position[current] do
        if not self:undo() then return false end
        current = self.tree.current
    end

    -- 下降：沿目标分支逐个前进（显式改写活跃子节点，跨分支切换即在此完成）
    for i = (position[current] or 0) + 1, #path do
        local child = path[i]
        child.parent.active_child = child
        if not self:redoOne() then return false end
    end
    return self.tree.current == node
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

-- 订阅事件总栈：谱面数据的增删、替换与组编辑均由 ChartService 广播，此处统一落撤销记录。
-- 订阅在模块加载时建立；redo 为内置插件不参与热卸载，故不经 PluginManager:unregister 清理。
eventBus:on('chart:replaced', function() redo:clear() end)
eventBus:on('chart:committed', function(operation, actionKey) redo:writeRevoke(operation, nil, actionKey) end)
eventBus:on('chart:group_edit_begin', function() redo:suspend() end)
eventBus:on('chart:group_edit_end', function(operation, actionKey) redo:resume(operation, actionKey) end)

-- 注册信息由 plugins/init.lua 读取；生命周期仍使用对象的冒号方法。
redo.plugin = {
    name = 'redo',
    version = '1.0.0',
    target = 'edit/play',
    layer = 90,
    export = 'redo', -- 保留编辑器现有对象引用
}

return redo
