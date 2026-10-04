-- 每条轨道独立计算效果；起始前取默认值，结束后保留终值。
local ChartService = require('src.services.chartService')
local Event = require('src.models.Event')
local transitions = require('src.utils.event')
local EffectService = {}
local defaults = {note_alpha=100, track_alpha=100, track_line_alpha=100, note_rotate=0, scroll=1, jump=0}
function EffectService:defaults()
    local result = {}
    for key, value in pairs(defaults) do result[key] = value end
    return result
end
-- 自适应积分，分段边界先切开；常速段直接计算，缓动段按误差细分。
local function integrate(fn, a, b)
    if a == b then return 0 end
    local function solve(left, right, fl, fm, fr, whole, epsilon, depth)
        local middle = (left+right)/2
        local fq, ft = fn((left+middle)/2), fn((middle+right)/2)
        local l = (middle-left)*(fl+4*fq+fm)/6
        local r = (right-middle)*(fm+4*ft+fr)/6
        local delta = l+r-whole
        if depth == 0 or math.abs(delta) <= 15*epsilon then return l+r+delta/15 end
        return solve(left,middle,fl,fq,fm,l,epsilon/2,depth-1)
            + solve(middle,right,fm,ft,fr,r,epsilon/2,depth-1)
    end
    local fl, fm, fr = fn(a), fn((a+b)/2), fn(b)
    return solve(a,b,fl,fm,fr,(b-a)*(fl+4*fm+fr)/6,1e-7,12)
end
local function value(entry, t)
    local e = entry.entity
    local first, last = entry.first, entry.last
    if last <= first or t >= last then
        if e:getTransType()=='custom' then
            return e:getFrom()+(e:getTo()-e:getFrom())*transitions:getTrans(e,1)
        end
        return e:getTo()
    end
    return e:getFrom() + (e:getTo()-e:getFrom())
        * transitions:getTrans(e,(t-first)/(last-first))
end
local function find(entries, t)
    local left, right, answer = 1, #entries, 0
    while left <= right do
        local middle = math.floor((left+right)/2)
        if entries[middle].first <= t then answer=middle; left=middle+1
        else right=middle-1 end
    end
    return answer
end

-- 只在谱面变化后编译：读表、实体构造、排序和完整积分不进入逐帧路径。
local cache
local bus = require('src.utils.eventBus')
local function invalidate() cache=nil end
bus:on('chart:mutated', invalidate)
bus:on('chart:changed', invalidate)
bus:on('chart:replaced', invalidate)
local function compiled()
    if cache then return cache end
    local tracks={}
    for i=1, ChartService:getEffectCount() do
        local data=ChartService:getEffect(i)
        local kind=data.type=='rotate' and 'note_rotate' or data.type
        if data.track and defaults[kind]~=nil then
            local lane=tracks[data.track]
            if not lane then
                lane={fields={}, scroll={}, jump={}, targets={}}
                lane.fields.scroll, lane.fields.jump=lane.scroll,lane.jump
                tracks[data.track]=lane
            end
            local list=lane.fields[kind]
            if not list then list={}; lane.fields[kind]=list end
            local entity=Event.new(data)
            list[#list+1]={entity=entity, first=entity:getBeatValue(),
                last=entity:getBeat2Value(), order=i}
        end
    end
    local malody=ChartService:getPreferenceField('motion_mode')=='malody'
    for _, lane in pairs(tracks) do
        for _, entries in pairs(lane.fields) do
            table.sort(entries,function(a,b)
                return a.first < b.first or (a.first==b.first and a.order < b.order)
            end)
        end
        local jumpTotal, jumpDistanceTotal=0,0
        for _, entry in ipairs(lane.jump) do
            jumpTotal=jumpTotal+entry.entity:getTo()
            entry.total=jumpTotal
            -- MC 的毫秒跳变通过触发时的 scroll 转成位移；不能直接加到秒轴积分。
            -- 固定在触发点，后面的 scroll 变化不重新缩放已经发生的 jump。
            local i=find(lane.scroll,entry.first)
            entry.scrollMultiplier=i>0 and value(lane.scroll[i],entry.first) or 1
            jumpDistanceTotal=jumpDistanceTotal+entry.entity:getTo()*entry.scrollMultiplier
            entry.distanceTotal=jumpDistanceTotal
        end
        lane.segments={}
        lane.timeSegments={}
        local timeTotal=0
        local total=0
        for i, entry in ipairs(lane.scroll) do
            local nextEntry=lane.scroll[i+1]
            local stop=nextEntry and nextEntry.first or math.huge
            if stop > entry.first then
                local finish=math.min(stop,math.max(entry.first,entry.last))
                local segment={entry=entry,first=entry.first,last=finish,prefix=total}
                lane.segments[#lane.segments+1]=segment
                total=total+integrate(function(t) return value(entry,t) end,entry.first,finish)
                segment.tail=total
                if stop < math.huge then total=total+(stop-finish)*value(entry,entry.last) end
                if malody then
                    local firstTime=ChartService:toTime(entry.first)
                    local finishTime=ChartService:toTime(finish)
                    local ts={entry=entry,first=firstTime,last=finishTime,prefix=timeTotal}
                    lane.timeSegments[#lane.timeSegments+1]=ts
                    timeTotal=timeTotal+integrate(function(t)
                        return value(entry,ChartService:toBeat(t))
                    end,firstTime,finishTime)
                    ts.tail=timeTotal
                    if stop<math.huge then
                        timeTotal=timeTotal+(ChartService:toTime(stop)-finishTime)*value(entry,entry.last)
                    end
                end

            end
        end
    end
    cache=tracks
    return tracks
end
function EffectService:calculate(trackIds, currentBeat)
    local tracks=compiled()
    local cumulative=ChartService:getPreferenceField('jump_mode')=='cumulative'
    local result={}
    for _, id in ipairs(trackIds) do
        local fields=self:defaults()
        result[id]=fields
        local lane=tracks[id]
        if lane then
            for kind, entries in pairs(lane.fields) do
                local i=find(entries,currentBeat)
                if i>0 then
                    fields[kind]=kind=='jump' and cumulative and entries[i].total
                        or value(entries[i],currentBeat)
                end
            end
        end
    end
    return result
end
-- 每个快照只计算一次当前原函数值；音符端的积分跨帧缓存。
function EffectService:createMotion(trackIds)
    local compiledTracks=compiled()
    local tracks={}
    for _, id in ipairs(trackIds) do tracks[id]=compiledTracks[id] end
    local cumulative=ChartService:getPreferenceField('jump_mode')=='cumulative'
    local malody=ChartService:getPreferenceField('motion_mode')=='malody'
    local timeScale=malody and ChartService:getBpm(1).bpm/60 or 1
    local function primitive(lane,t)
        local segments=lane.segments
        local index=find(segments,t)
        if index==0 then return t end -- 默认 scroll=1
        local s=segments[index]
        local origin=segments[1].first
        if t >= s.last then return origin+s.tail+(t-s.last)*value(s.entry,s.entry.last) end
        return origin+s.prefix+integrate(function(x) return value(s.entry,x) end,s.first,t)
    end
    local function shifted(lane,t)
        local i=find(lane.jump,t)
        if i==0 then return t end
        return t+(cumulative and lane.jump[i].total or value(lane.jump[i],t))
    end
    local function position(lane,t)
        if not malody then return primitive(lane,t) end
        -- Malody 的 scroll 在音频秒轴积分，jump 为触发点 scroll 缩放后的累计毫秒位移。
        -- 两端共用坐标；不会把累计 jump 当成读取未来 scroll 的时间。
        local seconds=ChartService:toTime(t)
        local segments=lane.timeSegments
        local i=find(segments,seconds)
        local p=seconds
        if i>0 then
            local segment=segments[i]
            local origin=segments[1].first
            if seconds>=segment.last then
                p=origin+segment.tail+(seconds-segment.last)*value(segment.entry,segment.entry.last)
            else
                p=origin+segment.prefix+integrate(function(x)
                    return value(segment.entry,ChartService:toBeat(x))
                end,segment.first,seconds)
            end
        end
        local j=find(lane.jump,t)
        local jump=j>0 and (cumulative and lane.jump[j].distanceTotal
            or value(lane.jump[j],t)*lane.jump[j].scrollMultiplier) or 0
        return (p+jump/1000)*timeScale
    end
    local motion={}
    local current={}
    local function targetValue(lane,t)
        local v=lane.targets[t]
        if v==nil then v=position(lane,t); lane.targets[t]=v end
        return v
    end
    function motion:distance(trackId,now,target)
        local lane=tracks[trackId]
        if not lane then return target-now end
        -- Dakumi 保留当前读取时间语义；Malody 使用音符与当前时刻的位移差。
        local entry=current[trackId]
        if not entry or entry.now~=now then
            entry={now=now, value=malody and position(lane,now) or primitive(lane,shifted(lane,now))}
            current[trackId]=entry
        end
        return targetValue(lane,target)-entry.value
    end
    return motion
end
return EffectService
