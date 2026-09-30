--[[
    模块名: Note
    描述: 音符对象类，封装所有音符属性的访问
    作者: qwwshs

    所有字段通过 getter/setter 方法访问，不直接暴露内部数据。
    支持深度拷贝（copy）、深度比较（eq/__eq）、序列化（toTable）。
]]

local Note = {}
Note.__index = function(self, key)
    return Note[key]
end

--- 创建新的 Note 对象
-- @tparam table data 初始数据，支持字段：beat, track, type, fake, beat2, note_head, wipe_head
-- @treturn Note 新的 Note 实例
function Note.new(data)
    data = data or {}
    local self = setmetatable({}, Note)
    self._data = {
        beat      = data.beat or {0, 0, 1},
        track     = data.track or 1,
        type      = data.type or 'note',
        fake      = data.fake or 0,
        beat2     = data.beat2,
        note_head = data.note_head or 0,
        wipe_head = data.wipe_head or 0,
    }
    return self
end

-- ========== Getter ==========

function Note:getBeat()      return self._data.beat end
function Note:getTrack()     return self._data.track end
function Note:getType()      return self._data.type end
function Note:getFake()      return self._data.fake end
function Note:getBeat2()     return self._data.beat2 end
function Note:getNoteHead()  return self._data.note_head end
function Note:getWipeHead()  return self._data.wipe_head end

-- ========== Setter ==========

function Note:setBeat(v)      self._data.beat = v end
function Note:setTrack(v)     self._data.track = v end
function Note:setType(v)      self._data.type = v end
function Note:setFake(v)      self._data.fake = v end
function Note:setBeat2(v)     self._data.beat2 = v end
function Note:setNoteHead(v)  self._data.note_head = v end
function Note:setWipeHead(v)  self._data.wipe_head = v end

-- ========== 便捷判断 ==========

function Note:isHold()       return self._data.type == 'hold' end
function Note:isNote()       return self._data.type == 'note' end
function Note:isWipe()       return self._data.type == 'wipe' end
function Note:isFakeNote()   return self._data.fake == 1 end

-- ========== 数值计算 ==========

--- 获取 beat 的数值表示（委托给 beat 模块）
-- @treturn number beat 数值
function Note:getBeatValue()
    return beat:get(self._data.beat)
end

--- 获取 beat2 的数值表示（hold 专用，非 hold 返回 nil）
-- @treturn number|nil beat2 数值
function Note:getBeat2Value()
    if self._data.beat2 then
        return beat:get(self._data.beat2)
    end
    return nil
end

-- ========== 操作 ==========

--- 深拷贝当前 Note 对象
-- @treturn Note 新的 Note 实例（内容相同，引用不同）
function Note:copy()
    local d = self._data
    return Note.new({
        beat      = table.copy(d.beat),
        track     = d.track,
        type      = d.type,
        fake      = d.fake,
        beat2     = d.beat2 and table.copy(d.beat2),
        note_head = d.note_head,
        wipe_head = d.wipe_head,
    })
end

--- 深度比较两个 Note 对象是否相等
-- @tparam Note other 另一个 Note 对象
-- @treturn boolean 是否相等
function Note:eq(other)
    if not other or not other._data then return false end
    local a, b = self._data, other._data
    if a.track ~= b.track then return false end
    if a.type ~= b.type then return false end
    if a.fake ~= b.fake then return false end
    if a.note_head ~= b.note_head then return false end
    if a.wipe_head ~= b.wipe_head then return false end
    if not table.eq(a.beat, b.beat) then return false end
    -- beat2 比较：两者都为 nil 才相等
    if a.beat2 == nil and b.beat2 == nil then return true end
    if a.beat2 == nil or b.beat2 == nil then return false end
    return table.eq(a.beat2, b.beat2)
end

Note.__eq = Note.eq

-- ========== 序列化 ==========

--- 转为纯 table（用于手动序列化）
-- @treturn table 纯数据 table
function Note:toTable()
    local d = self._data
    local t = {
        beat  = d.beat,
        track = d.track,
        type  = d.type,
        fake  = d.fake,
    }
    if d.beat2 then
        t.beat2 = d.beat2
    end
    if d.type == 'hold' then
        t.note_head = d.note_head
        t.wipe_head = d.wipe_head
    end
    return t
end

--- dkjson 序列化支持：返回带缩进的 JSON 字符串
Note.__tojson = function(self, state)
    return dkjson.encode(self:toTable(), { indent = true })
end

-- ============================================================
-- 撤销强制记录：所有 setter 经 chartRecorder 拦截（src/utils/chartRecorder.lua）
-- 图谱面的对象自动快照旧值并归入当前事务；事务外的单次 setter 自动成为一条记录；
-- 豁免期（撤销回放/内部舞步）与谱面外副本（粘贴预览、编辑副本等）不产生记录
-- ============================================================
local recorder = require("src.utils.chartRecorder")
local MUTATING_SETTERS = { 'setBeat', 'setTrack', 'setType', 'setFake', 'setBeat2', 'setNoteHead', 'setWipeHead' }
for i = 1, #MUTATING_SETTERS do
    local name = MUTATING_SETTERS[i]
    local original = Note[name]
    Note[name] = function(self, v)
        return recorder.autoCommit(function() original(self, v) end, self)
    end
end

return Note
