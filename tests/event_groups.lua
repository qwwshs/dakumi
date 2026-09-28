-- 事件组计算、互斥和撤销回归；所有谱面数据只保存在内存。
WINDOW = {w = 1600, h = 900}
require('src.utils.room')
require('src.utils.table')
require('src.objects.meta')
require('src.utils.beat')
easings = require('src.utils.easings')
require('src.utils.bezier')
dkjson = require('src.utils.dkjson')
local savedChart
save = function(data) savedChart = dkjson.decode(dkjson.encode(data)) end
log = function() end
fNote = {sort = function() end, holdCleanUp = function() end}
local ChartService = require('src.services.chartService')
fEvent = require('src.utils.event')
redo = require('plugins.redo')
local Event = require('src.objects.Event')
local groupSidebar = require('src.objects.sidebar.event_groups')

local function at(n) return {n, 0, 1} end
local function inner(kind, from, to, startBeat, endBeat)
    return {type = kind, beat = at(startBeat), beat2 = at(endBeat),
        from = from, to = to,
        trans = {type = 'easings', easings = 1, trans = {0, 0, 1, 1}}}
end
local function near(actual, expected)
    assert(math.abs(actual - expected) < 0.00001,
        tostring(actual) .. ' ~= ' .. tostring(expected))
end

ChartService:setChart({preference = {x_offset = 10, event_scale = 100}})
ChartService:load()
assert(ChartService:putEventGroup('移动', {event = {
    inner('x', 10, 110, 2, 4), inner('w', 0, 100, 2, 4),
}}, nil, 'history.add_event_group'))
assert(ChartService:getEventGroup('移动').event[1].from == 10)
local instance = Event.new({type = 'event_group', track = 1, beat = at(10), beat2 = at(14),
    from = 50, to = 150, event_group = '移动'})
assert(ChartService:add(instance) ~= false)
local x, w = fEvent:get(1, 12, true)
near(x, 100)
near(w, 100)
near(select(1, fEvent:get(1, 14, true)), 150)

local ordinary = Event.new({type = 'x', track = 1, beat = at(11), beat2 = at(12)})
assert(ChartService:add(ordinary) == false)
local anotherGroup = Event.new({type = 'event_group', track = 1, beat = at(12), beat2 = at(15)})
assert(ChartService:add(anotherGroup) == false)
ordinary:setBeat(at(14))
ordinary:setBeat2(at(15))
assert(ChartService:add(ordinary) ~= false)
near(select(1, fEvent:get(1, 14, true)), 0)

instance:setFlipHorizontally(1)
x, w = fEvent:get(1, 11, true)
near(x, 125)
near(w, 75)
instance:setFlipHorizontally(0)
instance:setFlipVertically(1)
near(select(1, fEvent:get(1, 11, true)), 125)
instance:setFlipVertically(0)

assert(ChartService:putEventGroup('新名字', ChartService:getEventGroup('移动'),
    '移动', 'history.rename_event_group'))
assert(instance:getEventGroup() == '新名字')
redo:undo()
assert(ChartService:getEventGroup('移动') and not ChartService:getEventGroup('新名字'))
assert(ChartService:getEvent(1):getEventGroup() == '移动')
redo:redoOne()
assert(ChartService:getEvent(1):getEventGroup() == '新名字')
assert(ChartService:deleteEventGroup('新名字'))
near(select(1, fEvent:get(1, 12, true)), 100)
assert(dkjson.decode(ChartService:encodeJson()).event[1].event_group == '新名字')
assert(not ChartService:putEventGroup('bad/name', {event = {}}))

assert(ChartService:putEventGroup('编辑', {event = {
    inner('x', 20, 40, 0, 2), inner('w', 30, 30, 0, 2),
}}))
assert(ChartService:putEventGroup('不相关', {event = {
    inner('x', 0, 100, 100, 102),
}}))
sidebar = {displayed_content = 'event groups', getGroup = function() return groupSidebar end,
    to = function(self, name) self.displayed_content = name end}
track = require('src.objects.editTool.track')
track:to('track', 4)
play = {now_all_track_pos = {old = true}, effect = {old = true},
    get_init_effect = function() return {} end}
ctrl = {meta_copy_tab = {event = {}, note = {}}, copy_tab = {event = {'main'}},
    mouse_start_pos = {down = true}}
local mainClipboard = ctrl.copy_tab
local mainCount = ChartService:getEventCount()
local mainHistory = #redo.revoke
assert(groupSidebar:selectGroup('编辑'))
assert(groupSidebar.nameInput.value == '编辑')
assert(ChartService:isEditingEventGroup() == '编辑' and track.track == 1)
love = {graphics = {newFont = function() return {setFilter = function() end} end}}
local tabs = require('src.rooms.tabs')
tabs.list = {{track = 0}, {track = 2}}
assert(tabs:isSingle(), 'group editing should ignore existing tabs')
assert(ChartService:getEventCount() == 2 and ChartService:getNoteCount() == 0)
assert(#redo.revoke == 0 and ctrl.copy_tab ~= mainClipboard and not ctrl.mouse_start_pos.down)
assert(not ChartService:canPlaceEvent(Event.new({type = 'event_group', track = 1,
    beat = at(3), beat2 = at(4)})))
local added = Event.new(inner('lpos', 3, 8, 3, 4))
assert(ChartService:add(added, 'history.add_lpos_event') ~= false)
assert(ChartService:getEventCount() == 3 and #redo.revoke == 1)
assert(redo:undo() and ChartService:getEventCount() == 2)
assert(redo:redoOne() and ChartService:getEventCount() == 3)
ChartService:push()
ChartService:delete(ChartService:getEvent(1), 'history.delete_x_event')
ChartService:pop('history.bulk_delete')
assert(ChartService:getEventCount() == 2)
assert(redo:undo() and ChartService:getEventCount() == 3)
assert(ChartService:save('chart.json'))
assert(#savedChart.event == mainCount and #savedChart.event_groups['编辑'].event == 3)
assert(groupSidebar:exitGroup(true))
assert(not ChartService:isEditingEventGroup() and track.track == 4)
assert(not tabs:isSingle(), 'tabs should return after group editing')
assert(ChartService:getEventCount() == mainCount and ctrl.copy_tab == mainClipboard)
assert(#redo.revoke == mainHistory + 1)
assert(redo.revoke[#redo.revoke].beat_start == 0 and
    redo.revoke[#redo.revoke].beat_end == 4)
assert(redo:undo() and #ChartService:getEventGroup('编辑').event == 2)
assert(redo:redoOne() and #ChartService:getEventGroup('编辑').event == 3)

assert(groupSidebar:selectGroup('编辑'))
track:to('track', 5)
assert(not ChartService:isEditingEventGroup() and track.track == 5)
assert(ChartService:getEventCount() == mainCount)
assert(groupSidebar:selectGroup('编辑'))
track.track = 6
groupSidebar:update()
assert(not ChartService:isEditingEventGroup() and track.track == 6)
assert(track.useToTrack.value == '6')
print('PASS: event groups, dedicated editing, save, track exit and undo')
