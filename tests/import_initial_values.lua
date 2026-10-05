-- 导入结果经真实服务读取：固定轨道、运动轨道、延迟出现、结束隐藏与初始属性。
WINDOW={w=1600,h=900}
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
easings=require('src.utils.easings')
require('src.utils.bezier')
local Chart=require('src.services.chartService')
local Event=require('src.models.Event')
local events=require('src.utils.event')
events:init({chart=Chart,event=Event,coordinates=require('src.services.coordinateService')})
local tracks=require('src.utils.track')
tracks:init({chart=Chart})
local function check(id,b,x,w)
    local actualX,actualW=events:get(id,b)
    assert(math.abs(actualX-x)<1e-8 and math.abs(actualW-w)<1e-8,
        tostring(actualX)..','..tostring(actualW)..' ~= '..x..','..w)
end
local malody=require('plugins.malody.init').convert({meta={mode=0,mode_ext={column=4}},
    time={{beat={0,0,1},bpm=120}},effect={{beat={2,0,1},jump=500}}})
Chart:setChart(malody); Chart:load()
assert(Chart:getPreferenceField('jump_unit')=='ms' and #tracks:track_get_all_track()==4)
check(1,0,12.5,25); check(4,10,87.5,25)
assert(require('src.services.effectService'):createMotion({1}):distance(1,1,3)==3)
local function lane(list) return {type='position',list=list} end
local chart=require('plugins.takana_import.converter').convert({version=3,components={
    {model={type='track',timeStart=0,timeEnd=2000,movement={type='trackEdgeMovement',
        left=lane({['0']='v1e_(-4.5,u)'}),right=lane({['0']='v1e_(4.5,u)'})}}},
    {model={type='track',timeStart=1000,timeEnd=2000,movement={type='trackDirectMovement',
        position=lane({['1000']='v1e_(0,s)',['2000']='v1e_(4.5,u)'}),
        width=lane({['1000']='v1e_(1.8,u)'})}}},
}})
assert(chart.track['1'].start_lpos==0 and chart.track['1'].start_rpos==100)
assert(chart.track['1'].start_x==nil and chart.track['2'].start_w==0)
-- 第一条轨道只留下结束隐藏事件，固定边界由初始属性提供。
local firstCount=0
for _,event in ipairs(chart.event) do if event.track==1 then firstCount=firstCount+1 end end
assert(firstCount==2)
Chart:setChart(chart); Chart:load()
check(1,0,50,100); check(1,3,50,100); check(1,4,50,0)
check(2,1,50,0); check(2,2,50,20); check(2,3,75,20); check(2,4,50,0)
print('PASS: imported beat/ms preference, static initial tracks, both Takana lane types and lifetime visibility')
