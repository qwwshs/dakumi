-- Malody 转换不依赖当前谱面；覆盖 BPM、长条、全轨道效果及非法输入。
local M=require('plugins.malody.init')
local mc={meta={mode=0,mode_ext={column=4},song={title='test'}},
    time={{beat={0,0,1},bpm=120},{beat={8,0,1},bpm=180}},
    note={{beat={0,0,1},sound='a.ogg',type=1,offset=427},
        {beat={2,0,1},column=0},{beat={3,0,1},endbeat={4,0,1},column=3}},
    effect={{beat={8,0,1},jump=500,scroll=-2},{beat={9,0,1},jump=1000}}}
local c,a=M.convert(mc)
assert(a=='a.ogg' and c.offset==427 and #c.note==2 and c.note[2].type=='hold')
assert(c.note[2].track==4 and c.preference.jump_mode=='cumulative')
assert(c.preference.motion_mode=='malody' and c.preference.jump_unit=='ms')
assert(#c.effect==12 and c.effect[5].to==500 and c.effect[9].to==1000)
assert(#c.event==0 and c.track['1'].start_x==12.5 and c.track['1'].start_w==25)
assert(c.track['4'].start_x==87.5 and c.track['4'].name=='4')
mc.meta.mode=1; assert(not pcall(M.convert,mc)); mc.meta.mode=0
mc.note[2].column=4; assert(not pcall(M.convert,mc))
assert(M.review(nil,{extension='mcz'}) and M.review(nil,{extension='mc'}))
assert(not M.review(nil,{extension='json'}))
print('malody conversion passed')
