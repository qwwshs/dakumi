-- 初始轨道值与普通事件共用两属性合并；覆盖六种组合、索引回退与撤销。
WINDOW={w=1600,h=900}
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
easings=require('src.utils.easings')
require('src.utils.bezier')
log=function() end
dkjson=require('src.utils.dkjson')
fNote={sort=function() end}
local Chart=require('src.services.chartService')
local Event=require('src.models.Event')
fEvent=require('src.utils.event')
fEvent:init({chart=Chart,event=Event,coordinates=require('src.services.coordinateService')})
local redo=require('plugins.redo')
local function near(a,b) assert(math.abs(a-b)<1e-8,tostring(a)..' ~= '..tostring(b)) end
local function check(x,w,t)
    local actualX,actualW=fEvent:get(1,t or 1)
    near(actualX,x*100); near(actualW,w*100)
end
local function load(fields,events)
    Chart:setChart({track={['1']=fields},event=events or {}}); Chart:load()
end
load({start_x=50,start_w=20}); check(0.5,0.2)
local tracks=require('src.utils.track')
tracks:init({chart=Chart})
assert(tracks:track_get_all_track()[1]==1, '只有初始值的轨道必须可见')
load({start_lpos=20,start_rpos=80}); check(0.5,0.6)
load({start_x=50,start_lpos=20}); check(0.5,0.6)
load({start_x=50,start_rpos=80}); check(0.5,0.6)
load({start_w=20,start_lpos=20}); check(0.3,0.2)
load({start_w=20,start_rpos=80}); check(0.7,0.2)
load({start_x=0,start_w=20,start_lpos=60,start_rpos=90}); check(0,0.2)
load({}); check(0,0)
load({start_x=50,start_w=60,boundary_type='pos',left_boundary=30,right_boundary=60})
check(0.45,0.3)
load({start_x=50,start_w=20,parent=2,scale_with_parent=1})
Chart:change('history.edit_track',function()
    Chart:setTrackField(2,'start_x',40); Chart:setTrackField(2,'start_w',40)
end)
check(0.4,0.08)
local function event(kind,first,last,from,to)
    return {type=kind,track=1,beat={first,0,1},beat2={last,0,1},from=from,to=to,
        trans={type='easings',easings=1}}
end
load({start_x=50,start_w=20},{event('x',2,4,60,80)})
check(0.5,0.2,1); check(0.6,0.2,2); check(0.7,0.2,3); check(0.8,0.2,6); check(0.5,0.2,1)
load({start_lpos=20,start_rpos=80},{event('lpos',0,2,30,40)})
check(0.55,0.5,0)
-- 两个事件均有值时，不再使用任何初始属性。
load({start_x=99,start_w=99},{event('lpos',0,2,20,20),event('rpos',0,2,80,80)})
check(0.5,0.6,0); check(0.5,0.6,5)
-- 无索引时的慢速查询同样以初始值补位。
load({start_x=50,start_w=20},{event('x',2,4,60,80)})
local hasTrack=Chart.hasTrack
Chart.hasTrack=function() return false end
check(0.5,0.2,1); check(0.7,0.2,3)
Chart.hasTrack=hasTrack
load({start_x=50,start_w=20})
Chart:change('history.edit_track',function() Chart:setTrackField(1,'start_x',70); Chart:setTrackField(1,'start_w',nil) end)
assert(Chart:getTrackField(1,'start_w')==nil)
assert(redo:undo()); check(0.5,0.2)
assert(redo:redoOne()); assert(Chart:getTrackField(1,'start_x')==70 and Chart:getTrackField(1,'start_w')==nil)
local raw=require('src.utils.dkjson').decode(Chart:encodeJson())
assert(raw.track['1'].start_x==70 and raw.track['1'].start_w==nil)
assert(not pcall(Chart.setTrackField,Chart,1,'start_x',math.huge))
assert(not pcall(Chart.setTrackField,Chart,1,'start_w','bad'))
print('PASS: initial track values, six pairs, events at zero, terminal values, seek, slow path, undo and serialization')
