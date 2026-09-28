--[[
    模块名: themeService
    描述: 读取 users/ui/theme.yml，并提供颜色与音符九宫格配置。
]]

local ThemeService = { data = {} }
local yamlParser = require('src.utils.yaml')
local baselines = {}

local function color(value)
    if type(value) == 'table' then
        local r, g, b = tonumber(value[1]), tonumber(value[2]), tonumber(value[3])
        if not r or not g or not b then return nil end
        local a = tonumber(value[4]) or 1
        if math.max(r, g, b, a) > 1 then
            r, g, b, a = r / 255, g / 255, b / 255, a > 1 and a / 255 or a
        end
        return {r, g, b, a}
    end
    if type(value) ~= 'string' then return nil end
    local hex = value:match('^#?(%x+)$')
    if not hex or (#hex ~= 6 and #hex ~= 8) then return nil end
    local r = tonumber(hex:sub(1, 2), 16) / 255
    local g = tonumber(hex:sub(3, 4), 16) / 255
    local b = tonumber(hex:sub(5, 6), 16) / 255
    local a = #hex == 8 and tonumber(hex:sub(7, 8), 16) / 255 or 1
    return {r, g, b, a}
end

local function hex(value)
    if type(value) == 'string' and ( #value == 7 or #value == 9 ) and value:match('^#%x+$') then return value end
    return nil
end

local function clone(value)
    if type(value) ~= 'table' then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = clone(item) end
    return result
end

-- 内置 YAML 解析器会把裸数字/英文值后面的注释当成值；这里只移除引号外的行尾注释。
local function stripComments(source)
    local lines = {}
    source = source:gsub('\r\n', '\n'):gsub('\r', '\n')
    for line in (source .. '\n'):gmatch('(.-)\n') do
        local quote, escaped
        for i = 1, #line do
            local char = line:sub(i, i)
            if escaped then
                escaped = false
            elseif quote == '"' and char == '\\' then
                escaped = true
            elseif quote then
                if char == quote then quote = nil end
            elseif char == '"' or char == "'" then
                quote = char
            elseif char == '#' and (i == 1 or line:sub(i - 1, i - 1):match('%s')) then
                line = line:sub(1, i - 1):gsub('%s+$', '')
                break
            end
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, '\n')
end

local function restore(target, baseline)
    for key, value in pairs(baseline) do
        if type(value) == 'table' and type(target[key]) == 'table' then
            restore(target[key], value)
        else
            target[key] = value
        end
    end
end

function ThemeService:restoreColors(target, name)
    if not baselines[name] then baselines[name] = clone(target) end
    restore(target, baselines[name])
end

function ThemeService:load(path)
    self.data = {}
    local source = nativefs.read(path)
    if not source and love.filesystem then source = love.filesystem.read(path) end
    if not source or source == '' then return true end
    local ok, result = pcall(yamlParser.eval, stripComments(source:gsub('^\239\187\191', '')))
    if not ok or type(result) ~= 'table' then
        if log then log('theme.yml: ' .. tostring(result)) end
        return false
    end
    self.data = result
    return true
end

function ThemeService:section(name, mode)
    local colors = self.data.colors
    local root = type(colors) == 'table' and colors[mode]
    return type(root) == 'table' and type(root[name]) == 'table' and root[name] or {}
end

function ThemeService:color(value)
    return color(value)
end

function ThemeService:overrideColorTable(target, name, mode)
    local source = self:section(name, mode)
    for key, value in pairs(source) do
        local parsed = color(value)
        if parsed and type(target[key]) == 'table' then
            for i = 1, 4 do target[key][i] = parsed[i] end
        elseif type(value) == 'table' and type(target[key]) == 'table' then
            for subkey, subvalue in pairs(value) do
                parsed = color(subvalue)
                if parsed and type(target[key][subkey]) == 'table' then target[key][subkey] = parsed end
            end
        end
    end
end

function ThemeService:nuklearColors(mode, defaults)
    local result = {}
    for key, value in pairs(defaults) do result[key] = value end
    for key, value in pairs(self:section('nuklear', mode)) do
        if result[key] and hex(value) then result[key] = value end
    end
    return result
end

function ThemeService:iconColor(mode, name)
    local all = self.data.ui_images
    local values = type(all) == 'table' and all[mode]
    if type(values) ~= 'table' then return nil end
    return color(values[name]) or color(values.default)
end

function ThemeService:judgeColor(mode, part)
    local colors = self.data.judge_line
    local values = type(colors) == 'table' and colors[mode]
    return type(values) == 'table' and color(values[part]) or nil
end

function ThemeService:backgroundColor(mode)
    local root = self.data.colors
    local values = type(root) == 'table' and root[mode]
    return type(values) == 'table' and color(values.background) or nil
end

function ThemeService:editorColor(mode, key)
    return color(self:section('editor', mode)[key])
end

function ThemeService:tabColors(mode, defaults)
    local result = clone(defaults)
    for key, value in pairs(self:section('tabs', mode)) do
        if key == 'bar' or key == 'thumb' then
            local parsed = color(value)
            if parsed then result[key] = parsed end
        elseif type(result[key]) == 'string' then
            if hex(value) then result[key] = value end
        elseif type(result[key]) == 'table' and type(value) == 'table' then
            for i = 1, #result[key] do
                if hex(value[i]) then result[key][i] = value[i] end
            end
        elseif (key == 'info_background' or key == 'info_border') and hex(value) then
            result[key] = value
        end
    end
    return result
end

function ThemeService:slice(kind)
    local slices = self.data.note_slices
    if type(slices) ~= 'table' or type(kind) ~= 'string' then return nil end
    local value = slices[kind]
    if not value and kind:match('^hold_') then value = slices.hold end
    if type(value) ~= 'table' then return nil end
    return value
end

return ThemeService
