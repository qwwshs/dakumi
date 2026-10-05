-- 元件毫秒偏移：BPM 变化、事件组、撤销、保存、排序和输入限制的内存回归。
WINDOW = {w = 1600, h = 900}
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
easings = require('src.utils.easings')
require('src.utils.bezier')
dkjson = require('src.utils.dkjson')
log = function() end
save = function() error('不得写入用户数据') end
fNote = {sort = function() end}
local Chart = require('src.services.chartService')
local Note = require('src.models.Note')
local Event = require('src.models.Event')
local Offset = require('src.utils.timeOffset')
fEvent = require('src.utils.event')
fEvent:init({chart = Chart, event = Event, coordinates = require('src.services.coordinateService')})
redo = require('plugins.redo')
local function at(n) return {n, 0, 1} end
local function near(actual, expected) assert(math.abs(actual-expected) < 1e-8, tostring(actual)..' ~= '..tostring(expected)) end
local function setup(list)
    sidebar = nil
    Chart:setChart({bpm_list = list or {{beat=at(0),bpm=60,linear_ramp=0}}})
    Chart:load()
end
setup({{beat=at(0),bpm=120,linear_ramp=0},{beat=at(2),bpm=60,linear_ramp=0}})
for _, kind in ipairs({'note','wipe','hold'}) do
    local note = Note.new({type=kind,beat=at(1),beat2=kind=='hold' and at(3) or nil,time_offset=750})
    near(note:getBeatValue(), 2.25)
    near(Chart:toTime(note:getBeatValue()), Chart:toTime(note:getBeat())+0.75)
    assert(note:getBeat()[1] == 1, '基础节拍不能被覆盖')
    if kind=='hold' then
        near(Chart:toTime(note:getBeat2Value())-Chart:toTime(note:getBeatValue()),1.5)
    end
    local restored = Note.new(dkjson.decode(dkjson.encode(note)))
    assert(restored:eq(note) and restored:getTimeOffset()==750 and note:copy():eq(note))
end
local ramp = {{beat=at(0),bpm=120,linear_ramp=1},{beat=at(8),bpm=240,linear_ramp=0}}
Chart:setBpmList(ramp)
local hold = Note.new({type='hold',beat=at(2),beat2=at(9),time_offset=350})
near(Chart:toTime(hold:getBeatValue())-Chart:toTime(hold:getBeat()),0.35)
near(Chart:toTime(hold:getBeat2Value())-Chart:toTime(hold:getBeat2()),0.35)
near(beat:get(Offset.baseBeat(hold:getBeatValue(),350)),2)
for _, factory in ipairs({Note,Event}) do
    local item = factory.new({beat=at(1),beat2=at(2)})
    assert(item:getTimeOffset()==0 and item:toTable().time_offset==nil)
    for _, invalid in ipairs({0,-1,math.huge,-math.huge,0/0,'12'}) do
        assert(not pcall(function() item:setTimeOffset(invalid) end))
        assert(item:getTimeOffset()==0)
        assert(factory.new({time_offset=invalid}):getTimeOffset()==0)
    end
    item:setTimeOffset(0.01)
    assert(item:getTimeOffset()==0.01 and not item:eq(factory.new({beat=at(1),beat2=at(2)})))
    item:setTimeOffset(nil)
    assert(item:getTimeOffset()==0)
end
setup()
local first = Note.new({beat=at(1)})
local second = Note.new({beat=at(2)})
Chart:add(first); Chart:add(second)
sidebar = {displayed_content='note', incoming={1}, to=function() end}
require('src.objects.sidebar.chart_notifications')(sidebar, Chart, require('src.utils.eventBus'))
Chart:change('history.edit_note',function() first:setTimeOffset(2000) end)
assert(Chart:getNote(1)==second and Chart:getNote(2)==first and sidebar.incoming[1]==2)
assert(redo:undo() and Chart:getNote(1):getTimeOffset()==0)
assert(redo:redoOne() and Chart:getNote(2):getTimeOffset()==2000)
local history = redo.revoke[#redo.revoke]
near(history.beat_start,1); near(history.beat_end,3)
-- 改 BPM 后按实际时间重新排序，不留下旧索引。
Chart:setBpmList({{beat=at(0),bpm=30,linear_ramp=0}})
near(Chart:getNote(2):getBeatValue(),2)
setup()
local plain = Event.new({type='x',beat=at(0),beat2=at(2),from=0,to=100,time_offset=500,
    trans={type='easings',easings=1,trans={0,0,1,1}}})
Chart:add(plain)
near(fEvent:get(1,0.25),0)
near(fEvent:get(1,1.5),50)
near(fEvent:get(1,2.5),100)
assert(Event.new(dkjson.decode(dkjson.encode(plain))):eq(plain))
setup()
local function inner(kind, offset, finish)
    return {type=kind,beat=at(0),beat2=at(finish),from=0,to=100,time_offset=offset,
        trans={type='easings',easings=1,trans={0,0,1,1}}}
end
assert(Chart:putEventGroup('偏移组',{event={inner('x',1000,2),inner('w',nil,3)}}))
local group = Event.new({type='event_group',event_group='偏移组',beat=at(10),beat2=at(13),
    from=0,to=100,time_offset=500})
Chart:add(group)
near(group:getBeatValue(),10.5); near(group:getBeat2Value(),13.5)
near(fEvent:get(1,12.5,true),50)
assert(not Chart:canPlaceEvent(Event.new({type='w',beat=at(13),beat2=at(14)})))
assert(Chart:canPlaceEvent(Event.new({type='w',beat=at(13),beat2=at(14),time_offset=500})))
assert(Chart:beginEventGroupEdit('偏移组'))
local innerOffset
for i=1,Chart:getEventCount() do
    local e=Chart:getEvent(i)
    if e:getType()=='x' then innerOffset=e; assert(e:getTimeOffset()==1000) end
end
innerOffset:setTimeOffset(1500)
local snapshot=assert(Chart:copyEditingGroupEvents())
assert(snapshot[1].time_offset==1500 or snapshot[2].time_offset==1500)
assert(Chart:finishEventGroupEdit())
local definition=Chart:getEventGroup('偏移组')
assert(definition.event[1].time_offset==1500 or definition.event[2].time_offset==1500)
-- 侧栏禁止非正数和事件组重叠，清空输入可取消偏移。
local Field=require('src.objects.timeOffsetField')
local field=Field.new()
local outside=Event.new({type='w',beat=at(8),beat2=at(10)})
Chart:add(outside)
field:load(outside); field.value='1000'
assert(not field:apply(outside,Chart) and outside:getTimeOffset()==0 and field.error=='time_offset_overlap')
for _, value in ipairs({'0','-1','nan','1e309','abc'}) do
    field.value=value
    assert(not field:apply(outside,Chart) and outside:getTimeOffset()==0)
end
field.value='0.5'; assert(field:apply(outside,Chart)); near(outside:getTimeOffset(),0.5)
field.value=''; assert(field:apply(outside,Chart)); assert(outside:getTimeOffset()==0)
-- 拷贝与组序列化均保留毫秒值，非法组内字段不接受。
assert(not Chart:putEventGroup('非法',{event={inner('x',-1,2)}}))
-- 粘贴保持基础节拍间距与偏移；实际排序反转时也不选错锚点。
setup()
settings = {judge_line_y=700}
denom = {scale=1,denom=4}
mouse = {y=-1300}
track = {track=1}
local clipboard=require('src.utils.clipboard')
local ctrl=require('plugins.ctrl')
clipboard.tab=table.copy(clipboard.meta)
clipboard.tab.pos='edit'
clipboard:add(Note.new({beat=at(1),time_offset=2000}), 'note')
clipboard:add(Note.new({beat=at(2)}), 'note')
local anchor=beat:get(beat:toNearby(require('src.services.coordinateService'):yToBeat(mouse.y)))
local pasted=ctrl:getPasteItems(false,true)
assert(#pasted.note==2)
for _, n in ipairs(pasted.note) do
    if n:getTimeOffset()>0 then near(n:getBeatValue(),anchor+2); near(beat:get(n:getBeat()),anchor)
    else near(n:getBeatValue(),anchor+1) end
end
print('PASS: 正数毫秒偏移、变速 BPM、hold 时长、事件插值、组内与实例偏移、互斥、保存、撤销、排序和侧栏校验')
