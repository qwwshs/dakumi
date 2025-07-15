object = {}

function object:new(name)
    local obj = {name = "",type = ""}
    if type(name) == 'string' then obj.name = name end
    setmetatable(obj, object)
    return obj
end

local container = object:new('')

container.objects = {}
container.groups = {}
container.__index = container
function container:new(name)
    if type(name) ~= "string" then return end
    local c = object:new(name)
    c.objects = {}
    c.groups = {}
    setmetatable(c,container)
    return c
end

function container:addObject(obj)
    if type(obj) ~= "table" then return end
    table.insert(self.objects,obj)
end

function container:deleteObject(name)
    if type(name) ~= "string" then return end
    for i,v in ipairs(self.objects) do
        if v.name == name then
            table.remove(self.objects,i)
            break
        end
    end
end

function container:getObject(name)
    if type(name) ~= "string" then return end
    for _,v in ipairs(self.objects) do
        if v.name == name then
            return v
        end
    end
    return nil
end

function container:getAllTypeObject(isType)
    if type(isType) ~= "string" then return end
    local tab = {}
    for _,v in ipairs(self.objects) do
        if v.type == isType then
            table.insert(tab,v)
        end
    end
    return tab
end

function container:getAllObject()
    return self.objects
end

function container:callAllObject(methodName,...)
    for _, obj in ipairs(self.objects) do
        if obj[methodName] then
            obj[methodName](obj,...)
        end
    end
end


function container:addGroup(group)
    if not group then return end
    if type(group) ~= "table" then return end
    table.insert(self.groups,group)
end

function container:deleteGroup(name)
    if type(name) ~= "string" then return end
    for i,v in ipairs(self.groups) do
        if v.name == name then
            table.remove(self.groups,i)
            break
        end
    end
end

function container:getGroup(name)
    if type(name) ~= "string" then return end
    for _,v in ipairs(self.groups) do
        if v.name == name then
            return v
        end
    end
    return nil
end

function container:getAllGroup()
    return self.groups
end

function container:callAllGroup(methodName,...)
    for _, group in ipairs(self.groups) do
        if group[methodName] then
            group[methodName](group,...)
        end
    end
end

function container:getAllTypeGroup(isType)
    if type(isType) ~= "string" then return end
    local tab = {}
    for _,v in ipairs(container.groups) do
        if v.type == isType then
            table.insert(tab,v)
        end
    end
    return tab
end

function container:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)

    if not self.rooms then return end
    if not self.rooms[self.type] then return end
    if type(self.rooms[self.type][methodName]) ~= 'function' then return end
    self.rooms[self.type][methodName](self.rooms[self.type],...)
end


group = container:new('')
group.__index = group

function group:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)
end

function group:new(name)
    local g = {name = '',objects = {},groups = {}}

    if type(name) == 'string' then g.name = name end

    setmetatable(g,group)
    return g
end

room = container:new('main')
room.rooms = {}
room.__index = room

function room:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)

    if not self.rooms then return end
    if not self.rooms[self.type] then return end
    if type(self.rooms[self.type][methodName]) ~= 'function' then return end
    self.rooms[self.type][methodName](self.rooms[self.type],...)
end

function room:new(name)
    if not name then return end
    local r = container:new(name)
    r.rooms = {}
    setmetatable(r, room)
    return r
end

function room:load(name)
    if not name then return end
    self.type = name
end

function room:addRoom(room)
    self.rooms[room.name] = room
end

function room:deleteRoom(room)
    self.rooms[room.name] = nil
end

function room:getRoom(name)
    return self.rooms[name]
end

function room:to(name,...)
    if self.rooms[name] then
        self.rooms[name]:load(...)
        self.type = name
    end
end