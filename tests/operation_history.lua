-- 操作历史回归：只使用内存谱面，不启动游戏或写入用户数据。
require('src.utils.room')
require('src.utils.table')

beat = {get = function(_, value) return value[1] + value[2] / value[3] end}
event_type = {'x', 'w', 'lpos', 'rpos'}
meta_chart = {__index = {
    note = {}, event = {}, bpm_list = {}, track = {}, effect = {},
    info = {}, preference = {},
}}
meta_extra_chart_track = {x = {}, w = {}, lpos = {}, rpos = {}, note = {}}
fNote = {sort = function() end}
fEvent = {sort = function() end}
sidebar = {displayed_content = 'operation history', to = function(self, name)
    self.displayed_content = name
end}

local Note = require('src.objects.Note')
local Event = require('src.objects.Event')
local chart = require('src.services.chartService')
redo = require('plugins.redo')

local function check(value, message) assert(value, message) end
local function near(a, b) return math.abs(a - b) < 0.000001 end

chart:setChart({note = {}, event = {}, track = {}})
local hold = Note.new({type = 'hold', track = 1, beat = {2, 0, 1}, beat2 = {5, 0, 1}})
chart:add(hold, 'history.add_hold')
check(#redo.revoke == 1 and redo.revoke[1].action_key == 'history.add_hold', 'single action')
check(near(redo.revoke[1].beat_start, 2) and near(redo.revoke[1].beat_end, 5), 'hold range')

local early = Note.new({type = 'note', track = 1, beat = {1, 1, 4}})
local event = Event.new({type = 'x', track = 1, beat = {6, 0, 1}, beat2 = {9, 1, 2}})
chart:push()
chart:add(early)
chart:add(event)
chart:pop('history.paste')
local timeline, cursor = redo:getHistory()
check(#timeline == 2 and cursor == 2 and timeline[2].action_key == 'history.paste', 'batch action')
check(near(timeline[2].beat_start, 1.25) and near(timeline[2].beat_end, 9.5), 'batch range')

check(redo:jumpTo(0), 'jump to initial state')
check(chart:getNoteCount() == 0 and chart:getEventCount() == 0, 'initial chart contents')
check(sidebar.displayed_content == 'operation history', 'panel remains visible')
timeline, cursor = redo:getHistory()
check(#timeline == 2 and cursor == 0 and timeline[1].action_key == 'history.add_hold', 'undone entries remain')
check(redo:jumpTo(2), 'jump to latest state')
check(chart:getNoteCount() == 2 and chart:getEventCount() == 1, 'latest chart contents')
check(redo:jumpTo(1), 'jump to intermediate state')
check(chart:getNoteCount() == 1 and chart:getEventCount() == 0, 'intermediate chart contents')

chart:add(Note.new({type = 'note', track = 1, beat = {7, 0, 1}}), 'history.add_note')
timeline, cursor = redo:getHistory()
check(#timeline == 2 and cursor == 2 and #redo.redo == 0, 'new action replaces undone future')
check(timeline[2].action_key == 'history.add_note', 'new action label')
chart:push()
chart:pop('history.batch_delete')
check(#redo.revoke == 2, 'empty batch is not recorded')

-- 插件入口在侧边栏首页出现，条目显示说明和范围，点击可跳转。
local root = room:new('main')
local edit = room:new('edit')
local side = group:new('sidebar')
local home = group:new('nil')
root:addRoom(edit)
edit:addGroup(side)
side:addGroup(home)
side.displayed_content = 'nil'
function side:to(name) self.displayed_content = name end
local labels, buttons, click = {}, {}, nil
local ui = {
    layoutRow = function() end,
    label = function(_, value) labels[#labels + 1] = value end,
    button = function(_, value)
        buttons[#buttons + 1] = value
        return click and value:find(click, 1, true) ~= nil
    end,
}
local zh = require('i18n.zh-CN')
local plugin = dofile('plugins/operationHistory.lua')
plugin.init({root = root, ui = ui, i18n = {get = function(_, key) return zh[key] or key end}})
click = '操作历史'
home('Nui')
check(side.displayed_content == 'operation history', 'sidebar navigation')
click = nil
side:getGroup('operation history'):Nui()
check(table.concat(buttons, ' '):find('放置 hold', 1, true), 'localized operation shown')
check(table.concat(labels, ' '):find('2–5', 1, true), 'beat range shown')
click = '1. 放置 hold'
side:getGroup('operation history'):Nui()
check(#redo.revoke == 1 and chart:getNoteCount() == 1, 'click jumps to selected step')
plugin.destroy({})
check(side:getGroup('operation history') == nil and home:getObject('operation history navigation') == nil,
    'plugin cleans up its sidebar content')

chart:setChart({note = {}, event = {}, track = {}})
check(#redo.revoke == 0 and #redo.redo == 0, 'switching charts clears history')
local oldEvent = Event.new({type = 'x', track = 1, beat = {2, 0, 1}, beat2 = {4, 0, 1}})
chart:add(oldEvent, 'history.add_x_event')
local movedEvent = oldEvent:copy()
movedEvent:setBeat({1, 0, 1})
movedEvent:setBeat2({6, 0, 1})
chart:push()
chart:add(movedEvent)
chart:delete(oldEvent)
chart:pop('history.move_event_start')
check(near(redo.revoke[2].beat_start, 1) and near(redo.revoke[2].beat_end, 6),
    'editing range includes both previous and new endpoints')
print('PASS: operation history, ranges, jumps, pruning, sidebar plugin')
