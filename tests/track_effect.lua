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
