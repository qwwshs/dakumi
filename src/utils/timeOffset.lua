-- 元件时间偏移：字段单位为毫秒，时钟由谱面服务注入，工具不反向引用服务。
local Offset = {}
local clock
function Offset.init(value) clock = value end
function Offset.valid(value)
    return type(value) == 'number' and value == value and value > 0 and value < math.huge
end
function Offset.normalize(value) return Offset.valid(value) and value or nil end
local function number(value) return type(value) == 'number' and value or beat:get(value) end
function Offset.shiftBeat(value, milliseconds)
    local base = number(value)
    if not milliseconds or milliseconds == 0 then return base end
    assert(clock, '时间偏移需要先装配谱面时钟')
    return clock:toBeat(clock:toTime(base) + milliseconds / 1000)
end
function Offset.baseBeat(value, milliseconds)
    if (not milliseconds or milliseconds == 0) and type(value) == 'table' then
        return {value[1], value[2], value[3]}
    end
    local result = number(value)
    if milliseconds and milliseconds > 0 then
        assert(clock, '时间偏移需要先装配谱面时钟')
        result = clock:toBeat(clock:toTime(result) - milliseconds / 1000)
    end
    -- 保存成分数，避免把精确毫秒位置再次吸附到编辑分度。
    local whole = math.floor(result)
    local fraction = math.floor((result - whole) * 1000000000 + 0.5)
    return {whole, fraction, 1000000000}
end
function Offset.changed(entity)
    if clock and clock.onTimeOffsetChanged then clock:onTimeOffsetChanged(entity) end
end
return Offset
