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
event.__index = {
    type = 'x',
    transtype = 'bezier',
    track = 0,
    beat = {0,0,1},
    beat2 = {0,0,2},
    from = 0,
    to = 0,
    trans = {1,1,1,1}
}
function event:cleanUp() --长条清除
    event.local_event = {}
    event.hold_type = 0
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
            if (beat:get(chart.event[i].beat) <= isbeat and beat:get(chart.event[i].beat2) > isbeat) or beat:get(chart.event[i].beat2) <= isbeat then
                if chart.event[i].type == "x" and (not now_x_ed) then
                    now_x = bezier(beat:get(chart.event[i].beat),beat:get(chart.event[i].beat2),chart.event[i].from,chart.event[i].to,chart.event[i].trans,isbeat)
                    now_x_ed = true
                elseif chart.event[i].type == "w" and (not now_w_ed) then
                    now_w = bezier(beat:get(chart.event[i].beat),beat:get(chart.event[i].beat2),chart.event[i].from,chart.event[i].to,chart.event[i].trans,isbeat)
                    now_w_ed = true
                end
            end
        end
    end
    return now_x,now_w
end

-- event函数
function event:click(type,pos)  --被点击
    sidebar.displayed_content = "nil" --界面清除
    --检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local event_beat_up = beat:yToBeat(pos - pos_interval)
    local event_beat_down = beat:yToBeat(pos + pos_interval)
    for i = 1,#chart.event do
        if chart.event[i].type == type and chart.event[i].track == track.track and
        (chart.event[i].beat2 and -- 长条
        (beat:get(chart.event[i].beat) <= event_beat_down and beat:get(chart.event[i].beat2) >= event_beat_down)
        or (beat:get(chart.event[i].beat) <= event_beat_up and beat:get(chart.event[i].beat2) >= event_beat_up)) then
            sidebar.displayed_content = "event"..i
            sidebar:to("event",i)
            event:cleanUp()
            return i
        end
    end
end
function event:delete(type,pos)
    sidebar.displayed_content = "nil" --界面清除
    --删除检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local event_beat_up = beat:yToBeat(pos - pos_interval)
    local event_beat_down = beat:yToBeat(pos + pos_interval)
    for i = 1,#chart.event do
        if chart.event[i].track == track.track and chart.event[i].type == type and
        (chart.event[i].beat2 and -- 长条
        math.intersect(beat:get(chart.event[i].beat), beat:get(chart.event[i].beat2), event_beat_down, event_beat_up)) then
            object_redo.write_revoke("event delete",chart.event[i])
            table.remove(chart.event, i)
            return
        end
    end
end

function event:place(type,pos)
    --根据距离反推出beat
    local event_beat = beat:yToBeat(pos)
    local event_min_denom = 1 --假设1最近
    for i = 1, denom.denom do --取分度 哪个近取哪个
        if math.abs(event_beat - (math.floor(event_beat) + i / denom.denom)) < math.abs(event_beat - (math.floor(event_beat) + event_min_denom / denom.denom)) then
            event_min_denom = i
        end
    end
    
    if event.hold_type == 0 then --放置头
            event.local_event = {
                type = type,
                track = track.track,
                beat = {math.floor(event_beat),event_min_denom,denom.denom},
                from = 0,
                to = 0,
                trans = {[1] = event.bezier[bezier_index][1],[2] = event.bezier[bezier_index][2],[3] = event.bezier[bezier_index][3],[4] = event.bezier[bezier_index][4]}
            }
            event.hold_type = 1
            local x,w = event:get(event.local_event.track,beat:get(event.local_event.beat)) --把数值设定为上次event结尾的数值
            if type == "x" then
                event.local_event.from,event.local_event.to = x,x
            else
                event.local_event.from,event.local_event.to = w,w
            end
    elseif event.hold_type == 1 then
        event.local_event.beat2 = {math.floor(event_beat),event_min_denom,denom.denom} 
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
        object_redo.write_revoke("event place",event.local_event)
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