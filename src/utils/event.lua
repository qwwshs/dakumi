local event = object:new('event')
local bezier_file = io.open("defaultBezier.txt", "r")  -- 以只读模式打开文件
if bezier_file then
    local content = bezier_file:read("*a")  -- 读取整个文件内容
    bezier_file:close()  -- 关闭文件
    event.bezier = loadstring("return "..content)()
end
if type(event.bezier) ~= "table" then
    event.bezier = {}
end

event.local_event = {} -- 局部event表
event.hold_type = 0 --长条状态 0没放 1头 2尾
event.__index = meta_event.__index
function event:cleanUp() --长条清除
    event.local_event = {}
    event.hold_type = 0
end

function event:getTrans(isevent,t)
    if isevent.trans.type == 'bezier' then
        return bezier(0,1,0,1,isevent.trans.trans,t)
    elseif isevent.trans.type == 'easings' then
        return easings[isevent.trans.easings](t)
    else return 1
    end
end

function event:get(track,isbeat) --得到event此时的宽和高
    local now_w = 0
    local now_x = 0
    local now_x_ed = false --已经计算
    local now_w_ed = false --已经计算
    for i =  #chart.event,1,-1 do --倒着减小计算量
        if now_w_ed and now_x_ed then --计算完成
            break
        end
        if chart.event[i].track == track then
            local beat1 = beat:get(chart.event[i].beat)
            local beat2 = beat:get(chart.event[i].beat2) or beat1
            local isevent = chart.event[i]
            if (beat1 <= isbeat and beat2 > isbeat) or beat2 <= isbeat then
                if isevent.type == "x" and (not now_x_ed) then
                    now_x = isevent.from + (isevent.to-isevent.from) * self:getTrans(isevent,(isbeat-beat1)/(beat2-beat1))
                    now_x_ed = true
                elseif isevent.type == "w" and (not now_w_ed) then
                    now_w = isevent.from + (isevent.to-isevent.from) * self:getTrans(isevent,(isbeat-beat1)/(beat2-beat1))
                    now_w_ed = true
                end
            end
        end
    end
    local track_info = fTrack:get_track_info(track)
    if track_info.type == 'lposrpos' then --将x w 转换为 lpos rpos
        local lpos = now_x
        local rpos = now_w
        now_x = (lpos + rpos) /2
        now_w = rpos - lpos
    end
    return now_x,now_w
end

-- event函数
function event:click(type,pos)  --被点击
    sidebar:to("nil") --界面清除
    --检测区间
    local pos_interval = 20 * math.min(denom.scale,1)
    --根据距离反推出beat
    local event_beat_up = beat:yToBeat(pos - pos_interval)
    local event_beat_down = beat:yToBeat(pos + pos_interval)
    for i = 1,#chart.event do
        local isevent = chart.event[i]
        local beat1 = beat:get(isevent.beat)
        local beat2 = beat:get(isevent.beat2) or beat1
        if isevent.type == type and isevent.track == track.track and
        (math.intersect(beat1,beat2, event_beat_down, event_beat_up)) then
            sidebar.displayed_content = "event"..i
            sidebar:to("event",i)
            event:cleanUp()
            return i
        end
    end
end
function event:delete(type,pos)
    sidebar:to("nil") --界面清除
    --删除检测区间
    local pos_interval = 20 * math.min(denom.scale,1)
    --根据距离反推出beat
    local event_beat_up = beat:yToBeat(pos - pos_interval)
    local event_beat_down = beat:yToBeat(pos + pos_interval)
    for i = 1,#chart.event do
        local isevent = chart.event[i]
        local beat1 = beat:get(isevent.beat)
        local beat2 = beat:get(isevent.beat2) or beat1
        if isevent.track == track.track and isevent.type == type and
        (math.intersect(beat1,beat2, event_beat_down, event_beat_up)) then
            redo:writeRevoke("event delete",isevent)
            table.remove(chart.event, i)
            return
        end
    end
end

function event:place(type,pos)
    --根据距离反推出beat
    local event_beat = beat:toNearby(beat:yToBeat(pos))

    if event.hold_type == 0 then --放置头
            event.local_event = table.copy(meta_event.__index)
            event.local_event.type = type
            event.local_event.track = track.track
            event.local_event.beat = {event_beat[1],event_beat[2],event_beat[3]}
            event.local_event.trans.type = 'easings'
            event.local_event.trans.easings = easings_index

            event.hold_type = 1
            local x,w = event:get(event.local_event.track,beat:get(event.local_event.beat)) --把数值设定为上次event结尾的数值
            if type == "x" then
                event.local_event.from,event.local_event.to = x,x
            else
                event.local_event.from,event.local_event.to = w,w
            end
    elseif event.hold_type == 1 then
        event.local_event.beat2 = {event_beat[1],event_beat[2],event_beat[3]} 
        if beat:get(event.local_event.beat2) <= beat:get(event.local_event.beat) then --尾巴比头早或重叠
            messageBox:add("illegal operation")
            event:cleanUp()
            return false
        else -- 合法操作
            chart.event[#chart.event + 1] = event.local_event
            event.hold_type = 2
        end
    end
    if event.hold_type == 2 then --长条尾放置完成
        --对event进行排序
        local thetable = {} --临时event表
        local theevent = false --得到event编辑的长条索引
        local int_theevent = 1
        local min = #chart.event --设1 event大小最小
        event:sort()
        for i = 1 ,#chart.event do
            if table.eq(chart.event[i],event.local_event) then --表相同
                theevent = true
                int_theevent = i
                break
            end

        end
        redo:writeRevoke("event place",event.local_event)
        sidebar.displayed_content = "event"..int_theevent
        sidebar:to("event",int_theevent)
        event:cleanUp()
    end
end
function event:sort()
    --对event进行排序
    table.sort(chart.event,function(a,b) return beat:get(a.beat) < beat:get(b.beat) end)
end

function event:getHoldTable()
    return event.local_event
end

return event