--[[
    模块名: PluginManager
    描述: 插件注册、目标容器挂载、钩子与卸载；入口发现由 plugins/init.lua 负责
    作者: qwwshs
    描述表回调使用 function(ctx, ...)，object 模式使用对象的冒号方法。
]]
local PluginManager = {plugins = {}, hooks = {}, records = {}, sequence = 0}
local function report(message)
    if type(log) == 'function' then pcall(log, '[PluginManager] ' .. message) end
end
local function pack(...) return {n = select('#', ...), ...} end
local function validLayer(layer)
    return layer == nil or (type(layer) == 'number' and layer == layer and layer ~= -math.huge)
end

function PluginManager:init(ctx)
    local names = self:getPluginNames()
    for _, name in ipairs(names) do self:unregister(name) end
    self.ctx = ctx or {}
    self.plugins, self.hooks, self.records, self.sequence = {}, {}, {}, 0
end

function PluginManager:resolveTarget(target)
    if type(target) == 'table' and target._entries and type(target.addObject) == 'function' then
        return target
    end
    local root = self.ctx and self.ctx.root
    if root and type(target or 'main') == 'string' then
        return root:findContainer(target or 'main')
    end
end

-- 每个插件只有一个代理挂载到目标；生命周期只走场景分发，不再全局重复调用。
function PluginManager:register(plugin)
    if type(plugin) ~= 'table' then return false, 'plugin must be a table' end
    -- 兼容内置 object 模块：对象上只携带注册信息，加载器统一注册。
    if plugin.plugin then
        local descriptor = {}
        for key, value in pairs(plugin.plugin) do descriptor[key] = value end
        descriptor.object = plugin
        plugin = descriptor
    end
    local function fail(message)
        report(message)
        return false, message
    end
    if type(plugin.name) ~= 'string' or plugin.name == '' then return fail('missing plugin name') end
    if self.plugins[plugin.name] then return fail('duplicate plugin: ' .. plugin.name) end
    if not validLayer(plugin.layer) then return fail('invalid layer: ' .. plugin.name) end
    if plugin.object ~= nil and type(plugin.object) ~= 'table' then return fail('invalid object: ' .. plugin.name) end
    if plugin.hooks ~= nil and type(plugin.hooks) ~= 'table' then return fail('invalid hooks: ' .. plugin.name) end
    if plugin.export ~= nil and type(plugin.export) ~= 'string' then return fail('invalid export: ' .. plugin.name) end
    local importing=plugin.type=='import'
    if importing and (type(plugin.review)~='function' or type(plugin.import)~='function') then
        return fail('import plugin requires review and import: '..plugin.name)
    end
    local target = not importing and self:resolveTarget(plugin.target) or nil
    if not importing and not target then return fail('target not found for ' .. plugin.name .. ': ' .. tostring(plugin.target)) end

    self.sequence = self.sequence + 1
    local record = {plugin = plugin, target = target, order = self.sequence, active = true}
    local proxy = {__name = plugin.name, __type = plugin.object and plugin.object.__type or ''}
    setmetatable(proxy, {__index = function(_, method)
        local owner = plugin.object or plugin
        if type(owner[method]) ~= 'function' then return nil end
        return function(_, ...)
            if not record.active then return end
            local result = pack(pcall(owner[method], plugin.object or self.ctx, ...))
            if not result[1] then
                report(plugin.name .. '.' .. tostring(method) .. ': ' .. tostring(result[2]))
                return
            end
            return unpack(result, 2, result.n)
        end
    end})
    record.proxy = proxy
    if target then target:addObject(proxy, plugin.layer) end
    self.plugins[plugin.name], self.records[plugin.name] = plugin, record
    if plugin.export then
        record.previousExport = _G[plugin.export]
        _G[plugin.export] = plugin.object or plugin
    end
    for eventName, callback in pairs(plugin.hooks or {}) do self:on(eventName, callback, plugin.name) end
    if type(plugin.init) == 'function' then
        local success, err = pcall(plugin.init, self.ctx)
        if not success then
            self:unregister(plugin.name)
            return fail('init failed for ' .. plugin.name .. ': ' .. tostring(err))
        end
    end
    report('registered ' .. plugin.name)
    return true
end

function PluginManager:unregister(name)
    local record = self.records[name]
    if not record then return false end
    local plugin = record.plugin
    record.active = false
    if record.target then record.target:deleteObject(record.proxy) end
    self.plugins[name], self.records[name] = nil, nil
    for _, listeners in pairs(self.hooks) do
        for i = #listeners, 1, -1 do
            if listeners[i].pluginName == name then
                listeners[i].active = false
                table.remove(listeners, i)
            end
        end
    end
    if type(plugin.destroy) == 'function' then
        local ok, err = pcall(plugin.destroy, self.ctx)
        if not ok then report('destroy failed for ' .. name .. ': ' .. tostring(err)) end
    end
    if plugin.export and rawequal(_G[plugin.export], plugin.object or plugin) then
        _G[plugin.export] = record.previousExport
    end
    return true
end

function PluginManager:setLayer(name, layer)
    local record = self.records[name]
    if not record or not validLayer(layer) then return false end
    record.plugin.layer = layer
    return not record.target or record.target:setLayer(record.proxy, layer)
end

function PluginManager:on(eventName, callback, pluginName)
    if type(eventName) ~= 'string' or type(callback) ~= 'function' then return false end
    self.sequence = self.sequence + 1
    local list = self.hooks[eventName] or {}
    self.hooks[eventName] = list
    list[#list + 1] = {pluginName = pluginName, callback = callback, order = self.sequence, active = true}
    return true
end

function PluginManager:emit(eventName, ...)
    local snapshot = {}
    for i, listener in ipairs(self.hooks[eventName] or {}) do snapshot[i] = listener end
    local function layer(listener)
        local plugin = self.plugins[listener.pluginName]
        return plugin and plugin.layer or math.huge
    end
    table.sort(snapshot, function(a, b)
        if layer(a) == layer(b) then return a.order < b.order end
        return layer(a) < layer(b)
    end)
    for _, listener in ipairs(snapshot) do
        if listener.active then
            local ok, err = pcall(listener.callback, self.ctx, ...)
            if not ok then report('hook ' .. eventName .. ': ' .. tostring(err)) end
        end
    end
end

-- 手动广播接口；普通生命周期已由 room/group 调用，不要再广播 update/draw 等。
function PluginManager:callAll(method, ...)
    local records = {}
    for _, record in pairs(self.records) do records[#records + 1] = record end
    table.sort(records, function(a, b)
        local al, bl = a.plugin.layer or math.huge, b.plugin.layer or math.huge
        if al == bl then return a.order < b.order end
        return al < bl
    end)
    for _, record in ipairs(records) do
        if record.active and type(record.proxy[method]) == 'function' then record.proxy[method](record.proxy, ...) end
    end
end
function PluginManager:getPluginNames()
    local names = {}
    for name in pairs(self.plugins) do names[#names + 1] = name end
    table.sort(names)
    return names
end
-- 按层和注册顺序审核；拒绝或审核异常时继续，已接收后的处理异常明确报错。
function PluginManager:dispatchImport(request)
    local records={}
    for _, record in pairs(self.records) do
        if record.active and record.plugin.type=='import' then records[#records+1]=record end
    end
    table.sort(records,function(a,b)
        local al,bl=a.plugin.layer or math.huge,b.plugin.layer or math.huge
        return al<bl or (al==bl and a.order<b.order)
    end)
    for _, record in ipairs(records) do
        local plugin=record.plugin
        local owner=plugin.object or self.ctx
        local reviewed,accepted=pcall(plugin.review,owner,request)
        if not reviewed then report(plugin.name..'.review: '..tostring(accepted)) end
        if reviewed and accepted==true and record.active then
            local ok,result=pcall(plugin.import,owner,request)
            if not ok then
                report(plugin.name..'.import: '..tostring(result))
                return nil,plugin.name..': '..tostring(result)
            end
            if type(result)~='table' then return nil,plugin.name..': import must return a table' end
            return result,nil,plugin.name
        end
    end
    return nil,'no import plugin accepted this file'
end

function PluginManager:getPlugin(name) return self.plugins[name] end
return PluginManager
