-- love tests/bpm_love：真实 LuaJIT 算法/线程/谱面事务；仅使用内存合成音频。
local root = love.filesystem.getSource():gsub('\\', '/'):gsub('/tests/bpm_love/?$', '')
package.path = root .. '/?.lua;' .. package.path
local lines = {}
local function say(text) lines[#lines+1] = text; print(text) end
local function pulse(rate, bpm, channels, bits)
    channels, bits = channels or 1, bits or 16
    local data = love.sound.newSoundData(rate*16,rate,bits,channels)
    for i=0,data:getSampleCount()-1 do
        local t, x = i/rate-0.24, 0
        if t>=0 then
            local p=t%(60/bpm)
            x=0.7*math.exp(-p*24)*math.sin(2*math.pi*(80*p+80*p*p))+0.003*math.sin(2*math.pi*713*t)
        end
        for c=1,channels do data:setSample(i,c,x) end
    end
    return data
end
local function run()
    local Analyzer = require('src.services.bpmAnalyzer')
    for _,spec in ipairs({{44100,120,1,16},{48000,173.5,2,16},{32000,240,1,16},{22050,120,1,8}}) do
        local sound = pulse(unpack(spec))
        local result = Analyzer.measure(sound)
        assert(math.abs(result.bpm-spec[2])<0.3, 'tempo mismatch')
        assert(result.offsetMs>=240 and result.offsetMs<=245, 'onset mismatch')
        say(string.format('PASS %d Hz: %.1f BPM, %d ms',spec[1],result.bpm,result.offsetMs))
    end
    assert(not pcall(Analyzer.measure,love.sound.newSoundData(132300,44100,16,1)), 'accepted silence')
    assert(not pcall(Analyzer.measure,love.sound.newSoundData(44100,44100,16,1)), 'accepted short audio')
    WINDOW={w=1600,h=900}
    require('src.utils.room'); require('src.utils.table'); require('src.utils.math')
    require('src.objects.meta'); require('src.utils.beat')
    easings=require('src.utils.easings'); require('src.utils.bezier')
    dkjson=require('src.utils.dkjson')
    log=function() end; save=function() error('unexpected disk write') end
    fNote={sort=function() end}; fEvent={sort=function() end}
    local words=require('i18n.zh-CN')
    i18n={get=function(_,key) return words[key] or key end}
    local Chart=require('src.services.chartService')
    local Audio=require('src.services.audioService')
    Audio:init({chart=Chart,backend={}})
    local History=require('plugins.redo')
    local Recorder=require('src.utils.chartRecorder')
    local Service=require('src.services.bpmMeasureService')
    local oldNewThread=love.thread.newThread
    love.thread.newThread=function(path)
        local f=assert(io.open(root..'/'..path,'rb')); local code=f:read('*a'); f:close()
        return oldNewThread(love.filesystem.newFileData('package.path='..string.format('%q',root..'/?.lua;')..'..package.path\n'..code,'bpm.lua'))
    end
    local choice, dialogs = 1, 0
    love.window.showMessageBox=function(title,message,buttons)
        dialogs=dialogs+1
        if type(buttons)=='table' then assert(message:find('120.0') and message:find('-240.0')) end
        return choice
    end
    local function setup()
        Chart:setChart({offset=50,bpm_list={{bpm=90,beat={0,0,1},linear_ramp=1},{bpm=170,beat={16,0,1},linear_ramp=0}}})
    end
    local function wait()
        local deadline=love.timer.getTime()+15
        while Service:isBusy() and love.timer.getTime()<deadline do Service:update(); love.timer.sleep(0.005) end
        assert(not Service:isBusy(),'worker timeout')
    end
    Audio:setSoundData(pulse(44100,120))
    setup()
    assert(Service:start()); assert(not Service:start(),'duplicate request'); wait()
    assert(Chart:getOffset()==50 and Chart:getBpm(1).bpm==90 and #History.revoke==0,'cancel mutated chart')
    choice=2
    local applied=false
    assert(Service:start(function(bpm,offset) applied=bpm==120 and offset==-240 end)); wait()
    assert(applied and Chart:getOffset()==-240 and Chart:getBpm(1).bpm==120)
    assert(Chart:getBpmCount()==2 and Chart:getBpm(2).bpm==170 and Chart:getBpm(1).linear_ramp==1)
    assert(#History.revoke==1 and History.revoke[1].action_key=='history.measure_bpm')
    assert(History:undo() and Chart:getOffset()==50 and Chart:getBpm(1).bpm==90)
    assert(History:redoOne() and Chart:getOffset()==-240 and Chart:getBpm(1).bpm==120)
    local before=dialogs
    assert(Service:start()); setup(); wait(); assert(dialogs==before,'stale result shown')
    assert(Service:start()); Audio:setSoundData(pulse(32000,120)); wait(); assert(dialogs==before,'wrong audio result shown')
    Audio:setSoundData(pulse(44100,120))
    assert(Service:start()); Recorder.begin()
    love.timer.sleep(0.3); Service:update(); assert(Service:isBusy() and dialogs==before,'result merged into gesture')
    Recorder.reset(); wait()
    Audio:setSoundData(love.sound.newSoundData(132300,44100,16,1))
    before=Chart:getOffset()
    assert(Service:start()); wait(); assert(Chart:getOffset()==before,'failure mutated chart')
    say('PASS: worker, duplicate guard, cancel, apply, preserved BPM entries, undo/redo, chart/audio switch, open transaction, silence')
end
function love.load()
    local ok,err=xpcall(run,debug.traceback)
    if not ok then say(err) end
    local f=assert(io.open(root..'/.zcode/bpm_love.txt','w'));f:write(table.concat(lines,'\n'));f:close()
    love.event.quit(ok and 0 or 1)
end
