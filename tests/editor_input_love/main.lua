io.stdout:setvbuf('no')
function love.errorhandler(message)
    print(debug.traceback(tostring(message)))
    return function() return 1 end
end
local project = love.filesystem.getWorkingDirectory()
package.path = project .. '/?.lua;' .. project .. '/?/init.lua;' .. package.path
local nativefs = require('src.utils.nativefs')
assert(nativefs.mount(project))
local rawUnmount = nativefs.unmount
nativefs.unmount = function(path)
    if path == nil or path == project then return true end
    return rawUnmount(path)
end
local rawOpen = io.open
local dummyFile = {write = function() return true end, close = function() return true end}
io.open = function(path, mode)
    if mode and (mode:find('w') or mode:find('a')) then return dummyFile end
    if path:find('users[/\\]') then return nil end
    return rawOpen(path, mode)
end
nativefs.write = function() return true end
nativefs.createDirectory = function() return true end
nativefs.getDirectoryItemsInfo = function() return {} end
nativefs.remove = function() error('unexpected deletion') end
local rawRead, rawList = nativefs.read, nativefs.getDirectoryItems
nativefs.read = function(path, ...)
    if path:find('users[/\\]') then return nil end
    return rawRead(path, ...)
end
nativefs.getDirectoryItems = function(path)
    if path:find('users') then return {} end
    return rawList(path)
end
love.filesystem.getSource = function() return project end
love.filesystem.getSourceBaseDirectory = function() return project end
love.filesystem.isFused = function() return false end
love.window.setMode = function() return true end
love.window.showMessageBox = function() return 1 end
love.system.openURL = function() return true end
-- 保持测试主循环，不启用游戏的错误自动保存。
local run = love.run
local ok, err = xpcall(assert(loadfile(project .. '/main.lua')), debug.traceback)
if not ok then
    print(err)
    love.event.quit(1)
    return
end
love.run = run
local gameLoad, gameUpdate, gameDraw = love.load, love.update, love.draw
local frame = 0
function love.errorhandler(message)
    print(debug.traceback(tostring(message)))
    love.event.quit(1)
    return function() return 1 end
end

local slider = require('src.objects.play.slider')
local ChartService = require('src.services.chartService')
local AudioService = require('src.services.audioService')
local results = {}
function love.load()
    gameLoad({})
    ChartService:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, event={}, note={}})
    ChartService:load()
    local data = love.sound.newSoundData(882000, 44100, 16, 1)
    AudioService:setSource(love.audio.newSource(data, 'static'))
    AudioService:setSoundData(data)
    AudioService:seek(3)
    room:to('edit')
end
local function point(x, y)
    love.mouse.setPosition(x, y)
    love.mousemoved(x, y, 0, 0, false)
end
function love.update(dt)
    frame = frame + 1
    Nui:frameBegin()
    gameUpdate(0.016)
    Nui:frameEnd()
    if frame == 2 then
        point(slider.x+10, slider.y+slider.h*0.5)
        love.mousepressed(mouse.x, mouse.y, 1, false, 1)
        results.dragStart = slider.down
        point(500, slider.y+slider.h*0.25)
    elseif frame == 3 then
        results.dragTime = AudioService:getCurrentTime()
        love.mousereleased(mouse.x, mouse.y, 1, false, 1)
    elseif frame == 4 then
        results.dragStopped = not slider.down
        point(1050, 500)
        results.singleBefore = AudioService:getCurrentBeat()
        love.wheelmoved(0, 1)
        results.singleAfter = AudioService:getCurrentBeat()
        tabs:addTab()
    elseif frame == 6 then
        point(1050, 500)
        results.tabsBefore = AudioService:getCurrentBeat()
        love.wheelmoved(0, 1)
        results.tabsAfter = AudioService:getCurrentBeat()
    elseif frame == 7 then
        sidebar:to('track')
        point(1500, 500)
        local before = AudioService:getCurrentBeat()
        love.wheelmoved(0, -1)
        results.sidebarNoSeek = AudioService:getCurrentBeat() == before
    elseif frame == 8 then
        for key, value in pairs(results) do print(key .. '=' .. tostring(value)) end
        assert(results.dragStart, 'progress drag did not start')
        assert(math.abs(results.dragTime - 15) < 0.001, 'progress drag did not follow the mouse')
        assert(results.dragStopped, 'progress drag remained active after release')
        assert(results.singleAfter > results.singleBefore, 'single edit wheel was blocked')
        assert(results.tabsAfter > results.tabsBefore, 'tabbed edit wheel was blocked')
        assert(results.sidebarNoSeek, 'sidebar wheel leaked into chart time')
        tabs:closeTab(2)
        local Event = require('src.models.Event')
        ChartService:add(Event.new({type='x', track=1, beat={10,0,1}, beat2={20,0,1},
            from=40, to=60, trans={type='easings', easings=1, trans={0,0,1,1}}}))
        sidebar:to('event', 1)
        directEventEditing.open = true
        settings.wavfrom, settings.spectrogram = 1, 1
    elseif frame == 10 then
        point(slider.x+10, slider.y+slider.h*0.5)
        love.mousepressed(mouse.x, mouse.y, 1, false, 1)
        assert(slider.down, 'direct event editing host blocked the progress drag')
        point(500, slider.y+slider.h*0.25)
    elseif frame == 11 then
        assert(math.abs(AudioService:getCurrentTime() - 15) < 0.001)
        love.mousereleased(mouse.x, mouse.y, 1, false, 1)
    elseif frame == 12 then
        point(500, 500)
        local before = AudioService:getCurrentBeat()
        love.wheelmoved(0, 1)
        assert(AudioService:getCurrentBeat() > before, 'direct event editing host blocked the time wheel')
    elseif frame == 13 then
        point(500, 500)
        love.mousepressed(mouse.x, mouse.y, 2, false, 1)
        assert(not slider.down, 'right click unexpectedly started progress dragging')
    elseif frame == 14 then
        love.mousereleased(mouse.x, mouse.y, 2, false, 1)
    elseif frame == 15 then
        assert(directEventEditing._menuOpen, 'context menu did not open on right click')
    elseif frame == 16 then
        point(520, 515)
        love.mousepressed(mouse.x, mouse.y, 1, false, 1)
    elseif frame == 18 then
        love.mousereleased(mouse.x, mouse.y, 1, false, 1)
        assert(ChartService:getEvent(1):getTransType() == 'bezier', 'context menu item did not respond')
    elseif frame == 20 then
        assert(not directEventEditing._menuOpen, 'context menu remained open after choosing an item')
        point(1050, 500)
        local before = AudioService:getCurrentBeat()
        love.wheelmoved(0, 1)
        assert(AudioService:getCurrentBeat() > before, 'time wheel remained blocked after closing the context menu')
        sidebar:getGroup('event').timeOffsetV.value = '125'
    elseif frame == 21 then
        local e = ChartService:getEvent(1)
        assert(e:getTimeOffset() == 125 and math.abs(e:getBeatValue() - 10.25) < 0.00001)
        sidebar:getGroup('event').timeOffsetV.value = '0'
    elseif frame == 22 then
        assert(ChartService:getEvent(1):getTimeOffset() == 125)
        assert(sidebar:getGroup('event').timeOffsetV.error == 'time_offset_invalid')
        sidebar:getGroup('event').timeOffsetV.value = ''
    elseif frame == 23 then
        assert(ChartService:getEvent(1):getTimeOffset() == 0)
        local Note = require('src.models.Note')
        ChartService:add(Note.new({type='hold',beat={10,0,1},beat2={12,0,1}}))
        sidebar:to('note', 1)
        sidebar:getGroup('note').timeOffsetV.value = '250'
    elseif frame == 24 then
        local n = ChartService:getNote(1)
        assert(n:getTimeOffset() == 250 and math.abs(n:getBeatValue() - 10.5) < 0.00001)
        sidebar:getGroup('note').timeOffsetV.value = ''
    elseif frame == 25 then
        assert(ChartService:getNote(1):getTimeOffset() == 0)
        require('tests.editor_input_love.offset_render')()
        print('PASS: progress drag, edit wheel, context menu and real Nuklear note/event time-offset fields')
    elseif frame == 26 then
        local mode=require('src.objects.editTool.effectMode')
        local Event=require('src.models.Event')
        ChartService:add(Event.new({type='x',beat={0,0,1},beat2={20,0,1},track=1,from=50,to=50}))
        mode:toggle()
        assert(ChartService:isEditingEffect())
        assert(table.concat(trackSequence,',')=='scroll,jump,track_alpha,track_line_alpha,rotate')
        assert(tabs.layout.lane[1]=='scroll' and tabs.layout.lane[5]=='rotate')
        local Coord=require('src.services.coordinateService')
        fEvent:place('scroll',Coord:toY(10),1)
        fEvent:place('scroll',Coord:toY(12),1)
        assert(ChartService:getEffectCount()==1 and ChartService:getChartEventCount()==1)
        assert(sidebar.displayed_content=='event')
        sidebar:getGroup('event').fromv.value='2'
        sidebar:getGroup('event').tov.value='3'
    elseif frame == 27 then
        local effect=ChartService:getEffect(1)
        assert(effect.type=='scroll' and effect.track==1 and effect.from==2 and effect.to==3)
        sidebar:getGroup('event').timeOffsetV.value='125'
    elseif frame == 28 then
        assert(ChartService:getEffect(1).time_offset==125)
        sidebar:to('nil')
        local before=ChartService:getEffect(1)
        redo:undo()
        assert(ChartService:getEffect(1).time_offset==nil and ChartService:getEffect(1).from==1)
        redo:redoOne()
        assert(table.eq(ChartService:getEffect(1),before))
        local cb=require('src.utils.clipboard')
        cb.tab=table.copy(cb.meta)
        cb.tab.type,cb.tab.pos='copy','edit'
        ctrl:copy_add(ChartService:getEvent(1),'event',1,1)
        point(play.layout.edit.x+5,require('src.services.coordinateService'):toY(14))
        local oldInput=input
        input=function(name) return name=='paste' end
        iskeyboard.ctrl=true
        ctrl:keypressed('v')
        input=oldInput; iskeyboard.ctrl=false
        assert(ChartService:getEffectCount()==2, 'effect paste did not write to effect')
        assert(ChartService:getChartEventCount()==1, 'effect paste changed ordinary events')
        cb.tab=table.copy(cb.meta)
        cb.tab.pos='edit'
        ctrl:copy_add(ChartService:getEvent(2),'event',1,1)
        input=function(name) return name=='deleteSelect' end
        iskeyboard.ctrl=true
        ctrl:keypressed('d')
        input=oldInput; iskeyboard.ctrl=false
        assert(ChartService:getEffectCount()==1, 'effect bulk delete failed')
        tabs:addTab()
        assert(tabs.list[2].edit.scroll and tabs:getLane(tabs:windowX(2)+1,tabs.layout.region.y+20))
        tabs:closeTab(2)
        require('src.objects.editTool.effectMode'):toggle()
        assert(not ChartService:isEditingEffect() and trackSequence[1]=='note' and trackSequence[5]=='rpos')
        assert(ChartService:getEventCount()==1 and ChartService:getEvent(1):getType()=='x')
        assert(ChartService:getEffectCount()==1)
        print('PASS: effect editor lanes, real placement/sidebar fields, time offset, undo/redo and exit isolation')
    elseif frame == 29 or frame == 32 then
        local bounds=require('src.objects.editTool.effectMode').buttonBounds
        assert(bounds and bounds.w>0 and bounds.h>0, 'effect toolbar button has no bounds')
        point(bounds.x+bounds.w/2,bounds.y+bounds.h/2)
        love.mousepressed(mouse.x,mouse.y,1,false,1)
    elseif frame == 30 or frame == 33 then
        love.mousereleased(mouse.x,mouse.y,1,false,1)
    elseif frame == 31 then
        assert(ChartService:isEditingEffect(), 'effect toolbar button did not enter editing')
    elseif frame == 34 then
        assert(not ChartService:isEditingEffect(), 'effect toolbar button did not exit editing')
        print('PASS: real Nuklear effect toolbar enter/exit buttons, copy/paste and bulk delete')
        sidebar:to('preference')
        local pref=sidebar:getGroup('preference')
        assert(pref.jumpMode.value==1)
        pref.jumpMode.value=2
        results.oldTip=ui.tip
        ui.tip=function(self,text,...)
            if text==i18n:get('save') then return true end
            return results.oldTip(self,text,...)
        end
    elseif frame == 35 then
        ui.tip=results.oldTip
        assert(ChartService:getPreferenceField('jump_mode')=='cumulative')
        redo:undo()
        assert(ChartService:getPreferenceField('jump_mode')=='current')
        redo:redoOne()
        assert(ChartService:getPreferenceField('jump_mode')=='cumulative')
        local json=dkjson.decode(ChartService:encodeJson())
        assert(json.preference.jump_mode=='cumulative')
        sidebar:to('preference')
        assert(sidebar:getGroup('preference').jumpMode.value==2)
        print('PASS: real preference panel jump mode save, serialization, undo/redo and reopen')
        love.event.quit(0)
    end
end
function love.draw() gameDraw() end
function love.quit() end
