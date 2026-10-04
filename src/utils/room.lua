--[[
    模块名: room
    描述: object/container/group/room 对象系统，子对象、子组和活动房间统一按层分发
    作者: qwwshs
    层号从小到大执行；同层按导入顺序执行。省略层号表示最高层（math.huge）。
    层属于父容器中的挂载关系，同一个对象在不同容器中可以拥有不同层。
]]
local room
local object = {}
function object:new(name)
    return setmetatable({__name = type(name) == 'string' and name or '', __type = ''}, object)
end

local container = object:new('')
container.__index = container
container.TOP_LAYER = math.huge
local function initContainer(value)
    value.objects, value.groups, value.layers = {}, {}, {}
    value._entries, value._sequence = {}, 0
    value._ordered = false
    return value
end
initContainer(container)
function container:new(name)
    if type(name) ~= 'string' then return end
    return setmetatable(initContainer(object:new(name)), container)
end

local function checkLayer(layer)
    layer = layer == nil and container.TOP_LAYER or layer
    assert(type(layer) == 'number' and layer == layer and layer ~= -math.huge,
        'layer must be a number (nil means the highest layer)')
    return layer
end
local function attach(self, child, kind, layer)
    if type(child) ~= 'table' then return false end
    layer = checkLayer(layer)
    -- 同一容器不重复挂载同一个对象，避免生命周期执行两次。
    for _, entry in ipairs(self._entries) do
        if rawequal(entry.child, child) then return false end
    end
    self._sequence = self._sequence + 1
    local entry = {child = child, kind = kind, layer = layer, order = self._sequence, alive = true}
    self._entries[#self._entries + 1] = entry
    self.layers[layer] = self.layers[layer] or {}
    table.insert(self.layers[layer], entry)
    self._ordered = false
    return true
end
local function removeLayerEntry(self, entry)
    local entries = self.layers[entry.layer]
    for i, value in ipairs(entries) do
        if value == entry then table.remove(entries, i); break end
    end
    if #entries == 0 then self.layers[entry.layer] = nil end
end
local function detach(self, child)
    for i, entry in ipairs(self._entries) do
        if rawequal(entry.child, child) then
            entry.alive = false
            removeLayerEntry(self, entry)
            table.remove(self._entries, i)
            self._ordered = false
            return true
        end
    end
    return false
end
function container:addObject(child, layer)
    if not attach(self, child, 'object', layer) then return false end
    table.insert(self.objects, child)
    return true
end
function container:addGroup(child, layer)
    if not attach(self, child, 'group', layer) then return false end
    table.insert(self.groups, child)
    return true
end
local function deleteFrom(self, list, childOrName)
    for i, child in ipairs(list) do
        if rawequal(child, childOrName) or child.__name == childOrName then
            detach(self, child)
            table.remove(list, i)
            return true
        end
    end
    return false
end
function container:deleteObject(childOrName) return deleteFrom(self, self.objects, childOrName) end
function container:deleteGroup(childOrName) return deleteFrom(self, self.groups, childOrName) end
local function findByName(list, name)
    for _, child in ipairs(list) do
        if child.__name == name then return child end
    end
end
function container:getObject(name) return findByName(self.objects, name) end
function container:getGroup(name) return findByName(self.groups, name) end
function container:getAllObject() return self.objects end
function container:getAllGroup() return self.groups end
local function findByType(list, kind)
    local result = {}
    for _, child in ipairs(list) do
        if child.__type == kind then result[#result + 1] = child end
    end
    return result
end
function container:getAllTypeObject(kind) return findByType(self.objects, kind) end
function container:getAllTypeGroup(kind) return findByType(self.groups, kind) end

-- 修改已经挂载的子对象、子组或子房间的层；省略 layer 则移到最高层。
function container:setLayer(child, layer)
    layer = checkLayer(layer)
    for _, entry in ipairs(self._entries) do
        if rawequal(entry.child, child) then
            removeLayerEntry(self, entry)
            entry.layer = layer
            self.layers[layer] = self.layers[layer] or {}
            table.insert(self.layers[layer], entry)
            self._ordered = false
            return true
        end
    end
    return false
end
function container:getLayer(child)
    for _, entry in ipairs(self._entries) do
        if rawequal(entry.child, child) then return entry.layer end
    end
end
local function orderedEntries(self)
    if not self._ordered then
        local entries = {}
        for i, entry in ipairs(self._entries) do entries[i] = entry end
        table.sort(entries, function(a, b)
            if a.layer == b.layer then return a.order < b.order end
            return a.layer < b.layer
        end)
        self._ordered = entries
    end
    return self._ordered
end
-- 自定义方法决定转发时机，保留场景的范围/显示状态判断；没有方法的容器自动向内转发。
local function invoke(child, method, ...)
    if type(child[method]) == 'function' then
        if method == 'load' and room and child.load == room.load then
            child('load', ...)
        else
            child[method](child, ...)
        end
    elseif child._entries then
        child(method, ...)
    end
end
function container:callChildren(method, kind, ...)
    local entries = orderedEntries(self)
    local active = self.__type
    for _, entry in ipairs(entries) do
        -- 顺序快照：新增项下次执行，已删除项当次立即跳过。
        if entry.alive and (not kind or entry.kind == kind) and
            (entry.kind ~= 'room' or entry.child.__name == active) then
            invoke(entry.child, method, ...)
        end
    end
end
function container:callAllObject(method, ...) self:callChildren(method, 'object', ...) end
function container:callAllGroup(method, ...) self:callChildren(method, 'group', ...) end
function container:__call(method, ...) self:callChildren(method, nil, ...) end

local group = container:new('')
group.__index = group
group.__call = container.__call
function group:new(name)
    return setmetatable(initContainer(object:new(name)), group)
end
room = container:new('main')
room.rooms = {}
room.__index = room
room.__call = container.__call
function room:new(name)
    if type(name) ~= 'string' then return end
    local value = container:new(name)
    value.rooms = {}
    return setmetatable(value, room)
end
function room:load(name)
    if name then self.__type = name end
end
function room:addRoom(child, layer)
    if type(child) ~= 'table' or type(child.__name) ~= 'string' then return false end
    if self.rooms[child.__name] then return false end
    if not attach(self, child, 'room', layer) then return false end
    self.rooms[child.__name] = child
    return true
end
function room:deleteRoom(childOrName)
    local name = type(childOrName) == 'table' and childOrName.__name or childOrName
    local child = self.rooms[name]
    if not child then return false end
    detach(self, child)
    self.rooms[name] = nil
    return true
end
function room:getRoom(name) return self.rooms[name] end
function room:to(name, ...)
    local child = self.rooms[name]
    if not child then return end
    invoke(child, 'load', ...)
    self.__type = name
end
-- 用 main/edit/play 或 edit/play 定位任意嵌套 room/group。
function container:findContainer(path)
    if type(path) ~= 'string' or path == '' then return nil end
    local current, first = self, true
    for name in path:gmatch('[^/]+') do
        if not (first and name == self.__name) then
            current = (current.rooms and current.rooms[name]) or current:getGroup(name)
            if not current then return nil end
        end
        first = false
    end
    return current
end

-- 系统内部使用局部引用。仅在兼容边界提供旧别名，外部可直接 require 取依赖。
local system = {object = object, container = container, group = group, room = room}
for name, value in pairs(system) do _G[name] = value end
return system
