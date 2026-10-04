-- 撤销强制记录回归：任何谱面修改（含 setter/低层API/字段）都必须进撤销栈，
-- 调用方无法跳过；仅撤销回放与显式豁免区不产生记录。
package.path = './?.lua;./?/init.lua;' .. package.path
WINDOW = { w = 1600, h = 900 }
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
easings = require('src.utils.easings')
require('src.utils.bezier')
dkjson = require('src.utils.dkjson')
save = function() end
log = function() end
fNote = {sort = function() end}
fEvent = {sort = function() end}

local eventBus = require('src.utils.eventBus')
local ChartService = require('src.services.chartService')
local Event = require('src.objects.Event')
local Note = require('src.objects.Note')
redo = require('plugins.redo')

local function at(n) return {n, 0, 1} end
local function setup()
    ChartService:setChart({preference = {x_offset = 10, event_scale = 100}})
    ChartService:load()
    assert(#redo.revoke == 0)
end
local function lastAction() return redo.revoke[#redo.revoke] end

-- 1. 事务外的 setter 修改图谱面事件 → 自动成为一条记录，无法跳过
setup()
local e1 = Event.new({type = 'x', track = 1, beat = at(1), beat2 = at(3), from = 0, to = 100})
ChartService:add(e1, 'history.add_x_event')
local depth = #redo.revoke
e1:setFrom(50) -- 无事务、无 actionKey：也必须记录
assert(#redo.revoke == depth + 1, '事务外的 setter 必须自动入撤销栈')
assert(lastAction().action_key == 'history.other')
assert(#lastAction().del.event == 1 and #lastAction().add.event == 1, '内容变更应为 del旧+add新')
assert(lastAction().del.event[1]:getFrom() == 0 and lastAction().add.event[1]:getFrom() == 50)
assert(redo:undo() and ChartService:getEvent(1):getFrom() == 0, '撤销应恢复旧值')
assert(redo:redoOne() and ChartService:getEvent(1):getFrom() == 50, '重做应恢复新值')
e1 = ChartService:getEvent(1) -- 内容撤销按旧值副本恢复（对象替换，与既有语义一致）

-- 2. 谱面外副本（粘贴预览/编辑副本）的 setter 不产生记录
depth = #redo.revoke
local copy = e1:copy()
copy:setFrom(999)
assert(#redo.revoke == depth, '谱面外副本不应产生记录')

-- 3. change 手势：多次 setter 合并为一条记录
depth = #redo.revoke
ChartService:change('history.edit_event', function()
    e1:setFrom(10)
    e1:setTo(90)
    e1:setFrom(20)
end)
assert(#redo.revoke == depth + 1, '同一手势应合并为一条记录')
assert(lastAction().del.event[1]:getFrom() == 50 and lastAction().add.event[1]:getFrom() == 20,
    '快照应取事务前旧值（多次修改不叠加中间态）')
assert(redo:undo() and ChartService:getEvent(1):getFrom() == 50)

-- 4. 低层 API（addEvent/deleteEvent）在事务外调用也必须记录
setup()
local e2 = Event.new({type = 'w', track = 1, beat = at(2), beat2 = at(4), from = 0, to = 50})
ChartService:addEvent(e2, 'history.add_w_event')
assert(lastAction().action_key == 'history.add_w_event' and #lastAction().add.event == 1)
assert(ChartService:deleteEvent(e2, 'history.delete_w_event'))
assert(lastAction().action_key == 'history.delete_w_event' and #lastAction().del.event == 1)
assert(redo:undo() and ChartService:getEventCount() == 1, '低层删除可撤销')

-- 5. 事务内"添加后又删除"：两两相抵，不产生记录
setup()
depth = #redo.revoke
ChartService:push()
local e3 = Event.new({type = 'x', track = 1, beat = at(5), beat2 = at(6), from = 0, to = 10})
ChartService:add(e3)
ChartService:delete(e3)
ChartService:pop('history.nothing')
assert(#redo.revoke == depth, '添加又删除应相抵为无记录')

-- 6. 事务内"修改后又删除"：撤销应恢复事务前的旧状态
setup()
e1 = Event.new({type = 'x', track = 1, beat = at(1), beat2 = at(3), from = 0, to = 100})
ChartService:add(e1, 'history.add_x_event')
ChartService:push()
e1:setFrom(77)
ChartService:delete(e1)
ChartService:pop('history.modify_then_delete')
assert(redo:undo() and ChartService:getEventCount() == 1)
local restored = ChartService:getEvent(1)
assert(restored:getFrom() == 0, '撤销应恢复修改前旧值，而非删除时的中间值')

-- 7. 字段变更（offset/track 定义）强制记录并可撤销
setup()
depth = #redo.revoke
ChartService:setOffset(123)
assert(#redo.revoke == depth + 1 and #lastAction().fields_before > 0, 'offset 变更必须入栈')
assert(lastAction().fields_before[1].value == 0 and lastAction().fields_after[1].value == 123)
assert(ChartService:getOffset() == 123)
assert(redo:undo() and ChartService:getOffset() == 0, '撤销应恢复 offset')

depth = #redo.revoke
ChartService:change('history.edit_track', function()
    ChartService:setTrackField(2, 'name', 'test track')
    ChartService:setTrackField(2, 'parent', 1)
end)
assert(#redo.revoke == depth + 1, '同事务内多次字段修改合并为一条记录')
assert(#lastAction().fields_before == 1, '同一轨道合并为一份定义快照')
assert(lastAction().fields_before[1].value == nil, '快照应保留轨道尚未创建的状态')
assert(lastAction().fields_after[1].value.name == 'test track' and
    lastAction().fields_after[1].value.parent == 1, '回放值应为修改后的轨道定义')
assert(redo:undo())
assert(ChartService:getTrackField(2, 'name') == '' and ChartService:getTrackField(2, 'parent') == 0,
    '撤销应恢复轨道字段')

-- 7b. 标量字段（info 字符串 / preference 数字）的快照与撤销
setup()
local oldName = ChartService:getInfoField('song_name')
local oldPref = ChartService:getPreferenceField('x_offset')
depth = #redo.revoke
ChartService:change('history.edit_chart_info', function()
    ChartService:setInfoField('song_name', '新歌名')
    ChartService:setPreferenceField('x_offset', 55)
    ChartService:setOffset(123)
end)
assert(#redo.revoke == depth + 1, '谱面信息保存应产生一条记录')
assert(ChartService:getInfoField('song_name') == '新歌名', '保存应写入新值')
assert(redo:undo(), '撤销谱面信息')
assert(ChartService:getInfoField('song_name') == oldName, '撤销应恢复 info 字符串字段')
assert(ChartService:getPreferenceField('x_offset') == oldPref, '撤销应恢复 preference 数字字段')
assert(ChartService:getOffset() == 0, '撤销应恢复 offset')
assert(redo:redoOne() and ChartService:getInfoField('song_name') == '新歌名', '重做应恢复新值')

-- 8. 跨帧手势（beginChange/commitChange）合并为一条记录
setup()
e1 = Event.new({type = 'x', track = 1, beat = at(1), beat2 = at(3), from = 0, to = 100})
ChartService:add(e1, 'history.add_x_event')
depth = #redo.revoke
ChartService:beginChange()
e1:setFrom(11)
ChartService:commitChange('history.edit_event')
e1:setTo(88) -- 事务已提交，这条应单独成记录
assert(#redo.revoke == depth + 2)
assert(redo:undo() and ChartService:getEvent(1):getTo() == 100,
    '撤销第二条应回退 setTo')
assert(ChartService:getEvent(1):getFrom() == 11, '第一条已提交的修改不受影响')

-- 9. 撤销回放本身不产生新记录
setup()
e1 = Event.new({type = 'x', track = 1, beat = at(1), beat2 = at(3), from = 0, to = 100})
ChartService:add(e1, 'history.add_x_event')
ChartService:setOffset(50)
depth = #redo.revoke
assert(redo:undo())
assert(#redo.revoke == depth - 1, '回放应消耗记录')
assert(redo:redoOne())
assert(#redo.revoke == depth, '回放不追加记录')
assert(ChartService:getOffset() == 50 and ChartService:getEventCount() == 1, '回放结果正确')

-- 10. push/pop 批量与内容修改混合仍是一条记录
setup()
e1 = Event.new({type = 'x', track = 1, beat = at(1), beat2 = at(3), from = 0, to = 100})
ChartService:add(e1, 'history.add_x_event')
depth = #redo.revoke
ChartService:push()
ChartService:add(Note.new({track = 1, beat = at(1)}))
e1:setFrom(33)
ChartService:pop('history.mixed')
assert(#redo.revoke == depth + 1, '批量增删+内容修改合并为一条记录')
local op = lastAction()
assert(#op.add.note == 1 and #op.add.event == 1 and #op.del.event == 1,
    '记录应同时含音符添加与事件内容变更')
assert(op.del.event[1]:getFrom() == 0 and op.add.event[1]:getFrom() == 33)
assert(redo:undo() and ChartService:getNoteCount() == 0 and
    ChartService:getEvent(1):getFrom() == 0, '批量撤销应同时回退结构与内容')

print('PASS: enforced undo recording (setters/low-level/fields/replay exempt/batch merge)')
