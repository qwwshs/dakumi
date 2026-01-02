local fTrack = object:new('fTrack')
function fTrack:get_track_offset()
    return (play.layout.demo.w - 100*settings.track_w_scale) / 2
end
function fTrack:to_play_track(x,w)
    x = x or 0
    w = w  or 0
    return (x + chart.preference.x_offset -w /2) / chart.preference.event_scale * 100 *settings.track_w_scale + fTrack:get_track_offset(),
    w*settings.track_w_scale / chart.preference.event_scale * 100
end
function fTrack:to_play_original_track(x,w) --废弃 不用
    x = x or 0
    w = w  or 0
    
    return (x-w /2) / chart.preference.event_scale * 100 *settings.track_w_scale + fTrack:get_track_offset(),
    w*settings.track_w_scale / chart.preference.event_scale * 100
end

function fTrack:to_play_track_x(x)
    x = x or 0
    return (x+ chart.preference.x_offset)/ chart.preference.event_scale * 100 *settings.track_w_scale + fTrack:get_track_offset()
end
function fTrack:to_play_track_w(w)
    w = w or 0
    return w*settings.track_w_scale / chart.preference.event_scale * 100
end
function fTrack:to_chart_track(x) --play区域的x转谱面轨道x
    return (chart.preference.event_scale / play.layout.demo.w * x) - chart.preference.x_offset
end
function fTrack:track_get_max_track() --得到最大的轨道
    local max_track = 0
    for i = 1, #chart.event do
        if chart.event[i].track > max_track then
            max_track = chart.event[i].track
        end
    end
    return max_track
end
function fTrack:track_get_near_fence() --得到附近的栅栏
    local min = 1
    for i = 1,track.fence do
        if math.abs((play.layout.demo.w / track.fence * min)  - mouse.x)> math.abs((play.layout.demo.w / track.fence * i)  - mouse.x) then
            min = i
        end
    end
    return min
end
function fTrack:track_get_near_fence_x() --得到附近的栅栏所对应的play区域的x
    local pos = 0
    if track.fence == 0 then
        pos = (mouse.x - fTrack:get_track_offset()) / settings.track_w_scale / 100 * chart.preference.event_scale
    else
        pos = (chart.preference.event_scale / track.fence * fTrack:track_get_near_fence()) - chart.preference.x_offset
    end
    return pos
end
function fTrack:track_get_all_track() --得到所有的轨道
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

function fTrack:get_track_info(track)
    if not chart.track[tostring(track)] then
        chart.track[tostring(track)] = {
                name = '',
                w0thenShow = 0,
                type = 'xw'
            }
    end
    return chart.track[tostring(track)]
end
return fTrack