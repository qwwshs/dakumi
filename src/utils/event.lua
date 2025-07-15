local local_event = {} -- 局部event表
local event_type = 0 --长条状态 0没放 1头 2尾

function event_clean_up() --长条清除
    local_event = {}
    event_type = 0
end

function event_get(track,beat) --得到event此时的宽和高
    local now_w = 0
    local now_x = 0
    local now_x_ed = false --已经计算
    local now_w_ed = false --已经计算
    for i =  #chart.event,1,-1 do --倒着减小计算量
        if now_w_ed and now_x_ed then --计算完成
            break
        end
        if chart.event[i].track == track then
            if (thebeat(chart.event[i].beat) <= beat and thebeat(chart.event[i].beat2) > beat) or thebeat(chart.event[i].beat2) <= beat then
                if chart.event[i].type == "x" and (not now_x_ed) then
                    now_x = bezier(thebeat(chart.event[i].beat),thebeat(chart.event[i].beat2),chart.event[i].from,chart.event[i].to,chart.event[i].trans,beat)
                    now_x_ed = true
                elseif chart.event[i].type == "w" and (not now_w_ed) then
                    now_w = bezier(thebeat(chart.event[i].beat),thebeat(chart.event[i].beat2),chart.event[i].from,chart.event[i].to,chart.event[i].trans,beat)
                    now_w_ed = true
                end
            end
        end
    end
    return now_x,now_w
end

-- event函数
function event_click(type,pos)  --被点击
    sidebar.displayed_content = "nil" --界面清除
    --检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local event_beat_up = y_to_beat(pos - pos_interval)
    local event_beat_down = y_to_beat(pos + pos_interval)
    for i = 1,#chart.event do
        if chart.event[i].type == type and chart.event[i].track == track.track and
        (chart.event[i].beat2 and -- 长条
        (thebeat(chart.event[i].beat) <= event_beat_down and thebeat(chart.event[i].beat2) >= event_beat_down)
        or (thebeat(chart.event[i].beat) <= event_beat_up and thebeat(chart.event[i].beat2) >= event_beat_up)) then
            sidebar.displayed_content = "event"..i
            object_event_edit.load(1200,40,0,30,30) --调用编辑界面
            event_clean_up()
            return i
        end
    end
end
function event_delete(type,pos)
    sidebar.displayed_content = "nil" --界面清除
    --删除检测区间
    local pos_interval = 20 * denom.scale
    --根据距离反推出beat
    local event_beat_up = y_to_beat(pos - pos_interval)
    local event_beat_down = y_to_beat(pos + pos_interval)
    for i = 1,#chart.event do
        if chart.event[i].track == track.track and chart.event[i].type == type and
        (chart.event[i].beat2 and -- 长条
        math.intersect(thebeat(chart.event[i].beat), thebeat(chart.event[i].beat2), event_beat_down, event_beat_up)) then
            object_redo.write_revoke("event delete",chart.event[i])
            table.remove(chart.event, i)
            return
        end
    end
end

function event_place(type,pos)
    --根据距离反推出beat
    local event_beat = y_to_beat(pos)
    local event_min_denom = 1 --假设1最近
    for i = 1, denom.denom do --取分度 哪个近取哪个
        if math.abs(event_beat - (math.floor(event_beat) + i / denom.denom)) < math.abs(event_beat - (math.floor(event_beat) + event_min_denom / denom.denom)) then
            event_min_denom = i
        end
    end
    
    if event_type == 0 then --放置头
            local_event = {
                type = type,
                track = track.track,
                beat = {math.floor(event_beat),event_min_denom,denom.denom},
                from = 0,
                to = 0,
                trans = {[1] = default_bezier[bezier_index][1],[2] = default_bezier[bezier_index][2],[3] = default_bezier[bezier_index][3],[4] = default_bezier[bezier_index][4]}
            }
            event_type = 1
            local x,w = event_get(local_event.track,thebeat(local_event.beat)) --把数值设定为上次event结尾的数值
            if type == "x" then
                local_event.from,local_event.to = x,x
            else
                local_event.from,local_event.to = w,w
            end
    elseif event_type == 1 then
        local_event.beat2 = {math.floor(event_beat),event_min_denom,denom.denom} 
        if thebeat(local_event.beat2) <= thebeat(local_event.beat) then --尾巴比头早或重叠
            messageBox:addMessage("illegal operation")
            event_clean_up()
            return false
        else -- 合法操作
            chart.event[#chart.event + 1] = local_event
            event_type = 2
        end
    end
    if event_type == 2 then --长条尾放置完成
        --对event进行排序
        local thetable = {} --临时event表
        local theevent = false --得到event编辑的长条索引
        local int_theevent = 1
        local min = #chart.event --设1 event大小最小
        event_sort()
        for i = 1 ,#chart.event do
            if table.eq(chart.event[i],local_event) then --表相同
                theevent = true
                int_theevent = i
                break
            end

        end
        object_redo.write_revoke("event place",local_event)
        sidebar.displayed_content = "event"..int_theevent
        object_event_edit.load(1200,40,0,30,30) --调用编辑界面
        event_clean_up()
    end
end
function event_sort()
    --对event进行排序
    table.sort(chart.event,function(a,b) return thebeat(a.beat) < thebeat(b.beat) end)
end

function get_event_table()
    return local_event
end