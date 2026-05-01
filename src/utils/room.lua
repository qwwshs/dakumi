object = {}

function object:new(__name)
    local obj = {__name = "",__type = ""}
    if type(__name) == 'string' then obj.__name = __name end
    setmetatable(obj, object)
    return obj
end

container = object:new('')

container.objects = {}
container.groups = {}
container.__index = container
function container:new(__name)
    if type(__name) ~= "string" then return end
    local c = object:new(__name)
    c.objects = {}
    c.groups = {}
    setmetatable(c,container)
    return c
end

function container:addObject(obj)
    if type(obj) ~= "table" then return end
    table.insert(self.objects,obj)
end

function container:deleteObject(__name)
    if type(__name) ~= "string" then return end
    for i,v in ipairs(self.objects) do
        if v.__name == __name then
            table.remove(self.objects,i)
            break
        end
    end
end

function container:getObject(__name)
    if type(__name) ~= "string" then return end
    for _,v in ipairs(self.objects) do
        if v.__name == __name then
            return v
        end
    end
    return nil
end

function container:getAllTypeObject(isType)
    if type(isType) ~= "string" then return end
    local tab = {}
    for _,v in ipairs(self.objects) do
        if v.__type == isType then
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

function container:deleteGroup(__name)
    if type(__name) ~= "string" then return end
    for i,v in ipairs(self.groups) do
        if v.__name == __name then
            table.remove(self.groups,i)
            break
        end
    end
end

function container:getGroup(__name)
    if type(__name) ~= "string" then return end
    for _,v in ipairs(self.groups) do
        if v.__name == __name then
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
    for _,v in ipairs(self.groups) do
        if v.__type == isType then
            table.insert(tab,v)
        end
    end
    return tab
end

function container:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)

    if not self.rooms then return end
    if not self.rooms[self.__type] then return end
    if type(self.rooms[self.__type][methodName]) ~= 'function' then return end
    self.rooms[self.__type][methodName](self.rooms[self.__type],...)
end


group = container:new('')
group.__index = group

function group:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)
end

function group:new(__name)
    local g = {__name = '',objects = {},groups = {}}

    if type(__name) == 'string' then g.__name = __name end

    setmetatable(g,group)
    return g
end

room = container:new('main')
room.rooms = {}
room.__index = room

function room:__call(methodName,...)
    self:callAllObject(methodName,...)
    self:callAllGroup(methodName,...)

    if not self.rooms or not self.rooms[self.__type] or not self.rooms[self.__type][methodName] then return end

    self.rooms[self.__type][methodName](self.rooms[self.__type],...)
end

function room:new(__name)
    if not __name then return end
    local r = container:new(__name)
    r.rooms = {}
    setmetatable(r, room)
    return r
end

function room:load(__name)
    if not __name then return end
    self.__type = __name
end

function room:addRoom(room)
    self.rooms[room.__name] = room
end

function room:deleteRoom(room)
    self.rooms[room.__name] = nil
end

function room:getRoom(__name)
    return self.rooms[__name]
end

function room:to(__name,...)
    if self.rooms[__name] then
        self.rooms[__name]:load(...)
        self.__type = __name
    end
end