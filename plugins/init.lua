--[[
    模块名: plugins/init
    描述: 自动发现插件入口，在场景、服务和 Nui 准备完成后统一注册
    作者: qwwshs
    支持 plugins/name.lua 与 plugins/name/init.lua；跳过 init.lua 和下划线开头的入口。
    外部目录中的同名入口覆盖打包版本；目录内辅助文件不会单独扫描。
]]
local function loadPlugins(manager)
    local virtual = PATH.plugins:gsub('/+$', '')
    local source = love.filesystem.getSource()
    local base = love.filesystem.isFused() or source:lower():match('%.love$')
    local external = (base and PATH.base or source) .. '/' .. virtual
    if virtual:match('^%a:[/\\]') or virtual:sub(1, 1) == '/' then external = virtual end
    -- 允许插件通过 require('plugins.name.helper') 加载外部目录里的辅助模块。
    package.path = external .. '/?.lua;' .. external .. '/?/init.lua;' ..
        external .. '/../?.lua;' .. external .. '/../?/init.lua;' .. package.path

    local function read(relative)
        local content = nativefs.read(external .. '/' .. relative)
        if content then return content, external .. '/' .. relative end
        content = love.filesystem.read(virtual .. '/' .. relative)
        return content, virtual .. '/' .. relative
    end
    local entries = {}
    local names = {}
    local function collect(items)
        for _, name in ipairs(items) do
            if name ~= 'init.lua' and name:sub(1, 1) ~= '_' then names[name] = true end
        end
    end
    collect(love.filesystem.getDirectoryItems(virtual))
    collect(nativefs.getDirectoryItems(external))
    for name in pairs(names) do
        local relative = name:match('%.lua$') and name or name .. '/init.lua'
        local content, path = read(relative)
        if content then entries[#entries + 1] = {relative = relative, content = content, path = path} end
    end
    table.sort(entries, function(a, b) return a.relative < b.relative end)
    local result = {loaded = {}, errors = {}}
    for _, entry in ipairs(entries) do
        local module = 'plugins.' .. entry.relative:gsub('/init%.lua$', ''):gsub('%.lua$', ''):gsub('/', '.')
        local ok, err = pcall(function()
            local chunk, syntaxError = loadstring(entry.content:gsub('^\239\187\191', ''), '@' .. entry.path)
            if not chunk then error(syntaxError) end
            local plugin = chunk()
            if type(plugin) ~= 'table' then error('entry must return a plugin table') end
            local descriptor = plugin.plugin or plugin
            if type(descriptor) ~= 'table' then error('plugin metadata must be a table') end
            descriptor.path = entry.path:match('^(.*)/[^/]+$')
            if descriptor.enabled == false then
                package.loaded[module] = plugin
            else
                local registered, reason = manager:register(plugin)
                if not registered then error(reason) end
                package.loaded[module] = plugin
                result.loaded[#result.loaded + 1] = descriptor.name
            end
        end)
        if not ok then
            result.errors[#result.errors + 1] = {path = entry.path, message = tostring(err)}
            if log then pcall(log, '[Plugins] ' .. entry.path .. ': ' .. tostring(err)) end
        end
    end
    return result
end
return loadPlugins
