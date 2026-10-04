-- 按轨道取值、缓动、结束保持、回退重算和新格式保存的回归。
WINDOW = {w=1600,h=900}
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
easings = require('src.utils.easings')
require('src.utils.bezier')
local Chart = require('src.services.chartService')
local Effects = require('src.services.effectService')
local function item(track, kind, first, last, from, to, trans)
    return {track=track,type=kind,beat={first,0,1},beat2={last,0,1},from=from,to=to,trans=trans or {type='easings',easings=1}}
end
local list = {
    item(1,'note_alpha',4,8,100,0),
    item(2,'note_alpha',0,8,20,60),
    item(1,'note_rotate',0,8,0,80),
    item(1,'note_alpha',10,12,70,90),
    item(2,'track_alpha',2,6,0,100,{type='easings',easings=2}),
    item(2,'track_line_alpha',5,5,0,30),
}
Chart:setChart({effect=list,bpm_list={{beat={0,0,1},bpm=120,linear_ramp=0}}})
local function near(a,b) assert(math.abs(a-b)<1e-8, tostring(a)..' ~= '..tostring(b)) end
local v = Effects:calculate({1,2,3},6)
near(v[1].note_alpha,50)
near(v[2].note_alpha,50)
near(v[1].note_rotate,60)
near(v[2].note_rotate,0)
near(v[3].note_alpha,100)
near(v[2].track_line_alpha,30)
near(v[2].track_alpha,100)
v=Effects:calculate({1,2},4)
near(v[2].track_alpha,easings[2](0.5)*100)
v=Effects:calculate({1,2},9)
near(v[1].note_alpha,0)
v=Effects:calculate({1,2},11)
near(v[1].note_alpha,80)
v=Effects:calculate({1,2},1)
near(v[1].note_alpha,100)
near(v[2].track_alpha,100)
-- 无 track 的旧条目不会变成全局效果，也不会修改输入数据。
list[#list+1]=item(nil,'note_alpha',0,100,0,0)
v=Effects:calculate({1,2},6)
near(v[1].note_alpha,50)
assert(list[1].track==1 and list[2].track==2)
local fresh=Effects:defaults()
fresh.note_alpha=0
assert(Effects:defaults().note_alpha==100)
print('PASS: independent track effects, event transitions, latest start, terminal values and backward seek')

-- scroll 为速度值，下一条开始前保持；jump 只取当前值，不累计。
Chart:setChart({effect={item(1,'scroll',2,2,2,2),item(1,'scroll',4,4,0,0),
    item(1,'scroll',6,6,-1,-1),item(2,'scroll',0,4,0,4),
    item(3,'jump',2,2,1,1),item(3,'jump',4,4,3,3)},
    bpm_list={{beat={0,0,1},bpm=120,linear_ramp=0}}})
local motion=Effects:createMotion({1,2,3,4})
near(motion:distance(1,0,8),4)
near(motion:distance(1,2,4),4)
near(motion:distance(1,4,6),0)
near(motion:distance(1,6,8),-2)
near(motion:distance(2,0,4),8)
near(motion:distance(2,0,6),16)
near(motion:distance(3,0,5),5)
near(motion:distance(3,3,5),1)
near(motion:distance(4,2,5),3)
for _, id in ipairs({1,2,4}) do near(motion:distance(id,5,5),0) end
near(motion:distance(1,8,0),-4)
Chart:setChart({effect={item(1,'scroll',0,4,0,4,{type='easings',easings=2}),
    item(1,'scroll',2,2,3,3)},bpm_list={{beat={0,0,1},bpm=120,linear_ramp=0}}})
motion=Effects:createMotion({1})
near(motion:distance(1,0,4),2/3+6)
print('PASS: scroll integration, overrides, stop/reverse, nonaccumulating jump and judgement zero')

Chart:setChart({effect={item(1,'jump',25,25,3,3),item(1,'jump',30,30,1,1)},
    bpm_list={{beat={0,0,1},bpm=120,linear_ramp=0}}})
motion=Effects:createMotion({1,2})
near(motion:distance(1,20,28),8)
near(motion:distance(1,24.999,28),3.001)
near(motion:distance(1,25,28),0)
near(motion:distance(1,26,28),-1)
near(motion:distance(1,30,31),0)
near(motion:distance(2,25,28),3)
near(motion:distance(1,20,28),8)
print('PASS: jump activates at its start only, never anticipates target jumps, replaces previous values and resets on seek')

Chart:setChart({effect={item(1,'jump',25,28,99,3),item(1,'jump',30,35,-99,2),
    item(1,'jump',40,40,0,-1),item(2,'jump',20,50,999,7)},
    preference={jump_mode='cumulative'},bpm_list={{beat={0,0,1},bpm=120,linear_ramp=0}}})
motion=Effects:createMotion({1,2})
near(motion:distance(1,20,28),8)
near(motion:distance(1,25,28),0)
near(motion:distance(1,30,35),0)
near(motion:distance(1,40,44),0)
near(motion:distance(1,20,28),8)
near(Effects:calculate({1,2},30)[1].jump,5)
near(Effects:calculate({1,2},30)[2].jump,7)
Chart:setPreferenceField('jump_mode','current')
near(Effects:calculate({1},30)[1].jump,-99)
motion=Effects:createMotion({1})
near(motion:distance(1,25,124),0)
print('PASS: per-chart jump modes, trigger-only cumulative to values, ignored from/easing and independent tracks')

assert(Chart:getPreferenceField('jump_mode')=='current')
local saved=Chart:getPreferenceField('jump_mode')
Chart:change('history.edit_preference',function() Chart:setPreferenceField('jump_mode','cumulative') end)
assert(Chart:getPreferenceField('jump_mode')=='cumulative')
Chart:setChart({effect={item(1,'jump',25,30,100,3),item(1,'jump',25,35,200,2)},
    preference={jump_mode='cumulative'},bpm_list={{beat={0,0,1},bpm=120,linear_ramp=0}}})
near(Effects:createMotion({1}):distance(1,25,30),0)
near(Effects:calculate({1},25)[1].jump,5)


-- 密集 scroll 只编译一次；帧内查询和多个预览不重复读取整份效果。
local dense={}
for i=1,3000 do
    dense[#dense+1]=item(1,'scroll',i/10,i/10,2,2)
end
Chart:setChart({effect=dense})
local reads=0
local getEffect=Chart.getEffect
Chart.getEffect=function(self,index) reads=reads+1; return getEffect(self,index) end
motion=Effects:createMotion({1})
near(motion:distance(1,10,20),20)
assert(reads==3000)
for frame=1,60 do
    local current=Effects:createMotion({1})
    near(current:distance(1,10,20),20)
    near(Effects:calculate({1},frame)[1].scroll,2)
end
assert(reads==3000, '逐帧查询重复读取效果列表')
Chart:setPreferenceField('jump_mode','cumulative')
Effects:createMotion({1})
assert(reads==6000, '修改后没有重建缓存')
Chart.getEffect=getEffect
-- 瞬时相同起点由最后写入的效果覆盖；累计 jump 同起点均计入。
Chart:setChart({effect={item(1,'scroll',0,0,2,2),item(1,'scroll',0,0,3,3)}})
near(Effects:createMotion({1}):distance(1,0,10),30)
print('PASS: dense effect compilation is shared across frames and invalidated on chart writes')


-- Malody 使用毫秒 jump 与音频秒轴，两端共用累计坐标。
Chart:setChart({preference={motion_mode='malody',jump_mode='cumulative'},
    bpm_list={{beat={0,0,1},bpm=120},{beat={10,0,1},bpm=240}},
    effect={item(1,'scroll',0,0,2,2),item(1,'jump',5,5,1000000000,1000000000),
        item(1,'jump',12,12,500,500)}})
motion=Effects:createMotion({1})
-- 巨大 jump 已发生后，未来音符仍在正确的相对位置，不消失。
near(motion:distance(1,6,7),2)
near(motion:distance(1,13,14),1)
near(motion:distance(1,13,13),0)
-- 跨 jump 的位移单位为毫秒，与 scroll 乘数独立；跨 BPM 按秒积分。
near(motion:distance(1,11,13),4)
near(motion:distance(1,13,11),-4)
near(motion:distance(1,6,7),2)
print('PASS: Malody millisecond jumps, note anchors, backward seek and time-domain scroll across BPM changes')


-- Regain 133–204 段：极小 scroll 配合巨大毫秒 jump，按触发点速度换算位移。
Chart:setChart({preference={motion_mode='malody',jump_mode='cumulative'},
    bpm_list={{beat={0,0,1},bpm=140}}, effect={
        item(1,'scroll',132,132,0.00001,0.00001),
        item(1,'jump',132.9975,132.9975,10714178.571428573,10714178.571428573),
        item(1,'scroll',134,134,2,2),item(1,'jump',135,135,500,500),
        item(1,'scroll',136,136,0,0),item(1,'jump',137,137,999999999,999999999)}})
motion=Effects:createMotion({1})
near(motion:distance(1,132.5,133),0.2499975+0.000005)
-- 后续 scroll 改变不会把此前 jump 按新速度重新缩放。
near(motion:distance(1,134,135),2+500*2*140/60000)
near(motion:distance(1,136,138),0)
near(motion:distance(1,133,132.5),-(0.2499975+0.000005))
print('PASS: tiny-scroll Malody jumps, trigger-time weighting and zero-speed jumps')
