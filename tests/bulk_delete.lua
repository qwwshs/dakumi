-- 批量删除回归：相邻选中项、内容相同的不同对象、未选中项。
package.path = './?.lua;./?/init.lua;' .. package.path
WINDOW = { w = 1600, h = 900 }
require('src.utils.room')
require('src.utils.table')
require('src.utils.beat')
require('src.utils.math')
require('src.objects.meta')

local ChartService = require('src.services.chartService')
local Note = require('src.objects.Note')
local Event = require('src.objects.Event')
fNote = { sort = function() ChartService:sortNotes() end }
fEvent = { sort = function() ChartService:sortEvents() end }
redo = { writeRevoke = function() end, clear = function() end }
PluginManager = { emit = function() end }
sidebar = { to = function() end }
messageBox = { add = function() end }
iskeyboard = { ctrl = true }
mouse = { down = false }
local activeAction = 'deleteSelect'
input = function(action) return action == activeAction end
local ctrl = require('plugins.ctrl')
local clipboard = require('src.utils.clipboard')

local function note(beatValue)
    return Note.new({ track = 1, beat = { beatValue, 0, 1 } })
end
local function event(beatValue)
    return Event.new({ track = 1, beat = { beatValue, 0, 1 }, beat2 = { beatValue + 1, 0, 1 } })
end
local function reset()
    ChartService:setChart({ note = {}, event = {} })
    clipboard.tab = table.copy(clipboard.meta)
    clipboard.tab.pos = 'edit'
end

reset()
local a, b, c, untouched = note(1), note(1), note(2), note(3)
local x, y = event(1), event(1)
for _, item in ipairs({ a, b, c, untouched }) do ChartService:addNote(item) end
for _, item in ipairs({ x, y }) do ChartService:addEvent(item) end
for _, item in ipairs({ a, b, c }) do ctrl:copy_add(item, 'note') end
for _, item in ipairs({ x, y }) do ctrl:copy_add(item, 'event') end
assert(#clipboard.tab.note == 3 and #clipboard.tab.event == 2, '内容相同的对象应分别进入选区')
ctrl:keypressed('d')
assert(ChartService:getNoteCount() == 1 and rawequal(ChartService:getNote(1), untouched), '所有选中 note 应被删除')
assert(ChartService:getEventCount() == 0, '所有选中 event 应被删除')

reset()
a, b = note(1), note(1)
ChartService:addNote(a)
ChartService:addNote(b)
ctrl:copy_add(b, 'note')
ctrl:keypressed('d')
assert(ChartService:getNoteCount() == 1 and rawequal(ChartService:getNote(1), a), '只删除实际选中的同值对象')

reset()
a, b = note(1), note(2)
ChartService:addNote(a)
ChartService:addNote(b)
ctrl:copy_add(a, 'note')
ctrl:copy_add(b, 'note')
clipboard.tab.type = 'cut'
ctrl.getPasteItems = function() return { note = { a:copy(), b:copy() }, event = {} } end
activeAction = 'paste'
ctrl:keypressed('v')
assert(ChartService:getNoteCount() == 2, '剪切粘贴后音符总数应保持不变')
assert(not rawequal(ChartService:getNote(1), a) and not rawequal(ChartService:getNote(2), b), '剪切应删除全部原始音符')

reset()
a = note(1)
ChartService:addNote(a)
activeAction = 'select'
love = { mouse = { isDown = function(button) return button == 1 end } }
play = { layout = { edit = { x = 900, interval = 60 } } }
settings = { judge_line_y = 700 }
denom = { scale = 1 }
fTrack = {
    to_chart_track = function(_, x) return x end,
    to_play_track = function(_, x, w) return x, w end,
}
fEvent.get = function() return 150, 30 end
clipboard.mouse_start_pos = { x = 100, y = 600, down = true }
ctrl:mousereleased(200, 500)
assert(#clipboard.tab.note == 1 and rawequal(clipboard.tab.note[1], a), 'play 区域应能框选无事件轨道的音符')
print('bulk_delete: PASS')
