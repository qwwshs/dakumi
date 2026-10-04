--[[
    模块名: input
    描述: 快捷键管理模块，处理快捷键的注册和检测
    作者: qwwshs
    依赖: init 显式传入文件系统、JSON、默认键位和按键状态
]]

local input = {}
setmetatable(input, input)
local bindings = {}
local storedKeys
local dependencies
local keyboard
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local modifierAlias = {
    lctrl = 'ctrl', rctrl = 'ctrl', lalt = 'alt', ralt = 'alt',
    lshift = 'shift', rshift = 'shift',
}

local function includes(keys, value)
    for _, key in ipairs(keys) do if key == value then return true end end
    return false
end

local function validKeys(keys)
    if type(keys) ~= 'table' or #keys < 1 or #keys > 8 then return false end
    local seen = {}
    for i, key in ipairs(keys) do
        if type(key) ~= 'string' or key == '' or #key > 32 or seen[key] then return false end
        seen[key] = true
    end
    return true
end

--- 注册新的快捷键
-- @tparam string name 快捷键名称
-- @tparam string|table key 按键名称或按键数组
function input:new(name, key)
    if type(name) ~= 'string' or name == '' then return false end
    local keys = {}
    if type(key) == 'string' then
        keys = { key }
    elseif type(key) == 'table' then
        keys = copy(key)
    end
    if not validKeys(keys) then return false end
    bindings[name] = keys
    self[name] = {name = name, keys = keys}
    return true
end

function input:getBindingNames()
    local names = {}
    for name in pairs(bindings) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function input:getBinding(name)
    return bindings[name] and copy(bindings[name]) or nil
end

-- UI 独立读取原生按键，不让文本输入的按键进入编辑快捷键状态。
function input:getUIKeyboard()
    return dependencies and dependencies.uiKeyboard or {}
end

-- 写盘成功后才替换运行中的映射，确认后立即生效。
function input:setBinding(name, keys)
    if not bindings[name] or not validKeys(keys) then return false, 'invalid binding' end
    local nextKeys = copy(storedKeys)
    nextKeys[name] = copy(keys)
    local called, ok, err = pcall(dependencies.fs.write, dependencies.path,
        dependencies.json.encode(nextKeys, {indent = true}))
    if not called then return false, ok end
    if not ok then return false, err end
    storedKeys = nextKeys
    bindings[name] = copy(keys)
    self[name] = {name = name, keys = bindings[name]}
    return true
end

--- 检测快捷键是否被按下（作为 __call 元方法，可直接调用 input('name')）
-- @tparam string name 快捷键名称
-- @treturn boolean 是否按下
function input:__call(name)
    local keys = bindings[name]
    if not keys then
        if dependencies and dependencies.log then dependencies.log('input not found', name) end
        return false
    end
    for _, key in ipairs(keys) do
        if not keyboard[key] then
            return false
        end
    end
    --防止同时触发多个快捷键
    for pressed, down in pairs(keyboard) do
        local alias = modifierAlias[pressed]
        local covered = includes(keys, pressed) or (alias and includes(keys, alias))
        if pressed == 'ctrl' or pressed == 'alt' or pressed == 'shift' then
            for physical, normalized in pairs(modifierAlias) do
                if normalized == pressed and includes(keys, physical) then covered = true end
            end
        end
        if down and not covered then
            return false
        end
    end
    return true
end


-- require 只加载代码；启动方提供状态、默认键位和存储接口。
function input:init(options)
    assert(options and options.fs and options.json and options.keyboard and options.defaults,
        'input:init requires fs, json, keyboard and defaults')
    dependencies, keyboard = options, options.keyboard
    for name in pairs(bindings) do self[name] = nil end
    bindings = {}
    local ok, keys = pcall(options.json.decode, options.fs.read(options.path) or '')
    if not ok or type(keys) ~= 'table' then keys = {} end
    local defaults = options.defaults
    for name, value in pairs(defaults) do
        if not validKeys(keys[name]) then keys[name] = copy(value) end
    end
    storedKeys = copy(keys)
    for name, value in pairs(keys) do self:new(name, value) end
    return self
end

return input
