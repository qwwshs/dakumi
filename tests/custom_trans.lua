-- 自定义 Lua 过渡：隔离、执行预算、事件/组/effect、序列化及撤销。
WINDOW={w=1600,h=900}
log=function() end
require('src.utils.room'); require('src.utils.table'); require('src.utils.math')
require('src.objects.meta'); require('src.utils.beat')
easings=require('src.utils.easings'); require('src.utils.bezier')
local Chart=require('src.services.chartService')
local Custom=require('src.utils.customTransition')
local Event=require('src.models.Event')
local fEvent=require('src.utils.event')
_G.fEvent=fEvent
fNote={sort=function() end}
fEvent:init({chart=Chart,event=Event,coordinates=require('src.services.coordinateService')})
local Effects=require('src.services.effectService')
local json=require('src.utils.dkjson')
dkjson=json
local redo=require('plugins.redo')
local function near(a,b) assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b)) end
Chart:setChart({}); Chart:load()
assert(Chart:putCustomTrans('平方','return t*t'))
near(Custom.evaluate('平方',0.5),0.25)
near(Custom.evaluate('平方',-1),0); near(Custom.evaluate('平方',2),1)
assert(Custom.validate('return math.sin(t * math.pi / 2)'))
for _,source in ipairs({'while true do end','return os.execute("anything")','math.pi=0; return t',
    'math={}; return t','return 0/0','return "oops"','return math.huge','return loadstring("return 1")()',
    'return ("x"):rep(1000000000)','return require("ffi")','return debug.sethook()','return io.open("secret")','return t +'}) do
    assert(not Custom.validate(source),source)
end
-- 计数钩子必须还原，不能污染编辑器自身的调试钩子。
local hook=function() end
debug.sethook(hook,'',100000)
assert(not Custom.validate('while true do end'))
assert(debug.gethook()==hook)
assert(('abc'):sub(1,1)=='a', 'host string methods were not restored')
debug.sethook()
assert(not Chart:putCustomTrans('../bad','return t'))
local event={track=1,type='x',beat={0,0,1},beat2={2,0,1},from=0,to=100,
    trans={type='custom',custom='平方'}}
Chart:setChart({custom_trans={['平方']='return t*t'},event={event},effect={
    {track=1,type='scroll',beat={0,0,1},beat2={2,0,1},from=0,to=2,trans=event.trans}}})
Chart:load()
near(fEvent:getTrans(Chart:getEvent(1),0.5),0.25)
near(Effects:calculate({1},1)[1].scroll,0.5)
near(Effects:createMotion({1}):distance(1,0,2),4/3)
Chart:putCustomTrans('平方','return t')
near(Effects:createMotion({1}):distance(1,0,2),2)
assert(redo:undo()); near(Custom.evaluate('平方',0.5),0.25)
assert(redo:redoOne()); near(Custom.evaluate('平方',0.5),0.5)
assert(json.decode(Chart:encodeJson()).custom_trans['平方']=='return t')
local e=Chart:getEvent(1); e:setCustomTrans('missing'); near(fEvent:getTrans(e,0.5),0.5)
assert(redo:undo()); assert(Chart:getEvent(1):getCustomTrans()=='平方')
assert(Chart:deleteCustomTrans('平方')); near(Custom.evaluate('平方',0.5),0.5)
assert(redo:undo()); assert(Chart:getCustomTrans('平方')=='return t')
-- 事件组内的自定义过渡也从谱面库读取；进入组编辑后库仍可选。
event.trans.custom='square'
Chart:setChart({custom_trans={square='return t*t'},event_groups={g={name='g',event={event}}},
    event={{track=1,type='event_group',event_group='g',beat={0,0,1},beat2={2,0,1},from=0,to=100}}})
Chart:load(); near(fEvent:get(1,1),25)
assert(Chart:beginEventGroupEdit('g')); assert(Chart:getCustomTrans('square')=='return t*t')
assert(Chart:finishEventGroupEdit())
-- 载入的坏脚本按需执行并回退，任何谱面不能通过脚本卡死加载或渲染。
Chart:setChart({custom_trans={bad='while true do end'}})
near(Custom.evaluate('bad',0.4),0.4)
assert(Custom.getError('bad'))
-- 自定义返回值本身决定终值，不能在 effect 持续段结束后强制跳到 to。
Chart:setChart({custom_trans={half='return 0.5'},effect={
    {track=1,type='scroll',beat={0,0,1},beat2={2,0,1},from=0,to=2,
        trans={type='custom',custom='half'}}}})
near(Effects:calculate({1},3)[1].scroll,1)
near(Effects:createMotion({1}):distance(1,0,4),4)
print('PASS: custom scripts, sandbox limits, events/effects/groups, history and serialization')
