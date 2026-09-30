-- 事件总栈回归：服务层只广播 chart:* 领域事件，撤销插件经事件总栈订阅，双方互不直接引用。
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
redo = require('plugins.redo') -- 模块加载即订阅事件总栈

-- 1. 总栈基础行为：订阅/退订/同步分发/错误隔离
local hits = {}
local off = eventBus:on('test:ping', function(v) hits[#hits + 1] = v end)
assert(eventBus:count('test:ping') == 1)
assert(eventBus:emit('test:ping', 'a') == true)
off()
assert(eventBus:emit('test:ping', 'b') == false, '退订后 emit 应视为无订阅者')
assert(hits[1] == 'a' and hits[2] == nil)

eventBus:on('test:boom', function() error('boom') end)
eventBus:on('test:boom', function() hits[#hits + 1] = 'survived' end)
assert(eventBus:emit('test:boom') == true)
assert(hits[2] == 'survived', '单个回调出错不应影响其它订阅者')
eventBus:clear('test:boom')
assert(eventBus:count('test:boom') == 0)

-- 2. 单元素增删 → chart:committed → 撤销记录
local function at(n) return {n, 0, 1} end
ChartService:setChart({preference = {x_offset = 10, event_scale = 100}}) -- 广播 chart:replaced → redo:clear
ChartService:load()
assert(#redo.revoke == 0 and #redo.redo == 0)

local e1 = Event.new({type = 'x', track = 1, beat = at(1), beat2 = at(3), from = 0, to = 100})
assert(ChartService:add(e1, 'history.add_x_event') ~= false)
assert(#redo.revoke == 1 and redo.revoke[1].action_key == 'history.add_x_event')
assert(#redo.revoke[1].add.event == 1 and #redo.revoke[1].del.event == 0)
assert(ChartService:delete(e1, 'history.delete_x_event') ~= false)
assert(#redo.revoke == 2 and #redo.revoke[2].del.event == 1)
assert(redo:undo() and ChartService:getEventCount() == 1, '撤销删除应恢复事件')
assert(redo:undo() and ChartService:getEventCount() == 0, '撤销添加应移除事件')
assert(redo:redoOne() and ChartService:getEventCount() == 1, '重做添加')
assert(redo:redoOne() and ChartService:getEventCount() == 0, '重做删除')

-- 3. 批量提交：push 期间缓冲，pop 时只产生一条记录
ChartService:push()
ChartService:add(Event.new({type = 'w', track = 1, beat = at(1), beat2 = at(2), from = 0, to = 50}))
ChartService:add(Note.new({track = 1, beat = at(1)}))
assert(#redo.revoke == 2, 'push 期间不应写撤销记录')
ChartService:pop('history.bulk_bus')
assert(#redo.revoke == 3 and #redo.revoke[3].add.event == 1 and #redo.revoke[3].add.note == 1)
assert(redo:undo() and ChartService:getEventCount() == 0 and ChartService:getNoteCount() == 0,
    '批量撤销应同时回退事件与音符')

-- 4. 事件组编辑：撤销栈挂起/恢复，组定义变更单独成记录
assert(ChartService:putEventGroup('组', {event = {
    {type = 'x', beat = at(0), beat2 = at(2), from = 0, to = 50,
        trans = {type = 'easings', easings = 1, trans = {0, 0, 1, 1}}},
}}, nil, 'history.add_event_group'))
local mainDepth = #redo.revoke
assert(ChartService:beginEventGroupEdit('组'))
assert(#redo.revoke == 0, '进入组编辑后撤销栈应为空（已挂起）')
assert(ChartService:add(Event.new({type = 'x', track = 1, beat = at(0), beat2 = at(1),
    from = 0, to = 10}), 'history.add_x_event') ~= false)
assert(#redo.revoke == 1, '组内编辑写入独立撤销栈')
assert(ChartService:finishEventGroupEdit())
assert(#redo.revoke == mainDepth + 1, '退出后恢复主栈并追加一条组编辑记录')
assert(redo.revoke[#redo.revoke].action_key == 'history.edit_event_group')
assert(#ChartService:getEventGroup('组').event == 2, '组内新增应同步回组定义')
assert(redo:undo() and #ChartService:getEventGroup('组').event == 1, '撤销组编辑应还原组定义')
assert(redo:redoOne() and #ChartService:getEventGroup('组').event == 2)

-- 5. 整谱替换 → chart:replaced → 撤销/重做栈清空
ChartService:setChart({})
ChartService:load()
assert(#redo.revoke == 0 and #redo.redo == 0, '整谱替换后撤销/重做栈应清空')

print('PASS: event bus decoupling, suspend/resume, committed records, replace clear')
