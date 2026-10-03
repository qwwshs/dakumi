--[[
    模块名: input
    描述: 快捷键管理模块，处理快捷键的注册和检测
    作者: qwwshs
    依赖: nativefs, dkjson, meta_key, iskeyboard, table, PATH
]]

local input = {}
setmetatable(input, input)
local bindings = {}
local storedKeys

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
        keys = table.copy(key)
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
    return bindings[name] and table.copy(bindings[name]) or nil
end

-- 写盘成功后才替换运行中的映射，确认后立即生效。
function input:setBinding(name, keys)
    if not bindings[name] or not validKeys(keys) then return false, 'invalid binding' end
    local nextKeys = table.copy(storedKeys)
    nextKeys[name] = table.copy(keys)
    local called, ok, err = pcall(nativefs.write, PATH.usersPath.key .. 'key.json',
        dkjson.encode(nextKeys, {indent = true}))
    if not called then return false, ok end
    if not ok then return false, err end
    storedKeys = nextKeys
    bindings[name] = table.copy(keys)
    self[name] = {name = name, keys = bindings[name]}
    return true
end

--- 检测快捷键是否被按下（作为 __call 元方法，可直接调用 input('name')）
-- @tparam string name 快捷键名称
-- @treturn boolean 是否按下
function input:__call(name)
    local keys = bindings[name]
    if not keys then
        log('input')
        log(name)
        log('not found')
        return false
    end
    for _, key in ipairs(keys) do
        if not iskeyboard[key] then
            return false
        end
    end
    --防止同时触发多个快捷键
    for pressed, down in pairs(iskeyboard) do
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


--快捷键相关
nativefs.mount(PATH.base)

local key_file = nativefs.read(PATH.usersPath.key .. 'key.json') or ''
local key
pcall(function() key = dkjson.decode(key_file) or meta_key.__index end)
if type(key) ~= 'table' then
    key = meta_key.__index
end
table.fill(key, meta_key.__index)
storedKeys = table.copy(key)
save(dkjson.encode(key, { indent = true }), PATH.usersPath.key .. 'key.json')
for i, v in pairs(key) do
    input:new(i, v)
end
nativefs.unmount(PATH.base)


return input
