--[[
    模块名: clipboard
    描述: 选区/剪贴板数据与纯变换（内部核心模块）。数据本体与增删/转换操作在此，
          框选、粘贴、预览绘制等交互由 plugins/ctrl.lua 承担；内部模块只依赖本模块，
          不反向依赖 ctrl 插件（依赖方向：插件 → 核心）。
    作者: qwwshs
    依赖: table (全局, isRequire 加载)
]]

local clipboard = {}

--- 默认的空剪贴板结构
clipboard.meta = {
    note = {},
    event = {},
    note_tracks = {},   -- 与 note 并行的轨道数组（框选时的实际轨道）
    event_tracks = {},  -- 与 event 并行的轨道数组
    note_tabidx = {},   -- 与 note 并行的标签页下标数组
    event_tabidx = {},  -- 与 event 并行的标签页下标数组
    type = "",   -- 操作类型: "copy" 或 "cut"
    pos = "",    -- 来源位置: "play" 或 "edit" 或 "tabs"
}

--- 当前剪贴板数据
clipboard.tab = table.copy(clipboard.meta)

--- 框选进行中的鼠标起始状态（框选矩形绘制与滚轮锚点使用）
clipboard.mouse_start_pos = { x = 0, y = 0, down = false }

--- 按 beat 排序剪贴板（保持轨道/标签页并行数组对齐）
-- @tparam string istype 类型 ("note" 或 "event")
local function sortCopy(istype)
    local items = clipboard.tab[istype]
    local tracks = clipboard.tab[istype .. '_tracks']
    local tabidx = clipboard.tab[istype .. '_tabidx']
    local order = {}
    for i = 1, #items do order[i] = i end
    table.sort(order, function(a, b) return items[a]:getBeatValue() < items[b]:getBeatValue() end)
    local nitems, ntracks, ntabidx = {}, {}, {}
    for i, idx in ipairs(order) do
        nitems[i] = items[idx]
        ntracks[i] = tracks[idx]
        ntabidx[i] = tabidx[idx]
    end
    clipboard.tab[istype] = nitems
    clipboard.tab[istype .. '_tracks'] = ntracks
    clipboard.tab[istype .. '_tabidx'] = ntabidx
end

--- 从剪贴板中移除指定元素
-- @tparam table item 要移除的元素
-- @tparam string istype 类型 ("note" 或 "event")
function clipboard:sub(item, istype)
    if istype ~= "note" and istype ~= "event" then return end
    for i, v in ipairs(self.tab[istype]) do
        if rawequal(self.tab[istype][i], item) then
            table.remove(self.tab[istype], i)
            table.remove(self.tab[istype .. '_tracks'], i)
            table.remove(self.tab[istype .. '_tabidx'], i)
            return
        end
    end
end

--- 向剪贴板添加元素（去重）
-- @tparam table item 要添加的元素
-- @tparam string istype 类型 ("note" 或 "event")
-- @tparam number|nil track 元素所在实际轨道
-- @tparam number|nil tabidx 元素所在标签页下标
function clipboard:add(item, istype, track, tabidx)
    if istype ~= "note" and istype ~= "event" then return end
    for i = 1, #self.tab[istype] do
        if rawequal(self.tab[istype][i], item) then
            return -- 已存在，不重复添加
        end
    end
    self.tab[istype][#self.tab[istype] + 1] = item
    self.tab[istype .. '_tracks'][#self.tab[istype .. '_tracks'] + 1] = track or 0
    self.tab[istype .. '_tabidx'][#self.tab[istype .. '_tabidx'] + 1] = tabidx or 1
    sortCopy(istype)
end

--- 检查元素是否在剪贴板中
-- @tparam table item 要检查的元素
-- @tparam string istype 类型 ("note" 或 "event")
-- @treturn boolean 是否存在
function clipboard:exist(item, istype)
    if istype ~= "note" and istype ~= "event" then return end
    for i = 1, #self.tab[istype] do
        if rawequal(self.tab[istype][i], item) then
            return true
        end
    end
    return false
end

--- 获取剪贴板数据
-- @treturn table 剪贴板数据
function clipboard:get()
    return self.tab
end

--- 多标签页收起为单标签页后，改用 demo 区域的跨轨道复制规则。
function clipboard:convertTabsToPlay()
    if self.tab.pos ~= 'tabs' then return end
    self.tab.pos = 'play'
    self.tab.note_tracks = {}
    self.tab.event_tracks = {}
    self.tab.note_tabidx = {}
    self.tab.event_tabidx = {}
end

return clipboard
