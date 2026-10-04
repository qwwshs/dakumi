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
function EffectService:calculate(trackIds, currentBeat)
    local result, selected = {}, {}
    local cumulative=ChartService:getPreferenceField('jump_mode')=='cumulative'
    for _, id in ipairs(trackIds) do
        result[id], selected[id] = self:defaults(), {}
    end
    for i = 1, ChartService:getEffectCount() do
        local data = ChartService:getEffect(i)
        -- track 为必填字段，不再把旧的全局效果套到所有轨道。
        local kind=data.type=='rotate' and 'note_rotate' or data.type
        if selected[data.track] and defaults[kind] ~= nil then
            local entity = Event.new(data)
            local first = entity:getBeatValue()
            local previous = selected[data.track][kind]
            if first <= currentBeat and (not previous or first >= previous.first) then
                if kind=='jump' and cumulative then
                    -- 累计模式在起点触发终值，from、持续时间和缓动不参与取值。
                    result[data.track].jump=result[data.track].jump+entity:getTo()
                else
                    selected[data.track][kind] = {entity=entity, first=first}
                end
            end
        end
    end
    for id, fields in pairs(selected) do
        for kind, entry in pairs(fields) do
            local entity, first = entry.entity, entry.first
            local last = entity:getBeat2Value()
            local progress = last <= first and 1 or (currentBeat-first)/(last-first)
            result[id][kind] = entity:getFrom() + (entity:getTo()-entity:getFrom())
                * transitions:getTrans(entity, progress)
        end
    end
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
    if last <= first or t >= last then return e:getTo() end
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

-- 每帧构建一份分段原函数，多个音符共用；不依赖播放方向或帧间累加。
function EffectService:createMotion(trackIds)
    local tracks = {}
    local cumulative=ChartService:getPreferenceField('jump_mode')=='cumulative'
    for _, id in ipairs(trackIds) do tracks[id]={scroll={},jump={}} end
    for i=1, ChartService:getEffectCount() do
        local data=ChartService:getEffect(i)
        local lane=tracks[data.track]
        if lane and (data.type=='scroll' or data.type=='jump') then
            local entity=Event.new(data)
            local list=lane[data.type]
            list[#list+1]={entity=entity, first=entity:getBeatValue(),
                last=entity:getBeat2Value(), order=i}
        end
    end
    for _, lane in pairs(tracks) do
        for _, kind in ipairs({'scroll','jump'}) do
            table.sort(lane[kind],function(a,b)
                return a.first < b.first or (a.first==b.first and a.order < b.order)
            end)
        end
        local jumpTotal=0
        for _, entry in ipairs(lane.jump) do
            jumpTotal=jumpTotal+entry.entity:getTo()
            entry.total=jumpTotal
        end
        lane.segments={}
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
                if stop < math.huge then total=total+(stop-finish)*entry.entity:getTo() end
            end
        end
    end
    local function primitive(lane,t)
        local segments=lane.segments
        local index=find(segments,t)
        if index==0 then return t end -- 默认 scroll=1
        local s=segments[index]
        local origin=segments[1].first
        if t >= s.last then return origin+s.tail+(t-s.last)*s.entry.entity:getTo() end
        return origin+s.prefix+integrate(function(x) return value(s.entry,x) end,s.first,t)
    end
    local function shifted(lane,t)
        local i=find(lane.jump,t)
        if i==0 then return t end
        return t+(cumulative and lane.jump[i].total or value(lane.jump[i],t))
    end
    local motion={}
    function motion:distance(trackId,now,target)
        local lane=tracks[trackId]
        if not lane then return target-now end
        -- 只修正当前读取时间；不能提前读取音符时刻尚未触发的 jump。
        return primitive(lane,target)-primitive(lane,shifted(lane,now))
    end
    return motion
end
return EffectService
