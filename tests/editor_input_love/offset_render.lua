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
    local wasDemoOpen=demo.open
    -- 编辑预览不启用 effect，即使已有上一帧的效果表。
    demo.open=false
    play.effect={[1]={note_alpha=0}}
    assert(play:get_effect(1).note_alpha==100)
    -- 实际 demo 绘制也必须使用积分和当前 jump，而不是仅增加配置字段。
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, note={}, event={},
        effect={{track=1,type='scroll',beat={0,0,1},beat2={0,0,1},from=2,to=2},
            {track=1,type='jump',beat={9,9,10},beat2={9,9,10},from=0.1,to=0.1}}})
    Chart:load()
    Chart:addNote(Note.new({beat={10,0,1}}))
    drawDemo(4.9)
    assert(seenDemo('note',Chart:getNote(1)), 'effects were active outside demo mode')
    demo.open=true
    play.effect={}
    drawDemo(4.9)
    local expectedY=(settings.judge_line_y-0.4*denom.scale*100)*demoView.sh
        - settings.note_height*demoView.sh
    local found=false
    for _, item in ipairs(drawn) do
        if item.kind=='note' and math.abs(item.y-expectedY)<0.000001 then found=true end
    end
    assert(found, 'demo ignored scroll integration or current jump')
    print('PASS: actual demo note position uses scroll and jump')
    -- 巨大的 Malody 累计毫秒 jump 后，demo 仍实际绘制即将到达的 note。
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, note={}, event={},
        preference={motion_mode='malody',jump_mode='cumulative'},
        effect={{track=1,type='scroll',beat={0,0,1},beat2={0,0,1},from=1,to=1},
            {track=1,type='jump',beat={2,0,1},beat2={2,0,1},from=1000000000,to=1000000000}}})
    Chart:load()
    Chart:addNote(Note.new({beat={10,0,1}}))
    drawDemo(4.9)
    expectedY=(settings.judge_line_y-0.2*denom.scale*100)*demoView.sh
        - settings.note_height*demoView.sh
    found=false
    for _, entry in ipairs(drawn) do
        if entry.kind=='note' and math.abs(entry.y-expectedY)<0.00001 then found=true end
    end
    assert(found, 'Malody cumulative jump hid notes in the actual demo renderer')
    print('PASS: actual demo renders notes after huge cumulative millisecond jumps')

    -- 在判定前的真实帧验证 Regain 的巨大 jump + 极小 scroll 组合。
    Chart:setChart({bpm_list={{bpm=140,beat={0,0,1}}},
        preference={motion_mode='malody',jump_mode='cumulative'},
        note={{track=1,type='note',beat={133,0,1}}},
        effect={{track=1,type='scroll',beat={132,0,1},beat2={132,0,1},from=0.00001,to=0.00001},
            {track=1,type='jump',beat={132,399,400},beat2={132,399,400},
                from=10714178.571428573,to=10714178.571428573}}})
    Chart:load()
    local getCurrentBeat=Audio.getCurrentBeat
    Audio.getCurrentBeat=function() return 132.5 end
    drawDemo(1)
    Audio.getCurrentBeat=getCurrentBeat
    expectedY=(settings.judge_line_y-0.2500025*denom.scale*100)*demoView.sh-settings.note_height*demoView.sh
    found=false
    for _, entry in ipairs(drawn) do
        if entry.kind=='note' and math.abs(entry.y-expectedY)<0.00001 then found=true end
    end
    assert(found, 'tiny-scroll Malody jump hid a future note before judgement')
    print('PASS: actual future note is visible during the tiny-scroll jump interval')
    -- 反向 scroll 将未判定 note 放到判定线下，仍应绘制；判定后才隐藏。
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1}}},
        effect={{track=1,type='scroll',beat={0,0,1},beat2={0,0,1},from=-1,to=-1}},
        note={{track=1,type='note',beat={10,0,1}}}})
    Chart:load()
    drawDemo(4.95)
    expectedY=(settings.judge_line_y+0.1*denom.scale*100)*demoView.sh-settings.note_height*demoView.sh
    found=false
    for _, entry in ipairs(drawn) do
        if entry.kind=='note' and math.abs(entry.y-expectedY)<0.00001 then found=true end
    end
    assert(found, 'unjudged note below judgement line was hidden')
    drawDemo(5.05)
    for _, entry in ipairs(drawn) do assert(entry.kind~='note', 'judged note remained visible') end
    print('PASS: effects are demo-only; unjudged notes render below the judgement line')
    demo.open=wasDemoOpen
    play.get_all_track_pos = savedPositions
    Skin.draw = original
    print('PASS: demo visibility is independent of other notes offsets and array order')
    Chart:setChart({bpm_list={{bpm=120,beat={0,0,1},linear_ramp=0}}, note={}, event={}})
    Chart:load()
    print('PASS: large time offsets and independent edit-window traversal')
end
