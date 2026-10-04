-- Malody key 模式导入；ZIP 只挂载读取，不解压到用户目录。

local json = require('src.utils.dkjson')

local M = {name = 'malody', type = 'import'}

local serial = 0

local function finite(n)

    return type(n) == 'number' and n == n and math.abs(n) < math.huge

end

local function beat(b)

    assert(type(b) == 'table' and finite(b[1]) and finite(b[2]) and finite(b[3])

        and b[3] > 0, 'Malody：无效节拍')

    return {b[1], b[2], b[3]}

end

local function value(b) return b[1] + b[2] / b[3] end

local function parse(data)

    local mc, _, err = json.decode(data:gsub('^\239\187\191', ''))

    assert(type(mc) == 'table' and not err, 'Malody：谱面 JSON 无效')

    return mc

end

local function safePath(path)

    assert(type(path) == 'string' and not path:find('%c'), 'Malody：无效资源路径')

    path = path:gsub('\\', '/')

    assert(not path:match('^/') and not path:find(':') , 'Malody：资源必须使用相对路径')

    for part in path:gmatch('[^/]+') do assert(part ~= '..', 'Malody：禁止引用上级目录') end

    return path

end

local function event(chart, track, kind, b, n)
    local bt = beat(b)
    local bt2 = beat(b)
    bt2[1] = bt2[1] + 1
    chart.event[#chart.event + 1] = {track=track, type=kind, beat=bt, beat2=bt2,

        from=n, to=n, trans={type='easings', easings=1}}

end

function M.convert(mc)

    local meta = assert(mc.meta, 'Malody：缺少 meta')

    assert(meta.mode == 0, 'Malody：目前只支持 key 模式')

    local columns = meta.mode_ext and meta.mode_ext.column

    assert(finite(columns) and columns >= 1 and columns <= 64 and columns % 1 == 0,

        'Malody：无效按键数量')

    local song = meta.song or {}

    local chart = {version=1, note={}, event={}, effect={}, track={}, event_groups={}, offset=0,

        preference={jump_mode='cumulative', motion_mode='malody', event_scale=100, x_offset=0},

        info={song_name=song.title or '', artist=song.artist or '',

            chart_name=meta.version or '', chartor=meta.creator or ''}, bpm_list={}}

    for _, t in ipairs(mc.time or {}) do

        assert(finite(t.bpm) and t.bpm > 0, 'Malody：无效 BPM')

        chart.bpm_list[#chart.bpm_list+1] = {beat=beat(t.beat), bpm=t.bpm, linear_ramp=0}

    end

    assert(#chart.bpm_list > 0, 'Malody：缺少 BPM')

    table.sort(chart.bpm_list, function(a,b) return value(a.beat)<value(b.beat) end)

    assert(value(chart.bpm_list[1].beat)==0, 'Malody：首个 BPM 必须从第 0 拍开始')

    local function secondsAt(b)

        local last, seconds, bpm = 0, 0, chart.bpm_list[1].bpm

        for _, t in ipairs(chart.bpm_list) do

            local nextBeat=value(t.beat)

            if nextBeat>b then break end

            seconds=seconds+(nextBeat-last)*60/bpm; last=nextBeat; bpm=t.bpm

        end

        return seconds+(b-last)*60/bpm

    end

    local audio

    for _, n in ipairs(mc.note or {}) do

        if n.column ~= nil then

            assert(finite(n.column) and n.column%1==0 and n.column>=0 and n.column<columns,

                'Malody：按键列超出范围')

            local item={track=n.column+1, type=n.endbeat and 'hold' or 'note', beat=beat(n.beat)}

            if n.endbeat then

                item.beat2=beat(n.endbeat)

                assert(value(item.beat2)>=value(item.beat), 'Malody：长条结束早于开始')

            end

            chart.note[#chart.note+1]=item

        elseif n.sound and n.type==1 then

            assert(not audio, 'Malody：暂不支持多段背景音乐')

            assert(finite(n.offset or 0), 'Malody：无效音乐偏移')

            audio=n.sound

            chart.offset=secondsAt(value(beat(n.beat)))*1000+(n.offset or 0)

        end

    end

    table.sort(chart.note,function(a,b) return value(a.beat)<value(b.beat) end)

    for t=1,columns do

        chart.track[t]={name=tostring(t)}

        event(chart,t,'x',{0,0,1},(t-0.5)*100/columns)

        event(chart,t,'w',{0,0,1},100/columns)

    end

    for _, e in ipairs(mc.effect or {}) do

        local b=beat(e.beat)

        for _, kind in ipairs({'scroll','jump'}) do

            if e[kind] ~= nil then

                assert(finite(e[kind]), 'Malody：无效 '..kind)

                local n=e[kind]

                -- MC jump 保留毫秒；音符与播放位置使用同一份累计位移坐标。
                for t=1,columns do

                    chart.effect[#chart.effect+1]={track=t,type=kind,beat=beat(b),beat2=beat(b),

                        from=n,to=n,trans={type='easings',easings=1}}

                end

            end

        end

    end

    return chart, audio, meta.background

end

function M.review(_, request)

    return request.extension=='mc' or request.extension=='mcz'

end

local function load(mc, read)

    local chart, audio, background=M.convert(mc)

    local result={chart=chart}

    if audio and audio~='' then

        local bytes=read(safePath(audio))

        if bytes then result.audio=love.sound.newSoundData(love.filesystem.newFileData(bytes,audio)) end

    end

    if background and background~='' then

        local bytes=read(safePath(background))

        if bytes then result.background=love.image.newImageData(love.filesystem.newFileData(bytes,background)) end

    end

    return result

end

function M.import(_, request)

    if request.extension=='mc' then

        local root=(request.path or ''):match('^(.*[/\\])')

        return load(parse(request.data),function(path)

            if root then return nativefs.read(root..path) end

        end)

    end

    serial=serial+1

    local mount='__malody_import_'..serial

    local archive=love.filesystem.newFileData(request.data,'malody_'..serial..'.zip')

    assert(love.filesystem.mount(archive,mount), 'Malody：无法读取 MCZ 压缩包')

    local ok,result=pcall(function()

        local candidates={}

        local function scan(dir, depth)

            assert(depth<32, 'Malody：压缩包目录过深')

            for _, name in ipairs(love.filesystem.getDirectoryItems(dir)) do

                local path=dir..'/'..name

                local info=love.filesystem.getInfo(path)

                if info and info.type=='directory' then scan(path,depth+1)

                elseif name:lower():match('%.mc$') then

                    local mc=parse(assert(love.filesystem.read(path)))

                    if mc.meta and mc.meta.mode==0 then candidates[#candidates+1]={path=path,mc=mc} end

                end

            end

        end

        scan(mount,0)

        table.sort(candidates,function(a,b) return a.path<b.path end)

        assert(#candidates>0, 'Malody：压缩包中没有 key 模式 MC 谱面')

        local selected=1

        if #candidates>1 then

            local buttons={}

            for _, c in ipairs(candidates) do

                buttons[#buttons+1]=((c.mc.meta.song or {}).title or '')..' / '..(c.mc.meta.version or c.path)

            end

            buttons[#buttons+1]='取消'

            selected=love.window.showMessageBox('Malody','请选择要导入的谱面',buttons,'info')

            assert(selected and candidates[selected], 'Malody：已取消导入')

        end

        local c=candidates[selected]

        local root=c.path:match('^(.*)/')..'/'

        return load(c.mc,function(path) return love.filesystem.read(root..path) end)

    end)

    love.filesystem.unmount(archive)

    if not ok then error(result) end

    return result

end

return M

