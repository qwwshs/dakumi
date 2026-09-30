-- 从多标签页回到单标签页时，复制表改为 demo 区域的跨轨道规则。
package.path = './?.lua;./?/init.lua;' .. package.path
WINDOW = { w = 1600, h = 900 }
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.utils.beat')
require('src.objects.meta')

local Note = require('src.objects.Note')
local Event = require('src.objects.Event')
local font = { setFilter = function() end }
love = { graphics = { newFont = function() return font end } }
package.loaded['src.objects.play.demoInEdit'] = { new = function() return {} end }
play = { layout = { x = 0, w = 1200, y = 192, edit = { x = 900, w = 300 }, demo = { w = 900 } } }
track = { track = 9 }
settings = { judge_line_y = 700 }
denom = { scale = 1, denom = 4 }
mouse = { y = 700 }
messageBox = { add = function() end }

ctrl = require('plugins.ctrl')
local clipboard = require('src.utils.clipboard')
local tabs = require('src.rooms.tabs')
tabs:load()
tabs:addTab()
tabs:addTab()

local note = Note.new({ track = 2, beat = { 1, 0, 1 } })
local event = Event.new({ track = 4, type = 'x', beat = { 2, 0, 1 }, beat2 = { 3, 0, 1 } })
clipboard.tab = {
    note = { note }, event = { event },
    note_tracks = { 2 }, event_tracks = { 4 },
    note_tabidx = { 1 }, event_tabidx = { 3 },
    type = 'cut', pos = 'tabs',
}

tabs:closeTab(2)
assert(clipboard.tab.pos == 'tabs', '仍有多个标签页时不应转换复制表')
tabs:closeTab(2)
assert(clipboard.tab.pos == 'play', '单标签页应改为 demo 区域复制表')
assert(clipboard.tab.type == 'cut' and rawequal(clipboard.tab.note[1], note) and
    rawequal(clipboard.tab.event[1], event), '复制内容和剪切状态应保留')
assert(#clipboard.tab.note_tabidx == 0 and #clipboard.tab.event_tabidx == 0, '旧标签页下标应清除')

local items = ctrl:getPasteItems(false, true)
assert(items.note[1]:getTrack() == 2 and items.event[1]:getTrack() == 4,
    '单标签页粘贴应保留原轨道，而非改到当前编辑轨道')
print('tab_clipboard: PASS')
