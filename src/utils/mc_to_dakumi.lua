function mc_to_takumi(mc) --malody的转换函数 silde模式mod是7 key是0
    local mc_tab,pos,err = dkjson.decode(mc, 1, nil) 
    local chart_tab = table.copy(meta_chart.__index)
    if (not err) and mc_tab.meta.mode == 0 then --key
        chart_tab.info.chartor = mc_tab.meta.chartor
        chart_tab.info.artist = mc_tab.meta.song.artist
        chart_tab.info.song_name = mc_tab.meta.song.title
        chart_tab.info.chart_name = mc_tab.meta.version
        chart_tab.offset = mc_tab.note[#mc_tab.note].offset
        --bpmlist
        for i = 1,#mc_tab.time do
            chart_tab.bpm_list[#chart_tab.bpm_list + 1] = {
                beat = {mc_tab.time[i].beat[1],mc_tab.time[i].beat[2],mc_tab.time[i].beat[3]},
                bpm = mc_tab.time[i].bpm,
            }
        end
        local bpmlist = {} 
        while #chart_tab.bpm_list > 0 do
            local bpm_beat_min = 1
            for i = 1,  #chart_tab.bpm_list  do
                if beat:get(chart_tab.bpm_list[i].beat) < beat:get(chart_tab.bpm_list[bpm_beat_min].beat) then
                    bpm_beat_min = i
                end
            end
            bpmlist[#bpmlist + 1] = chart_tab.bpm_list[bpm_beat_min]
            table.remove(chart_tab.bpm_list,bpm_beat_min)
        end
        for i = 1,#bpmlist do
            chart_tab.bpm_list[i] = bpmlist[i]
        end

        --先写轨道
        for i = 1,mc_tab.meta.mode_ext.column do
            chart_tab.event[#chart_tab.event + 1] = {
                type = 'x',
                track = i,
                beat = {0,0,1},
                beat2 = {0,1,4},
                from = ((i / mc_tab.meta.mode_ext.column) - (1 / (mc_tab.meta.mode_ext.column *2))) * 100,
                to = ((i / mc_tab.meta.mode_ext.column) - (1 / (mc_tab.meta.mode_ext.column *2))) * 100,
                trans = {0,0,1,1}
            }
            chart_tab.event[#chart_tab.event + 1] = {
                type = 'w',
                track = i,
                beat = {0,0,1},
                beat2 = {0,1,4},
                from = 1 / mc_tab.meta.mode_ext.column * 100,
                to = 1 / mc_tab.meta.mode_ext.column * 100,
                trans = {0,0,1,1}
            }
        end
        --对event进行排序
        local thetable = {} --临时event表
        while #chart_tab.event > 0 do
            local min = 1 --设1 event大小最小
            for i = 1 ,#chart_tab.event do
                if beat:get(chart_tab.event[i].beat) < beat:get(chart_tab.event[min].beat) then
                    min = i
                end
            end
    
            thetable[#thetable + 1] = chart_tab.event[min]
            table.remove(chart_tab.event,min)
        end
        chart_tab.event = thetable
        --再写音符
        for i = 1,#mc_tab.note -1 do --减去1是因为最后一个note是装信息的
            if type(mc_tab.note[i].endbeat) == 'table' then --长条
                chart_tab.note[#chart_tab.note + 1] = {
                    type = "hold",
                    track = mc_tab.note[i].column + 1,
                    beat = {mc_tab.note[i].beat[1],mc_tab.note[i].beat[2],mc_tab.note[i].beat[3]},
                    beat2 = {mc_tab.note[i].endbeat[1],mc_tab.note[i].endbeat[2],mc_tab.note[i].endbeat[3]},
                }
            else
                chart_tab.note[#chart_tab.note + 1] = {
                    type = "note",
                    track = mc_tab.note[i].column + 1,
                    beat = {mc_tab.note[i].beat[1],mc_tab.note[i].beat[2],mc_tab.note[i].beat[3]},
                }
            end
        end
        local local_tab = {}
        --对note进行排序
        local thetable = {} --临时note表
    
        while #chart_tab.note > 0 do
            local min = 1 --设1 note大小最小
            for i = 1 ,#chart_tab.note do
                if beat:get(chart_tab.note[i].beat) < beat:get(chart_tab.note[min].beat) then
                    min = i
                end
            end
            thetable[#thetable + 1] = chart_tab.note[min]
            table.remove(chart_tab.note,min)
        end
        chart_tab.note = thetable
        return chart_tab
    elseif (not err) and mc_tab.meta.mode == 7 then --slide
        chart_tab.info.chartor = mc_tab.meta.chartor
        chart_tab.info.artist = mc_tab.meta.song.artist
        chart_tab.info.song_name = mc_tab.meta.song.title
        chart_tab.info.chart_name = mc_tab.meta.version
        chart_tab.offset = mc_tab.note[#mc_tab.note].offset
        --bpmlist
        for i = 1,#mc_tab.time do
            chart_tab.bpm_list[#chart_tab.bpm_list + 1] = {
                beat = {mc_tab.time[i].beat[1],mc_tab.time[i].beat[2],mc_tab.time[i].beat[3]},
                bpm = mc_tab.time[i].bpm,
            }
        end
        local bpmlist = {} 
        while #chart_tab.bpm_list > 0 do
            local bpm_beat_min = 1
            for i = 1,  #chart_tab.bpm_list  do
                if beat:get(chart_tab.bpm_list[i].beat) < beat:get(chart_tab.bpm_list[bpm_beat_min].beat) then
                    bpm_beat_min = i
                end
            end
            bpmlist[#bpmlist + 1] = chart_tab.bpm_list[bpm_beat_min]
            table.remove(chart_tab.bpm_list,bpm_beat_min)
        end
        for i = 1,#bpmlist do
            chart_tab.bpm_list[i] = bpmlist[i]
        end
        --先写轨道
        local track = {}
        local track_index = {} --对应的索引
        for i = 1, #mc_tab.note - 1 do
            if type(mc_tab.note[i].w) ~= 'number' then --w默认大小 
                mc_tab.note[i].w = 48
            end
            --写入track表格
            if not track[mc_tab.note[i].x..","..mc_tab.note[i].w] then
                track[mc_tab.note[i].x..","..mc_tab.note[i].w] = {mc_tab.note[i].x,mc_tab.note[i].w,#track_index + 1} 
                track_index[#track_index + 1] = mc_tab.note[i].x..","..mc_tab.note[i].w
            end
        end
        --写轨道
        for i = 1,#track_index do
            chart_tab.event[#chart_tab.event + 1] = {
                type = 'x',
                track = i,
                beat = {0,0,1},
                beat2 = {0,1,4},
                from = track[track_index[i]][1]/255 * 100,
                to = track[track_index[i]][1]/255 * 100,
                trans = {0,0,1,1}
            }
            chart_tab.event[#chart_tab.event + 1] = {
                type = 'w',
                track = i,
                beat = {0,0,1},
                beat2 = {0,1,4},
                from = track[track_index[i]][2]/255 * 100,
                to = track[track_index[i]][2]/255 * 100,
                trans = {0,0,1,1}
            }
            log(track[track_index[i]][2])
        end
        --对event进行排序
        local thetable = {} --临时event表
        while #chart_tab.event > 0 do
            local min = 1 --设1 event大小最小
            for i = 1 ,#chart_tab.event do
                if beat:get(chart_tab.event[i].beat) < beat:get(chart_tab.event[min].beat) then
                    min = i
                end
            end
            
            thetable[#thetable + 1] = chart_tab.event[min]
            table.remove(chart_tab.event,min)
        end
        chart_tab.event = thetable

        --写入note
        for i = 1,#mc_tab.note -1 do --减去1是因为最后一个note是装信息的
            if type(mc_tab.note[i].type) == 'number' then --wipe
                chart_tab.note[#chart_tab.note + 1] = {
                    type = "wipe",
                    track = track[mc_tab.note[i].x..","..mc_tab.note[i].w][3],
                    beat = {mc_tab.note[i].beat[1],mc_tab.note[i].beat[2],mc_tab.note[i].beat[3]},
                }
            elseif type(mc_tab.note[i].seg) == 'table' then --slide
                local seg_beat = beat:add(mc_tab.note[i].beat,mc_tab.note[i].seg[#mc_tab.note[i].seg].beat) --beat2
                chart_tab.note[#chart_tab.note + 1] = {
                    type = "hold",
                    track = track[mc_tab.note[i].x..","..mc_tab.note[i].w][3],
                    beat = {mc_tab.note[i].beat[1],mc_tab.note[i].beat[2],mc_tab.note[i].beat[3]},
                    beat2 = table.copy(seg_beat),
                }
            else --note
                chart_tab.note[#chart_tab.note + 1] = {
                    type = "note",
                    track = track[mc_tab.note[i].x..","..mc_tab.note[i].w][3],
                    beat = {mc_tab.note[i].beat[1],mc_tab.note[i].beat[2],mc_tab.note[i].beat[3]},
                }
            end
        end
        local local_tab = {}
        --对note进行排序
        local thetable = {} --临时note表
    
        while #chart_tab.note > 0 do
            local min = 1 --设1 note大小最小
            for i = 1 ,#chart_tab.note do
                if beat:get(chart_tab.note[i].beat) < beat:get(chart_tab.note[min].beat) then
                    min = i
                end
            end
            thetable[#thetable + 1] = chart_tab.note[min]
            table.remove(chart_tab.note,min)
        end
        chart_tab.note = thetable
        return chart_tab
    end
end