-- 移除全局 UI 后，插件的侧栏和事件右键菜单仍可通过注入上下文绘制。
require('src.utils.room')
local function block() error('不得读取全局 UI 或翻译器') end
Nui = setmetatable({}, {__index = block})
i18n = setmetatable({}, {__index = block})
love = {mouse = {isDown = function() return false end}}
package.loaded['src.services.audioService'] = {}
local event = {getBeat = function() return 0 end, getBeat2 = function() return 1 end,
    getFrom = function() return 0 end, getTo = function() return 1 end,
    getTransType = function() return 'easings' end}
package.loaded['src.services.chartService'] = {getEvent = function() return event end}
package.loaded['src.services.coordinateService'] = {toY = function(_, b) return b end}
fTrack = {to_play_track_x = function(_, x) return x end}
play = {layout = {demo = {x = 0, w = 100}}}
tabs = {isSingle = function() return true end, layout = {region = {y = 0, h = 100}}}
sidebar = {displayed_content = 'event', incoming = {1}, to = function() end}
local calls = {}
local ui
ui = setmetatable({}, {__index = function(_, method)
    return function(self, ...)
        assert(self == ui, 'UI 接收者必须是注入对象')
        calls[method] = (calls[method] or 0) + 1
        if method == 'slider' then local _, value = ...; return type(value) == 'number' and value or false end
        return method == 'windowBegin' or method == 'contextualBegin'
    end
end})
local context = {ui = ui, i18n = {get = function(_, key) return key end}}
local home = group:new('nil')
local host = room:new('sidebar')
host:addGroup(home)
context.root = {findContainer = function() return host end}
for _, name in ipairs({'equalizer', 'takana'}) do
    local plugin = require('plugins.' .. name .. '.init')
    plugin.init(context)
    local pane = host:getGroup(name)
    assert(pane, name .. ' 侧栏注册失败')
    pane:Nui()
    assert(calls.label and calls.slider)
    plugin.destroy(context)
    assert(not host:getGroup(name), name .. ' 侧栏卸载失败')
end
local direct = require('plugins.directEventEditing')
direct.plugin.init(context)
direct.open = true
direct:update(0)
assert(calls.contextualItem == 3 and calls.windowEnd == 1, '事件菜单没有使用注入 UI')
direct.plugin.destroy(context)
print('PASS: 三个插件独立 UI 上下文与侧栏卸载')
