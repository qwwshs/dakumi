-- 导入插件审核、顺序、卸载、异常、可选资源和新文件写入的内存回归。
WINDOW={w=1600,h=900}
require('src.utils.room')
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
local manager=require('src.utils.plugin')
local Import=require('src.services.importService')
local Chart=require('src.services.chartService')
local Audio=require('src.services.audioService')
assert(Import:isDakumiChart({note={},event={},bpm_list={{beat={0,0,1},bpm=120}}}))
assert(not Import:isDakumiChart({components={}}))
assert(not Import:isDakumiChart({other_format={}}))
assert(not Import:isDakumiChart({note={},event={},bpm_list={}}))
assert(not Import:isDakumiChart({note={'bad'},event={},bpm_list={{beat={0,0,1},bpm=120}}}))
assert(Import:isDakumiChart({note={},event={{trans={type='bezier',trans={0,0,0.3,0.3,1,1}}}},
    bpm_list={{beat={0,0,1},bpm=120}},components={}}), '原生谱面有额外字段也应优先')
manager:init({marker='context',importer=Import})
Chart:setChart({info={chart_name='original'}}); Chart:load()
local audits={}
assert(manager:register({name='broken_review',type='import',layer=0,
    review=function() error('review failure') end,import=function() error('must not run') end}))
assert(manager:register({name='decline',type='import',layer=1,
    review=function(ctx,r) assert(ctx.marker=='context'); audits[#audits+1]=r.origin; return false end,
    import=function() error('must not run') end}))
local payload
assert(manager:register({name='accepted',type='import',layer=2,
    review=function(ctx,r) return r.extension=='pkg' end,
    import=function(ctx,r) assert(r.data=='bytes'); return payload end}))
assert(not manager:register({name='invalid',type='import',review=function() end}))
local sound={typeOf=function(_,kind) return kind=='SoundData' end,
    getChannelCount=function() return 1 end,getSampleRate=function() return 44100 end,
    getSampleCount=function() return 2 end,getBitDepth=function() return 16 end,
    getString=function() return string.char(0,0,255,127) end}
local image={typeOf=function(_,kind) return kind=='ImageData' end,
    encode=function() return {getString=function() return 'png bytes' end} end}
for mask=1,7 do
    payload={}
    if mask%2==1 then payload.chart={info={chart_name='converted'}} end
    if math.floor(mask/2)%2==1 then payload.audio=sound end
    if math.floor(mask/4)%2==1 then payload.background=image end
    local result,err=Import:convert({path='sample.pkg',data='bytes'})
    assert(result==payload,err)
end
payload={}
assert(not Import:convert({name='sample.pkg',data='bytes'}))
payload={chart={note={'bad'}}}
assert(not Import:convert({name='sample.pkg',data='bytes'}))
payload={chart='bad'}
assert(not Import:convert({name='sample.pkg',data='bytes'}))
assert(not Import:convert({name='sample.unknown',data='bytes'}))
local files,removed={},{}
PATH={usersPath={chart='memory/'}}
nativefs={read=function(path) return files[path] end,getInfo=function(path) return files[path] end,
    createDirectory=function(path) files[path]={directory=true}; return true end,
    write=function(path,data) files[path]=data; return true end,
    remove=function(path) removed[#removed+1]=path; files[path]=nil; return true end}
payload={chart={info={chart_name='converted'}},audio=sound,background=image}
local folder,err,paths=Import:saveToMenu(payload,{name='sample.pkg'},'original')
assert(folder=='sample',err)
assert(files[paths.audio]:sub(1,4)=='RIFF' and files[paths.background]=='png bytes')
assert(require('src.utils.dkjson').decode(files[paths.chart]).info.chart_name=='converted')
assert(Chart:getInfoField('chart_name')=='original', 'conversion or saving mutated current chart')
payload={chart={info={chart_name='another'}}}
folder,err,paths=Import:saveToMenu(payload,{name='sample.pkg'},'sample')
assert(paths.chart=='memory/sample/sample_.json' and files['memory/sample/sample.json'])
local originalWrite=nativefs.write
nativefs.write=function(path,data) if path:match('%.png$') then return false,'disk error' end return originalWrite(path,data) end
assert(not Import:saveToMenu({chart={},background=image},{name='fail.pkg'},'sample'))
assert(files['memory/sample/fail.json']==nil and files['memory/sample/sample.json'])
assert(manager:unregister('accepted'))
assert(not Import:convert({name='sample.pkg',data='bytes'}))
assert(manager:register({name='handler_error',type='import',review=function() return true end,
    import=function() error('conversion failed') end}))
local result,message=Import:convert({name='sample.pkg',data='bytes'})
assert(not result and message:find('conversion failed'))
print('PASS: import plugin registration, review order/isolation, seven optional combinations, file persistence and cleanup')
