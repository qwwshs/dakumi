-- 真正调用编辑窗口绘制，验证大偏移重排和多窗口不会漏画其他音符。
return function()
    local Chart = require('src.services.chartService')
    local Audio = require('src.services.audioService')
    local Coord = require('src.services.coordinateService')
    local Skin = require('src.services.noteSkin')
    local View = require('src.objects.play.demoInEdit')
    local Note = require('src.models.Note')
    local Event = require('src.models.Event')
    sidebar:to('track')
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, note={}, event={}})
    Chart:load()
    local moved = Note.new({beat={0,0,1},track=1})
    local untouched = Note.new({type='wipe',beat={10,0,1},track=1})
    local other = Note.new({type='wipe',beat={9,0,1},track=2})
    local movedEvent = Event.new({type='x',beat={0,0,1},beat2={1,0,1},track=1})
    local untouchedEvent = Event.new({type='x',beat={10,0,1},beat2={11,0,1},track=1})
    Chart:add(moved)
    Chart:add(other)
    Chart:add(untouched)
    Chart:add(Note.new({beat={11,0,1},track=1}))
    Chart:add(movedEvent)
    Chart:add(untouchedEvent)
    settings.wavfrom, settings.spectrogram = 0, 0
    local a, b = View:new(), View:new()
    local original = Skin.draw
    local drawn = {}
    Skin.draw = function(kind, image, x, y)
        drawn[#drawn+1] = {kind=kind,y=y}
    end
    local function draw(view, trackId, seconds)
        Audio:seek(seconds)
        drawn = {}
        view:drawEditContent(play.layout.edit.x, trackId)
    end
    local function seen(kind, entity)
        local expected = Coord:toY(entity:getBeatValue()) - settings.note_height
        for _, item in ipairs(drawn) do
            if item.kind == kind and math.abs(item.y - expected) < 0.000001 then return true end
        end
        return false
    end
    draw(a, 1, 5)
    assert(seen('wipe', untouched), 'initial note was not drawn')
    draw(a, 1, 5.01)
    -- 只触发即时修改通知，不能依赖离开侧栏后的事务提交来恢复绘制。
    Chart:beginChange()
    moved:setTimeOffset(20000)
    movedEvent:setTimeOffset(20000)
    draw(a, 1, 5.02)
    assert(seen('wipe', untouched), 'large offset hid an unrelated note after reordering')
    assert(seen('hold_head', untouchedEvent), 'large offset hid an unrelated event after reordering')
    assert(untouched:getTimeOffset() == 0 and untouched:getBeatValue() == 10)
    Chart:commitChange('history.edit_note')
    -- 多个窗口交错绘制时，各自保留其轨道的遍历起点。
    draw(b, 2, 5.03)
    assert(seen('wipe', other), 'another edit window skipped its first visible note')
    draw(a, 1, 5.04)
    draw(b, 2, 5.05)
    assert(seen('wipe', other), 'edit windows shared traversal indices')
    moved:setTimeOffset(nil)
    movedEvent:setTimeOffset(nil)
    draw(a, 1, 5.06)
    assert(seen('wipe', untouched) and seen('hold_head', untouchedEvent), 'clearing offset hid other entities')
    -- demo 必须独立筛选音符，公开的 addNote 入口不会立即对整个列表排序。
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, note={}, event={}})
    Chart:load()
    local demoView = require('src.objects.play.demoPlay')
    local far = Note.new({beat={0,0,1},time_offset=20000})
    local normal = Note.new({beat={10,0,1}})
    local wipe = Note.new({type='wipe',beat={11,0,1}})
    local hold = Note.new({type='hold',beat={10,0,1},beat2={12,0,1}})
    Chart:addNote(far)
    Chart:addNote(normal)
    Chart:addNote(wipe)
    Chart:addNote(hold)
    local savedPositions = play.get_all_track_pos
    play.get_all_track_pos = function() return {[1]={track_x=100,track_w=200}} end
    local function drawDemo(seconds)
        Audio:seek(seconds)
        drawn = {}
        demoView:draw()
    end
    local function seenDemo(kind, entity)
        local expected = Coord:toY(entity:getBeatValue()) * demoView.sh
            - settings.note_height * demoView.sh
        for _, item in ipairs(drawn) do
            if item.kind == kind and math.abs(item.y - expected) < 0.000001 then return true end
        end
        return false
    end
    drawDemo(4.5)
    assert(seenDemo('note', normal) and seenDemo('wipe', wipe) and seenDemo('hold_head', hold),
        'a far-offset note stopped demo rendering of unrelated notes')
    Chart:beginChange()
    far:setTimeOffset(nil)
    drawDemo(4.51)
    far:setTimeOffset(30000)
    drawDemo(4.52)
    assert(seenDemo('note', normal) and seenDemo('wipe', wipe) and seenDemo('hold_head', hold),
        'live offset reordering hid unrelated demo notes')
    Chart:commitChange('history.edit_note')
    drawDemo(4.53)
    assert(seenDemo('note', normal), 'forward playback lost a demo note')
    drawDemo(4.4)
    assert(seenDemo('note', normal), 'backward seek lost a demo note')
    play.get_all_track_pos = savedPositions
    Skin.draw = original
    print('PASS: demo visibility is independent of other notes offsets and array order')
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, note={}, event={}})
    Chart:load()
    print('PASS: large time offsets and independent edit-window traversal')
end
