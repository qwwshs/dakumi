-- 音符与事件侧栏共用的偏移输入。空白关闭偏移，其他输入只允许有限正数。
local TimeOffset = require('src.utils.timeOffset')
local Field = {}
Field.__index = Field
function Field.new() return setmetatable({value = '', error = nil}, Field) end
function Field:load(entity)
    local offset = entity:getTimeOffset()
    self.value = offset > 0 and tostring(offset) or ''
    self.error = nil
end
function Field:draw(height)
    Nui:layoutRow('dynamic', height, 2)
    Nui:label(i18n:get('time_offset'))
    ui:edit('field', self)
    if self.error then
        Nui:layoutRow('dynamic', height, 1)
        Nui:label(i18n:get(self.error))
    end
end
function Field:apply(entity, chart)
    local value
    if not self.value:match('^%s*$') then
        value = tonumber(self.value)
        if not TimeOffset.valid(value) then self.error = 'time_offset_invalid'; return false end
    end
    if (value or 0) == entity:getTimeOffset() then self.error = nil; return true end
    if entity.getEventGroup then
        local candidate = entity:copy()
        candidate:setTimeOffset(value)
        if not chart:canPlaceEvent(candidate, entity) then self.error = 'time_offset_overlap'; return false end
    end
    entity:setTimeOffset(value)
    self.error = nil
    return true
end
return Field
