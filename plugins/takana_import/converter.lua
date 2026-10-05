-- Takana v2/v3 纯数据转换；毫秒时间按 BPM 积分后吸附到最近的 1/256 拍。
local json=require('src.utils.dkjson')
local Curves=require('plugins.takana_import.curves')
local Converter={}
local GRID=256
local SCALE=100/9
local MAX_TIME=2147483647
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function ticks(beat) return math.floor(beat*GRID+0.5) end
local function fraction(tick)
    local whole=math.floor(tick/GRID)
    return {whole,tick-whole*GRID,GRID}
end
local function value(v)
    if type(v)=='table' then return v.value end
    return v
end
local function localized(v)
    if type(v)=='string' or type(v)=='number' then return tostring(v) end
    if type(v)~='table' then return '' end
    for _,key in ipairs({'zh-CN','zh','en','ja'}) do
        if type(v[key])=='string' then return v[key] end
    end
    local keys={}
    for key,item in pairs(v) do if type(item)=='string' then keys[#keys+1]=key end end
    table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
    return keys[1] and v[keys[1]] or ''
end
function Converter.decode(bytes)
    local data,_,err=json.decode(bytes:gsub('^\239\187\191',''))
    assert(type(data)=='table' and not err, 'Takana：谱面 JSON 无效')
    return data
end
function Converter.matches(data)
    return type(data)=='table' and type(data.components)=='table'
end
local function timing(preference)
    local entries={}
    for time,bpm in pairs((preference or {}).bpmList or {}) do
        time,bpm=tonumber(time),tonumber(bpm)
        assert(finite(time) and finite(bpm) and bpm>0, 'Takana：无效 BPM 项')
        entries[#entries+1]={time=time,bpm=bpm}
    end
    table.sort(entries,function(a,b) return a.time<b.time end)
    local initial=entries[1] and entries[1].bpm or 120
    for _,entry in ipairs(entries) do if entry.time<=0 then initial=entry.bpm end end
    local segments={{time=0,beat=0,bpm=initial}}
    local bpmList={{beat={0,0,GRID},bpm=initial,linear_ramp=0}}
    for _,entry in ipairs(entries) do
        if entry.time>0 then
            local previous=segments[#segments]
            entry.beat=previous.beat+(entry.time-previous.time)*previous.bpm/60000
            segments[#segments+1]=entry
            local item={beat=fraction(ticks(entry.beat)),bpm=entry.bpm,linear_ramp=0}
            local previousBpm=bpmList[#bpmList]
            if ticks(entry.beat)==previousBpm.beat[1]*GRID+previousBpm.beat[2] then
                bpmList[#bpmList]=item
            else bpmList[#bpmList+1]=item end
        end
    end
    local function toTicks(time)
        assert(finite(time), 'Takana：时间必须是有限毫秒数')
        local lo,hi=1,#segments
        while lo<hi do
            local mid=math.floor((lo+hi+1)/2)
            if segments[mid].time<=time then lo=mid else hi=mid-1 end
        end
        local entry=segments[lo]
        return ticks(entry.beat+(time-entry.time)*entry.bpm/60000)
    end
    return bpmList,toTicks,segments
end
function Converter.convert(data,options)
    options=options or {}
    assert(Converter.matches(data), 'Takana：缺少 components')
    local properties=data.properties or {}
    local version=data.version or properties.version
    assert(version==nil or version==2 or version==3, 'Takana：不支持的谱面版本 '..tostring(version))
    properties=properties.properties or properties
    local offset=value(properties.offset)
    if offset==nil then offset=(options.preference or {}).offset or 0 end
    assert(finite(offset), 'Takana：无效歌曲偏移')
    local bpmList,toTicks,segments=timing(options.preference)
    local curveCache={}
    local info=options.songinfo or {}
    local difficulty=(info.difficulties or {})[options.difficulty] or
        (info.difficulties or {})[tostring(options.difficulty)] or {}
    local name=options.chartName or ''
    if difficulty.levelDisplay then name=name..' Lv.'..localized(difficulty.levelDisplay) end
    local chart={version=1,offset=-offset,bpm_list=bpmList,note={},event={},effect={},track={},
        custom_trans={},event_groups={},preference={event_scale=100,x_offset=0,jump_unit='ms',jump_mode='current'},
        info={song_name=localized(info.title),artist=localized(info.composer),
            chart_name=name,chartor=localized(difficulty.charter)}}
    local layers={}
    local editor=data.editorconfig or (data.properties or {}).editorconfig or {}
    for index,layer in ipairs((editor.layers or {}).value or {}) do layers[layer.id]=index end
    local function emit(track,kind,first,last,from,to,trans)
        if last<=first then return end
        assert(finite(from) and finite(to), 'Takana：轨道位置超出数值范围')
        chart.event[#chart.event+1]={track=track,type=kind,beat=fraction(first),beat2=fraction(last),
            from=from,to=to,trans=trans or {type='easings',easings=1}}
    end
    local function coordinate(v,kind) return (kind=='w' and v or v+4.5)*SCALE end
    local function lane(track,kind,movement,startTime,endTime)
        local eventStart=#chart.event+1
        assert(type(movement)=='table' and movement.type=='position' and type(movement.list)=='table',
            'Takana：只支持 position 运动列表')
        local nodes={}
        for time,raw in pairs(movement.list) do
            local node=Curves.parse(raw,chart,curveCache)
            node.time=tonumber(time)
            assert(finite(node.time), 'Takana：无效节点时间')
            nodes[#nodes+1]=node
        end
        table.sort(nodes,function(a,b) return a.time<b.time end)
        local firstTick=toTicks(startTime)
        local endTick=endTime<MAX_TIME and math.max(firstTick+1,toTicks(endTime)) or nil
        local function constant(first,last,n)
            emit(track,kind,first,last,coordinate(n,kind),coordinate(n,kind))
        end
        if #nodes==0 then
            constant(firstTick,endTick or firstTick+1,0)
        else
            if nodes[1].time>startTime then
                constant(firstTick,math.min(toTicks(nodes[1].time),endTick or math.huge),nodes[1].value)
            end
            for i=1,#nodes-1 do
                local node,nextNode=nodes[i],nodes[i+1]
                local first,last=math.max(startTime,node.time),math.min(endTime,nextNode.time)
                if last>first then
                    -- BPM 改变后，时间进度与拍进度不再成比例，需在变速点切开原曲线。
                    local cuts={first}
                    for _,segment in ipairs(segments) do
                        if segment.time>first and segment.time<last then cuts[#cuts+1]=segment.time end
                    end
                    cuts[#cuts+1]=last
                    for j=1,#cuts-1 do
                        local a,b=(cuts[j]-node.time)/(nextNode.time-node.time),(cuts[j+1]-node.time)/(nextNode.time-node.time)
                        local from=node.value+(nextNode.value-node.value)*node.evaluate(a)
                        local to=node.still and from or node.value+(nextNode.value-node.value)*node.evaluate(b)
                        local firstBeat,lastBeat=toTicks(cuts[j]),toTicks(cuts[j+1])
                        if lastBeat>firstBeat then
                            emit(track,kind,firstBeat,lastBeat,coordinate(from,kind),coordinate(to,kind),
                                Curves.slice(node,a,b,chart))
                        end
                    end
                end
            end
            local last=nodes[#nodes]
            if last.time<=endTime then
                local begin=math.max(firstTick,toTicks(last.time))
                constant(begin,endTick or begin+1,last.value)
            end
        end
        if endTick then
            local hidden=kind=='w' and 0 or 50
            emit(track,kind,endTick,endTick+1,hidden,hidden)
        end
        -- 生效前保持零宽；从第 0 拍开始的常值段改用初始属性，运动与结束隐藏仍保留事件。
        local initial=kind=='w' and 0 or 50
        local firstEvent=chart.event[eventStart]
        if firstEvent and firstEvent.beat[1]==0 and firstEvent.beat[2]==0 then
            initial=firstEvent.from
            if firstEvent.from==firstEvent.to then table.remove(chart.event,eventStart) end
        end
        chart.track[tostring(track)]['start_'..kind]=initial
    end
    local trackCount=0
    local function walk(components,parent,depth)
        assert(depth<64 and type(components)=='table', 'Takana：物件层级无效或过深')
        for _,component in ipairs(components) do
            assert(type(component)=='table' and type(component.model)=='table', 'Takana：无效物件')
            local model=component.model
            local childTrack=parent
            if model.type=='track' then
                trackCount=trackCount+1
                childTrack=trackCount
                local config=model.editorconfig or component.editorconfig or {}
                local layer=value(config.layer)
                if type(config.layer)=='table' then layer=config.layer.id or layer end
                chart.track[tostring(childTrack)]={name=tostring(component.name or component.id or childTrack),
                    zindex=layers[layer] or 0,w0thenShow=value((model.properties or {}).showWhen0)==true and 1 or 0}
                local startTime,endTime=model.timeStart or 0,model.timeEnd or MAX_TIME
                assert(finite(startTime) and finite(endTime) and endTime>=startTime, 'Takana：无效轨道起止时间')
                local movement=assert(model.movement, 'Takana：轨道缺少 movement')
                if movement.type=='trackEdgeMovement' then
                    lane(childTrack,'lpos',movement.left,startTime,endTime)
                    lane(childTrack,'rpos',movement.right,startTime,endTime)
                elseif movement.type=='trackDirectMovement' then
                    lane(childTrack,'x',movement.position,startTime,endTime)
                    lane(childTrack,'w',movement.width,startTime,endTime)
                else error('Takana：不支持的轨道运动 '..tostring(movement.type)) end
            elseif model.type=='hit' or model.type=='hold' then
                assert(parent, 'Takana：音符没有所属轨道')
                local first=toTicks(model.timeJudge)
                local note={track=parent,beat=fraction(first),
                    fake=value((model.properties or {}).isDummy)==true and 1 or 0}
                if model.type=='hold' then
                    assert(finite(model.timeEnd) and model.timeEnd>=model.timeJudge, 'Takana：无效 Hold 结束时间')
                    note.type='hold'; note.beat2=fraction(math.max(first+1,toTicks(model.timeEnd)))
                    note.note_head=0; note.wipe_head=0
                else
                    assert(model.hitType=='Tap' or model.hitType=='Slide', 'Takana：不支持的 hitType')
                    note.type=model.hitType=='Slide' and 'wipe' or 'note'
                end
                chart.note[#chart.note+1]=note
            else assert(model.type=='line', 'Takana：不支持的物件 '..tostring(model.type)) end
            if component.children then walk(component.children,childTrack,depth+1) end
        end
    end
    walk(data.components,nil,0)
    local function byBeat(a,b)
        local x,y=a.beat[1]+a.beat[2]/GRID,b.beat[1]+b.beat[2]/GRID
        if x~=y then return x<y end
        if a.track~=b.track then return a.track<b.track end
        return a.type<b.type
    end
    table.sort(chart.note,byBeat); table.sort(chart.event,byBeat)
    return chart
end
return Converter
