--[[
    模块名: keyCapture
    描述: 设置页的快捷键录入状态。按下的键组成一组，全部松开后才能确认。
]]

local input = require('src.utils.input')
local Capture = {action = nil, phase = 'idle', down = {}, keys = {}, error = nil}

local aliases = {
    lctrl = 'ctrl', rctrl = 'ctrl', lalt = 'alt', ralt = 'alt',
    lshift = 'shift', rshift = 'shift',
}
local modifierOrder = {'ctrl', 'alt', 'shift'}
local displayNames = {
    ctrl = 'Ctrl', alt = 'Alt', shift = 'Shift', space = 'Space',
    ['return'] = 'Enter', kpenter = 'Num Enter', escape = 'Esc',
    left = '←', right = '→', up = '↑', down = '↓',
    tab = 'Tab', backspace = 'Backspace', delete = 'Delete',
}

local function display(keys)
    local labels = {}
    for i, key in ipairs(keys or {}) do
        labels[i] = displayNames[key] or (key:sub(1, 2) == 'kp' and
            'Num ' .. key:sub(3) or key:upper())
    end
    return table.concat(labels, ' + ')
end

function Capture:format(keys) return display(keys) end
function Capture:isActive() return self.action ~= nil end
function Capture:isReady() return self.action ~= nil and self.phase == 'ready' end

function Capture:begin(action)
    if not input:getBinding(action) then return false end
    self.action, self.phase, self.down, self.keys, self.error = action, 'waiting', {}, {}, nil
    return true
end

function Capture:cancel()
    self.action, self.phase, self.down, self.keys, self.error = nil, 'idle', {}, {}, nil
end

function Capture:keypressed(key, isrepeat)
    if not self:isActive() then return false end
    if self.phase == 'ready' or isrepeat or key == 'unknown' then return true end
    if self.down[key] then return true end
    self.down[key] = true
    local normalized = aliases[key] or key
    for _, existing in ipairs(self.keys) do
        if existing == normalized then return true end
    end
    self.keys[#self.keys + 1] = normalized
    self.phase = 'holding'
    return true
end

function Capture:keyreleased(key)
    if not self:isActive() then return false end
    if not self.down[key] then return true end
    self.down[key] = nil
    if self.phase == 'holding' and not next(self.down) then
        local ordered = {}
        for _, modifier in ipairs(modifierOrder) do
            for _, recorded in ipairs(self.keys) do
                if modifier == recorded then ordered[#ordered + 1] = modifier end
            end
        end
        for _, recorded in ipairs(self.keys) do
            if recorded ~= 'ctrl' and recorded ~= 'alt' and recorded ~= 'shift' then
                ordered[#ordered + 1] = recorded
            end
        end
        self.keys = ordered
        self.phase = 'ready'
    end
    return true
end

function Capture:confirm()
    if not self:isReady() then return false, 'not ready' end
    local ok, err = input:setBinding(self.action, self.keys)
    if ok then self:cancel(); return true end
    self.error = tostring(err or 'write failed')
    return false, self.error
end

function Capture:getDisplay()
    return display(self.keys)
end

return Capture
