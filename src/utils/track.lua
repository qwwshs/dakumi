local function get_track_offset()
    return (900 - 100*settings.track_w_scale) / 2
end
function to_play_track(x,w)
    x = x or 0
    w = w or 0
    
    return (x + chart.preference.x_offset -w/2) *settings.track_w_scale + get_track_offset(),w*settings.track_w_scale
end
function to_play_original_track(x,w)
    x = x or 0
    w = w or 0
    
    return (x-w/2) *settings.track_w_scale + get_track_offset(),w*settings.track_w_scale
end

function to_play_track_original_x(x)
    x = x or 0
    return (x+ chart.preference.x_offset)*settings.track_w_scale + get_track_offset()
end
function to_play_track_original_w(w)
    w = w or 0
    return w*settings.track_w_scale
end
function to_chart_track(x)
    return (x- chart.preference.x_offset * settings.track_w_scale - get_track_offset()) / settings.track_w_scale
end
function track_get_max_track() --得到最大的轨道
    local max_track = 0
    for i = 1, #chart.event do
        if chart.event[i].track > max_track then
            max_track = chart.event[i].track
        end
    end
    return max_track
end
function track_get_near_fence() --得到附近的栅栏
    local min = 1
    for i = 1,track.fence do
        if math.abs((900 / track.fence * min)  - mouse.x)> math.abs((900 / track.fence * i)  - mouse.x) then
            min = i
        end
    end
    return min
end
function track_get_near_fence_x() --得到附近的栅栏所对应的play区域的x
    local pos = 0
    if track.fence == 0 then
        pos = (mouse.x - get_track_offset()) / settings.track_w_scale
    else
        pos = (100 / track.fence * track_get_near_fence()) - chart.preference.x_offset
    end
    return pos
end
function track_get_all_track() --得到所有的轨道
    local temp_track = {}
    for i = 1,#chart.event do
        temp_track[chart.event[i].track] = 1
    end
    for i = 1,#chart.note do
        temp_track[chart.note[i].track] = 1
    end
    local temp2_track = {} --整理temp_track
    for i,v in pairs(temp_track) do
        temp2_track[#temp2_track + 1] = i
    end
    table.sort(temp2_track)
    return temp2_track
end
