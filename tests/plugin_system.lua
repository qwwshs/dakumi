-- LuaJIT 5.1 回归：不启动游戏，不读写用户数据。
require('src.utils.room')
local manager = require('src.utils.plugin')
local count = 0
local function check(value, message)
    assert(value, message)
    count = count + 1
end
local calls = {}
local function mark(name) calls[#calls + 1] = name end
local function expect(value)
    check(table.concat(calls, ',') == value, table.concat(calls, ',') .. ' ~= ' .. value)
    calls = {}
end
local function item(name)
    return {__name = name, update = function() mark(name) end}
end

-- 游戏把全局 room 同时当根实例和原型，根排序缓存不能被子 room 继承。
local cacheScene = room:new('cache_scene')
cacheScene:addObject(item('cache_child'))
room:addRoom(cacheScene)
room:load('cache_scene')
room('update'); expect('cache_child')
room:deleteRoom(cacheScene)
room:load('')

local root = room:new('main')
local scene, inactive = room:new('edit'), room:new('menu')
local play = group:new('play')
local nested = group:new('nested')
root:addRoom(scene, 0)
root:addRoom(inactive, 0)
scene:addGroup(play, 10)
play:addGroup(nested, 15)
root:load('edit')
check(root:findContainer('main/edit/play/nested') == nested, 'absolute container path')
check(root:findContainer('edit/play') == play, 'relative container path')
check(root:findContainer('edit/missing') == nil, 'missing container')
local high, low, same = item('highest'), item('low'), item('same')
play:addObject(high)
play:addObject(low, -10)
play:addObject(same, -10)
nested:addObject(item('nested'))
inactive:addObject(item('inactive'))
root('update')
expect('low,same,nested,highest')
check(play:getLayer(high) == math.huge, 'default highest layer')
check(play.layers[-10][1].child == low, 'layers attribute')
check(not play:addObject(low), 'duplicate object is ignored')
play:setLayer(high, -20)
root('update')
expect('highest,low,same,nested')
play:setLayer(high)
play:deleteObject(low)
play:deleteObject('same')
root('update')
expect('nested,highest')
local other = group:new('other')
other:addObject(high, 2)
check(play:getLayer(high) == math.huge and other:getLayer(high) == 2, 'layers belong to mounts')

local mutation = group:new('mutation')
local victim, added = item('victim'), item('added')
mutation:addObject({update = function()
    mark('mutate')
    mutation:deleteObject(victim)
    mutation:addObject(added)
end})
mutation:addObject(victim)
mutation('update'); expect('mutate')
mutation('update'); expect('mutate,added')
check(not pcall(function() mutation:addObject({}, 'bad') end), 'invalid layer')

local loads = 0
nested:addObject({load = function() loads = loads + 1 end})
root:to('edit')
check(loads == 1, 'empty room/group forwards load')
function scene:update(dt) self('update', dt) end
root('update'); expect('nested,highest')
function scene:update(dt) if dt > 0 then self('update', dt) end end
root('update', 0); expect('')
scene.update = nil

log = function() end
manager:init({root = root, token = 'context'})
local descriptor = {
    name = 'example', target = 'edit/play', layer = 12,
    init = function(ctx) check(ctx.token == 'context', 'init context') end,
    update = function(ctx, dt)
        check(ctx.token == 'context' and dt == 0.25, 'callback arguments')
        mark('plugin')
    end,
    hooks = {onNoteAdd = function(ctx, note)
        check(note == 42 and ctx.token == 'context', 'hook arguments')
        mark('hook')
    end},
    destroy = function(ctx) check(ctx.token == 'context', 'destroy context') end,
}
check(manager:register(descriptor), 'register descriptor')
root('update', 0.25); expect('plugin,nested,highest')
manager:emit('onNoteAdd', 42); expect('hook')
check(not manager:register(descriptor), 'duplicate plugin rejected')
check(not manager:register({name = 'bad', target = 'missing'}), 'invalid target rejected')
check(not manager:register({name = 'bad', layer = 'bad'}), 'invalid plugin layer rejected')
manager:setLayer('example', 20)
root('update', 0.25); expect('nested,plugin,highest')
root:load('menu'); root('update', 0.25); expect('inactive')
root:load('edit')
check(manager:unregister('example'), 'unregister')
root('update', 0.25); expect('nested,highest')
manager:emit('onNoteAdd', 42); expect('')
check(not manager:register({name = 'broken', target = play,
    init = function() error('broken init') end}), 'init failure rolls back')
check(manager:getPlugin('broken') == nil and play:getObject('broken') == nil, 'rollback detaches')

local legacy = object:new('legacy')
legacy.plugin = {name = 'legacy', target = nested, layer = -1, export = 'testPluginExport'}
function legacy:update(dt) check(self == legacy and dt == 0.25, 'object self'); mark('legacy') end
check(manager:register(legacy), 'object registration')
check(testPluginExport == legacy, 'legacy export')
root('update', 0.25); expect('legacy,nested,highest')
manager:unregister('legacy')
check(testPluginExport == nil, 'export restored')
check(manager:register({name = 'fault', target = play, layer = -1,
    update = function() error('bad callback') end}), 'failing callback registered')
root('update', 0.25); expect('nested,highest')
manager:unregister('fault')

-- 钩子按照层号排序；卸载尚未执行的监听者时立即跳过。
manager:register({name = 'hookLate', target = play, layer = 20,
    hooks = {test = function() mark('late') end}})
manager:register({name = 'hookEarly', target = play, layer = 10,
    hooks = {test = function() mark('early'); manager:unregister('hookLate') end}})
manager:emit('test'); expect('early')
manager:unregister('hookEarly')

-- 使用文件系统替身验证真实加载器的目录发现、覆盖及错误隔离。
PATH = {plugins = 'plugins/', base = '/app'}
local external = {
    ['a.lua'] = "return {name='a', target='edit/play', layer=5, update=function() end}",
    ['pack/init.lua'] = "return {name='pack', target='edit/play/nested'}",
    ['bad.lua'] = "error('entry failure')",
    ['invalid.lua'] = 'return 42',
    ['disabled.lua'] = "return {name='disabled', enabled=false}",
    ['syntax.lua'] = 'this is not lua',
    ['metadata.lua'] = "return {plugin='invalid'}",
}
local bundled = {['a.lua'] = "error('external must override')",
    ['z.lua'] = "return {name='z', target='menu'}"}
nativefs = {
    read = function(path) return external[path:match('^/app/plugins/(.*)$')] end,
    getDirectoryItems = function() return {'a.lua', 'pack', 'bad.lua', 'invalid.lua', 'disabled.lua', 'syntax.lua', 'metadata.lua', '_helper.lua'} end,
}
love = {filesystem = {
    getSource = function() return '/app/game.love' end,
    isFused = function() return false end,
    read = function(path) return bundled[path:match('^plugins/(.*)$')] end,
    getDirectoryItems = function() return {'init.lua', 'a.lua', 'z.lua', 'README.md'} end,
}}
local result = require('plugins.init')(manager)
check(table.concat(result.loaded, ',') == 'a,pack,z', 'directory discovery and stable load order')
check(#result.errors == 4, 'bad entries isolated')
check(manager:getPlugin('disabled') == nil, 'disabled plugin skipped')
check(manager:getPlugin('pack').path == '/app/plugins/pack', 'plugin resource path')
check(nested:getObject('pack') ~= nil and inactive:getObject('z') ~= nil, 'arbitrary targets attached')
manager:init({root = root})
check(#manager:getPluginNames() == 0 and nested:getObject('pack') == nil, 'reinit unloads old mounts')
print('PASS: ' .. count .. ' plugin/layer checks')
