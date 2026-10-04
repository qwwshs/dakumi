-- 事件右键菜单：三类过渡、定义选择、空库回退及撤销均走真实服务。
WINDOW = {w = 1600, h = 900}
log = function() end
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
easings = require('src.utils.easings')
local Chart = require('src.services.chartService')
local redo = require('plugins.redo')
local Custom = require('src.utils.customTransition')
package.loaded['src.services.coordinateService'] = {toY = function(_, b) return b end}
love = {mouse = {isDown = function() return false end}}
fTrack = {to_play_track_x = function(_, x) return x end}
fEvent = {bezier = {{0, 0, 1, 1}}, sort = function() Chart:sortEvents() end}
fNote = {sort = function() Chart:sortNotes() end}
transIndex = {bezier = 1, easings = 1}
play = {layout = {demo = {x = 0, w = 100}}}
tabs = {isSingle = function() return true end, layout = {region = {y = 0, h = 100}}}
sidebar = {displayed_content = 'event', incoming = {1}, to = function() end}
local selected
local ui = setmetatable({}, {__index = function(_, method)
    return function(_, label)
        if method == 'contextualItem' then return label == selected end
        return method == 'windowBegin' or method == 'contextualBegin'
    end
end})
local direct = require('plugins.directEventEditing')
direct.plugin.init({ui = ui, i18n = {get = function(_, key) return key end}})
direct.open = true
local function load(definitions)
    Chart:setChart({custom_trans = definitions, event = {{type = 'x', track = 1,
        beat = {0, 0, 1}, beat2 = {2, 0, 1}, from = 0, to = 100,
        trans = {type = 'bezier', trans = {0, 0, 1, 1}, easings = 1}}}})
    Chart:load()
end
local function click(label)
    selected = label
    direct:update(0)
    selected = nil
    return Chart:getEvent(1)
end
load({alpha = 'return t*t', beta = 'return t'})
assert(click('switch trans type'):getTransType() == 'easings')
local event = click('switch trans type')
assert(event:getTransType() == 'custom' and event:getCustomTrans() == 'alpha')
assert(Custom.evaluate(event:getCustomTrans(), 0.5) == 0.25)
assert(click('switch the curve to the next type'):getCustomTrans() == 'beta')
assert(redo:undo() and Chart:getEvent(1):getCustomTrans() == 'alpha')
assert(redo:redoOne() and Chart:getEvent(1):getCustomTrans() == 'beta')
assert(click('switch the curve back to the previous type'):getCustomTrans() == 'alpha')
assert(click('switch the curve back to the previous type'):getCustomTrans() == 'alpha')
assert(click('switch trans type'):getTransType() == 'bezier')
click('switch trans type')
assert(click('switch trans type'):getCustomTrans() == 'alpha')
load({})
click('switch trans type')
event = click('switch trans type')
assert(event:getTransType() == 'custom' and event:getCustomTrans() == '')
assert(Custom.evaluate(event:getCustomTrans(), 0.5) == 0.5)
assert(click('switch the curve to the next type'):getCustomTrans() == '')
assert(click('switch the curve back to the previous type'):getCustomTrans() == '')
direct.plugin.destroy()
print('PASS: direct event transition types, custom selection, empty library and undo/redo')
