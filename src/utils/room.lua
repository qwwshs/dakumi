object = {}

object.__index = function(table, key)
    if type(key) == "string" then --在调用不存在的函数时返回空函数
        return function(self, ...) end
    end
    return nil
end

function object:new(name)
    local obj = {name = "",type = ""}
    if type(name) == 'string' then obj.name = name end
    setmetatable(obj, object)
    return obj
end

group = {}

function group:new(name)
    local g = {name = '',objects = {},groups = {}}

    if type(name) == 'string' then g.name = name end

    function g:addObject(obj)
        if type(obj) ~= "table" then return end
        table.insert(g.objects,obj)
    end

    function g:deleteObject(name)
        if type(name) ~= "string" then return end
        for i,v in ipairs(g.objects) do
            if v.name == name then
                table.remove(g.objects,i)
                break
            end
        end
    end

    function g:getObject(name)
        if type(name) ~= "string" then return end
        for _,v in ipairs(g.objects) do
            if v.name == name then
                return v
            end
        end
        return nil
    end

    function g:getAllTypeObject(isType)
        if type(isType) ~= "string" then return end
        local tab = {}
        for _,v in ipairs(g.objects) do
            if v.type == isType then
                table.insert(tab,v)
            end
        end
        return tab
    end

    function g:getAllObject()
        return g.objects
    end

    function g:callAllObject(methodName,...)
        for _, obj in ipairs(g.objects) do
            if obj[methodName] then
                obj[methodName](obj,...)
            end
        end
    end

    
    function g:addGroup(group)
        if not group then return end
        if type(group) ~= "table" then return end
        table.insert(self.groups,group)
    end

    function g:deleteGroup(name)
        if type(name) ~= "string" then return end
        for i,v in ipairs(self.groups) do
            if v.name == name then
                table.remove(self.groups,i)
                break
            end
        end
    end

    function g:getGroup(name)
        if type(name) ~= "string" then return end
        for _,v in ipairs(self.groups) do
            if v.name == name then
                return v
            end
        end
        return nil
    end

    function g:getAllGroup()
        return self.groups
    end

    function g:callAllGroup(methodName,...)
        for _, group in ipairs(self.groups) do
            if group[methodName] then
                group[methodName](group,...)
            end
        end
    end

    function g:getAllTypeGroup(isType)
        if type(isType) ~= "string" then return end
        local tab = {}
        for _,v in ipairs(g.groups) do
            if v.type == isType then
                table.insert(tab,v)
            end
        end
        return tab
    end

    setmetatable(g, {
        __index = function(self, methodName)
            self:callAllObject(methodName)
            self:callAllGroup(methodName)
            end,
        __call = function(self,methodName,...)
            self:callAllObject(methodName,...)
            self:callAllGroup(methodName)
        end
    })
    return g
end

local metaRoom = {type = '',rooms = {},groups = {},objects = {},name = ''}

function metaRoom:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)

    if not self.rooms[self.type] then return end
    if type(self.rooms[self.type][methodName]) ~= 'function' then return end
    self.rooms[self.type][methodName](self.rooms[self.type],...)
end

function metaRoom:load(name)
    if not name then return end
    self.type = name
end

function metaRoom:new(name)
    if not name then return end
    local r = {type = '',rooms = {},groups = {},objects = {},name = name}
    setmetatable(r, metaRoom)
    return r
end

function metaRoom:addRoom(room)
    self.rooms[room.name] = room
end

function metaRoom:deleteRoom(room)
    self.rooms[room.name] = nil
end

function metaRoom:getRoom(name)
    return self.rooms[name]
end

function metaRoom:to(name,...)
    if self.rooms[name] then
        self.rooms[name]:load(...)
        self.type = name
    end
end

function metaRoom:addObject(obj)
    if type(obj) ~= "table" then return end
    table.insert(self.objects,obj)
end

function metaRoom:deleteObject(name)
    if type(name) ~= "string" then return end
    for i,v in ipairs(self.objects) do
        if v.name == name then
            table.remove(self.objects,i)
            break
        end
    end
end

function metaRoom:getObject(name)
    if type(name) ~= "string" then return end
    for _,v in ipairs(self.objects) do
        if v.name == name then
            return v
        end
    end
    return nil
end

function metaRoom:getAllTypeObject(isType)
    if type(isType) ~= "string" then return end
    local tab = {}
    for _,v in ipairs(self.objects) do
        if v.type == isType then
            table.insert(tab,v)
        end
    end
    return tab
end

function metaRoom:getAllObject()
    return self.objects
end

function metaRoom:callAllObject(methodName,...)
    for _, obj in ipairs(self.objects) do
        if obj[methodName] then
            obj[methodName](obj,...)
        end
    end
end

function metaRoom:addGroup(g)
    if not g then return end
    if type(g) ~= "table" then return end
    table.insert(self.groups,g)
end

function metaRoom:deleteGroup(name)
    if type(name) ~= "string" then return end
    for i,v in ipairs(self.groups) do
        if v.name == name then
            table.remove(self.groups,i)
            break
        end
    end
end

function metaRoom:getGroup(name)
    if type(name) ~= "string" then return end
    for _,v in ipairs(self.groups) do
        if v.name == name then
            return v
        end
    end
    return nil
end

function metaRoom:getAllGroup()
    return self.groups
end

function metaRoom:callAllGroup(methodName,...)
    for _, group in ipairs(self.groups) do
        if group[methodName] then
            group[methodName](group,...)
        end
    end
end

metaRoom.__index = metaRoom

room = {type = '',rooms = {},groups = {},objects = {},name = 'main'}

setmetatable(room,metaRoom)
