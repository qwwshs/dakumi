--[[
    模块名: Event
    描述: 事件对象类，封装所有事件属性的访问
    作者: qwwshs

    所有字段通过 getter/setter 方法访问，不直接暴露内部数据。
    支持深度拷贝（copy）、深度比较（eq/__eq）、序列化（toTable）。

    trans 字段是嵌套表 {trans={...}, type="bezier"|"easings", easings=number}，
    提供便捷方法直接访问子字段。
]]

local Event = {}
Event.__index = function(self, key)
    return Event[key]
end

--- 创建新的 Event 对象
-- @tparam table data 初始数据
-- @treturn Event 新的 Event 实例
function Event.new(data)
    data = data or {}
    local self = setmetatable({}, Event)
    self._data = {
        beat  = data.beat or {0, 0, 1},
        beat2 = data.beat2 or {0, 0, 1},
        track = data.track or 1,
        type  = data.type or 'x',
        from  = data.from or 0,
        to    = data.to or 0,
        event_group = data.event_group or '',
        flip_horizontally = data.flip_horizontally == 1 and 1 or 0,
        flip_vertically = data.flip_vertically == 1 and 1 or 0,
        trans = data.trans or {
            trans = {0, 0, 1, 1},
            type = 'bezier',
            easings = 1,
        },
    }
    return self
end

-- ========== Getter ==========

function Event:getBeat()   return self._data.beat end
function Event:getBeat2()  return self._data.beat2 end
function Event:getTrack()  return self._data.track end
function Event:getType()   return self._data.type end
function Event:getFrom()   return self._data.from end
function Event:getTo()     return self._data.to end
function Event:getTrans()  return self._data.trans end
function Event:getEventGroup() return self._data.event_group end
function Event:getFlipHorizontally() return self._data.flip_horizontally end
function Event:getFlipVertically() return self._data.flip_vertically end

-- trans 子字段便捷访问
function Event:getTransType()   return self._data.trans.type end
function Event:getTransData()   return self._data.trans.trans end
function Event:getEasings()     return self._data.trans.easings end

-- ========== Setter ==========

function Event:setBeat(v)   self._data.beat = v end
function Event:setBeat2(v)  self._data.beat2 = v end
function Event:setTrack(v)  self._data.track = v end
function Event:setType(v)   self._data.type = v end
function Event:setFrom(v)   self._data.from = v end
function Event:setTo(v)     self._data.to = v end
function Event:setTrans(v)  self._data.trans = v end
function Event:setEventGroup(v) self._data.event_group = v end
function Event:setFlipHorizontally(v) self._data.flip_horizontally = v == 1 and 1 or 0 end
function Event:setFlipVertically(v) self._data.flip_vertically = v == 1 and 1 or 0 end

-- trans 子字段便捷设置
function Event:setTransType(v)   self._data.trans.type = v end
function Event:setTransData(v)   self._data.trans.trans = v end
function Event:setEasings(v)     self._data.trans.easings = v end

-- ========== 数值计算 ==========

--- 获取 beat 的数值表示
function Event:getBeatValue()
    return beat:get(self._data.beat)
end

--- 获取 beat2 的数值表示
function Event:getBeat2Value()
    return beat:get(self._data.beat2)
end

-- ========== 类型判断 ==========

function Event:isX()     return self._data.type == 'x' end
function Event:isW()     return self._data.type == 'w' end
function Event:isLpos()  return self._data.type == 'lpos' end
function Event:isRpos()  return self._data.type == 'rpos' end

-- ========== 操作 ==========

--- 深拷贝当前 Event 对象
function Event:copy()
    local d = self._data
    return Event.new({
        beat  = table.copy(d.beat),
        beat2 = table.copy(d.beat2),
        track = d.track,
        type  = d.type,
        from  = d.from,
        to    = d.to,
        trans = table.copy(d.trans),
        event_group = d.event_group,
        flip_horizontally = d.flip_horizontally,
        flip_vertically = d.flip_vertically,
    })
end

--- 深度比较两个 Event 对象是否相等
function Event:eq(other)
    if not other or not other._data then return false end
    local a, b = self._data, other._data
    if a.track ~= b.track then return false end
    if a.type ~= b.type then return false end
    if a.from ~= b.from then return false end
    if a.to ~= b.to then return false end
    if not table.eq(a.beat, b.beat) then return false end
    if not table.eq(a.beat2, b.beat2) then return false end
    if not table.eq(a.trans, b.trans) then return false end
    if a.event_group ~= b.event_group or
        a.flip_horizontally ~= b.flip_horizontally or
        a.flip_vertically ~= b.flip_vertically then return false end
    return true
end

Event.__eq = Event.eq

-- ========== 序列化 ==========

--- 转为纯 table（用于手动序列化）
function Event:toTable()
    local d = self._data
    return {
        beat  = d.beat,
        beat2 = d.beat2,
        track = d.track,
        type  = d.type,
        from  = d.from,
        to    = d.to,
        trans = d.trans,
        event_group = d.event_group,
        flip_horizontally = d.flip_horizontally,
        flip_vertically = d.flip_vertically,
    }
end

--- dkjson 序列化支持：返回带缩进的 JSON 字符串
Event.__tojson = function(self, state)
    return dkjson.encode(self:toTable(), { indent = true })
end

return Event
