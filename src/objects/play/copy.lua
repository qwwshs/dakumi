--note和event的复制粘贴
local mouse_start_pos = {x = 0 ,y = 0 } --鼠标按下的时候的x和y
local meta_copy_tab = {}
local copy_tab = {
    note = {},
    event = {},
    type = "", --类型是复制 还是裁剪
    pos = "", --位置是游玩区域还是编辑区域
}
function copy_sub(new_table,type)
    for i, v in ipairs(copy_tab[type]) do
        if table.eq(copy_tab[type][i],new_table) then
            table.remove(copy_tab[type],i)
        end
    end
end
function copy_add(new_table,type)
    for i = 1, #copy_tab[type] do
        if table.eq(copy_tab[type][i],new_table) then --去重
            return
        end
    end
    copy_tab[type][#copy_tab[type] + 1] = new_table
    table.sort(copy_tab[type],function(a,b) return thebeat(a.beat) < thebeat(b.beat) end)
end
function copy_exist(new_table,type)
    for i = 1, #copy_tab[type] do
        if table.eq(copy_tab[type][i],new_table) then --去重
            return true
        end
    end
    return false
end
function get_copy()
    return copy_tab
end

object_copy = {
    draw = function(posx) --偏移值
        posx = posx or 900
        local note_h = settings.note_height --25 * denom.scale
        local note_w = 75 
        if love.mouse.isDown(1) then --复制框
            love.graphics.setColor(0,1,1,0.4)
            love.graphics.rectangle("fill",mouse_start_pos.x - 900 + posx,mouse_start_pos.y,mouse.x - mouse_start_pos.x ,mouse.y - mouse_start_pos.y)
            love.graphics.setColor(0,1,1,1)
            love.graphics.rectangle("line",mouse_start_pos.x -  900 + posx,mouse_start_pos.y,mouse.x - mouse_start_pos.x,mouse.y - mouse_start_pos.y)
        end
        if copy_tab.type ~= "x" then
            love.graphics.setColor(0,1,1,0.5)
        else
            love.graphics.setColor(1,1,1,0.5)
        end
        if room_pos == 'tracks_edit' then
            for i=1,#copy_tab.note do
                local pos = {} --默认不显示
                for k = 1,#Gtracks.table do
                    if Gtracks.table[k] ==copy_tab.note[i].track then
                        pos[#pos + 1] =  20+(k-1 + tracks_edit_x_move)*300
                    end
                end
                local y = beat_to_y(copy_tab.note[i].beat)
                local y2 = y - note_h
                if copy_tab.note[i].type == "hold" then
                    y2 = beat_to_y(copy_tab.note[i].beat2)
                end
                    if y > 0 - note_h  and y2 < WINDOW.h + note_h then
                        for k = 1,#pos do
                            love.graphics.rectangle("fill",pos[k],y2,75,y - y2)
                        end
                    end

            end

            for i=1,#copy_tab.event do
                local pos = {} --默认不显示
                for k = 1,#Gtracks.table do
                    if Gtracks.table[k] ==copy_tab.event[i].track then
                        pos[#pos + 1] =  20+(k-1 + tracks_edit_x_move)*300
                    end
                end
                local y = beat_to_y(copy_tab.event[i].beat)
                local y2 = beat_to_y(copy_tab.event[i].beat2)
                local x_pos = 100
                if copy_tab.event[i].type == "w" then
                    x_pos = 200
                end
                    if y > 0 - note_h  and y2 < WINDOW.h + note_h then
                        for k = 1,#pos do
                            love.graphics.rectangle("fill",pos[k] + x_pos,y2,75,y - y2)
                        end
                    end
            end

            return
        end
            --对所选标记   
            for i=1,#copy_tab.note do

                local y = beat_to_y(copy_tab.note[i].beat)
                local y2 = y - note_h
                if copy_tab.note[i].type == "hold" then
                    y2 = beat_to_y(copy_tab.note[i].beat2)
                end

                if copy_tab.note[i].track == track.track then
                    if y > 0 - note_h  and y2 < WINDOW.h + note_h then
                        love.graphics.rectangle("fill",posx,y2,75,y - y2)
                    end
                end

            end
        if copy_tab.pos == "play" then
            for i = 1,#copy_tab.note do
                local x,w = to_play_track(all_track_pos[copy_tab.note[i].track].x,all_track_pos[copy_tab.note[i].track].w)
                x = x + w /2
                if w > 40 and copy_tab.note[i].type ~= "wipe" then --增加间隙
                    w = w - 20
                elseif w <= 40 and w > 20 and copy_tab.note[i].type ~= "wipe" then
                    w = 20
                elseif w > 60 and copy_tab.note[i].type == "wipe" then --增加间隙
                    w = w - 30
                elseif w <= 60 and w > 30 and copy_tab.note[i].type == "wipe" then
                    w = 30
                end
                x = x - w /2
                local y = beat_to_y(copy_tab.note[i].beat)
                local y2 = y
                if copy_tab.note[i].type == "hold" then
                    y2 = beat_to_y(copy_tab.note[i].beat2)
                end
                if y <  0 -  note_h then break end --超出范围
                if (not  (y2 > settings.judge_line_y + note_h or y < 0 -  note_h)) and (not  (y > settings.judge_line_y and chart.note[i].fake == 1  ) )then
                    if y ~= y2 and y > settings.judge_line_y then y = settings.judge_line_y end --hold头保持在线上
    
                    if copy_tab.note[i].type ~= "hold" then
                        love.graphics.rectangle("fill",x,y-note_h,w,note_h)
                    else --hold
                        love.graphics.rectangle("fill",x,y,w,y2 - y)
                    end
                end
    
            end
        end
        for i=1,#copy_tab.event do

            local y = beat_to_y(copy_tab.event[i].beat)
            local y2 = beat_to_y(copy_tab.event[i].beat2)
            local x_pos = posx + 100
            if copy_tab.event[i].type == "w" then
                x_pos = posx + 200
            end

            if copy_tab.event[i].track == track.track then
                if y > 0 - note_h  and y2 < WINDOW.h + note_h then
                    love.graphics.rectangle("fill",x_pos,y2,75,y - y2)
                end
            end
        end

    end,
    update = function(dt)

    end,
    mousepressed = function(x,y,button)
        if love.mouse.isDown(2) then --单选
            if x > 900 + 100 and x <= 900 + 200 then
                if copy_exist(chart.event[event_click("x",mouse.y)],"event") then --存在就取消勾选
                    copy_sub(chart.event[event_click("x",mouse.y)],"event")
                else
                    copy_add(chart.event[event_click("x",mouse.y)],"event")
                end
            elseif x > 900 + 200 and x <= 1200 then
                if copy_exist(chart.event[event_click("w",mouse.y)],"event") then --存在就取消勾选
                    copy_sub(chart.event[event_click("w",mouse.y)],"event")
                else
                    copy_add(chart.event[event_click("w",mouse.y)],"event")
                end
            elseif x <= 900 + 100 then
                if copy_exist(chart.note[note_click(mouse.y)],"note") then --存在就取消勾选
                    copy_sub(chart.note[note_click(mouse.y)],"note")
                else
                    copy_add(chart.note[note_click(mouse.y)],"note")
                end
            end
            messageBox:add("add copy")

            if #copy_tab.event >0 then
                sidebar:to('events')
            end
        end

        if not love.mouse.isDown(1) then
            return
        end
        mouse_start_pos = {x = mouse.x, y = mouse.y}
    end,
    mousereleased = function(x,y)
        --松手＋shift确认选中
        if not ((iskeyboard.lshift or iskeyboard.rshift ) and love.mouse.isDown(1) ) then
            return
        end
        copy_tab = {note = {},event = {}}
        local min_x = to_play_track(to_chart_track(math.min(x,mouse_start_pos.x)),1)
        local max_x = to_play_track(to_chart_track(math.max(x,mouse_start_pos.x)),1)
        local min_y_beat = y_to_beat(math.max(y,mouse_start_pos.y))
        local max_y_beat = y_to_beat(math.min(y,mouse_start_pos.y))  --这引擎y是向下增长的 服了 beat是向上增长的 所以要取反

        if x < 900 or mouse_start_pos.x < 900  then --在note轨道 play区域
            copy_tab.pos = 'play'
            --先for循环记录此刻在游玩区域的轨道
            local local_track = {} --记录表
            for i = 1,#chart.event do --点击轨道进入轨道的编辑事件
                local track_x,track_w = to_play_track(event_get(chart.event[i].track,beat.nowbeat))
                if not (max_x < track_x or track_x + track_w < min_x) then
                    local_track[chart.event[i].track] = true
                end
                if thebeat(chart.event[i].beat) > max_y_beat then
                    break
                end
            end

            for i = 1,#chart.note do
                local isbeat = thebeat(chart.note[i].beat)
                local isbeat2 = isbeat
                if chart.note[i].type == 'hold' then
                    isbeat2 = thebeat(chart.note[i].beat2)
                end

                if (not (max_y_beat < isbeat or isbeat2 < min_y_beat)) and local_track[chart.note[i].track] then --这引擎y是向下增长的 服了
                    copy_tab.note[#copy_tab.note + 1] = table.copy(chart.note[i])

                end
                if isbeat > max_y_beat then
                    break
                end
            end

            for i = 1,#chart.event do --用于完全复制
                local isbeat = thebeat(chart.event[i].beat)
                local isbeat2 = thebeat(chart.event[i].beat2)
                if (not (max_y_beat < isbeat or isbeat2 < min_y_beat)) and local_track[chart.event[i].track]  then
                    copy_tab.event[#copy_tab.event + 1] = table.copy(chart.event[i])
                end
                if thebeat(chart.event[i].beat) > max_y_beat then
                    break
                end
            end

            return 
        end
        
        if not (max_x < 900 or 900 + 100 < min_x) then --在note轨道
            for i = 1,#chart.note do
                local isbeat = thebeat(chart.note[i].beat)
                local isbeat2 = isbeat
                if chart.note[i].type == 'hold' then
                    isbeat2 = thebeat(chart.note[i].beat2)
                end

                if (not (max_y_beat < isbeat or isbeat2 < min_y_beat)) and track.track == chart.note[i].track then --这引擎y是向下增长的 服了
                    copy_tab.note[#copy_tab.note + 1] = table.copy(chart.note[i])

                end
                if isbeat > max_y_beat then
                    break
                end
            end

        end

        if not (max_x < 900 + 100 or 1200 < min_x) then --在event轨道
            for i = 1,#chart.event do
                local event_x_min = 900 + 100
                local event_x_max = 900 + 200
                if chart.event[i].type == "w" then
                    event_x_min = 900 + 200
                    event_x_max = 1200
                end
                if not (max_x < event_x_min or event_x_max < min_x) then
                    local isbeat = thebeat(chart.event[i].beat)
                    local isbeat2 = thebeat(chart.event[i].beat2)
                    if (not (max_y_beat < isbeat or isbeat2 < min_y_beat)) and track.track == chart.event[i].track then
                        copy_tab.event[#copy_tab.event + 1] = table.copy(chart.event[i])
                    end
                    
                end
                if thebeat(chart.event[i].beat) > max_y_beat then
                    break
                end
            end
        end
        if #copy_tab.event >0 then
            sidebar:to('events')
        end
    end,
    wheelmoved = function(x,y)
        --beat更改
        local temp = settings.contact_roller--临时数值

        music_play = false
        if y > 0 then
            temp = temp / denom.denom
        else
            temp = -temp/ denom.denom
        end
        local y_beat = temp
        
        mouse_start_pos.y = mouse_start_pos.y + beat_to_y(0) - beat_to_y(y_beat)
    end,
    keyboard = function(key)
        if (iskeyboard.lshift or iskeyboard.rshift) and mouse.down then
            object_copy.mousereleased(mouse.x,mouse.y)
        end
        
        if not isctrl then
            return
        end
        if key == "c" then
            copy_tab.type = "c"
        elseif key == "x" then
            copy_tab.type = "x"
        elseif key == "d" then
            sidebar.displayed_content = "nil"
            local local_tab = {}
            if copy_tab.pos ~= 'play' or (copy_tab.pos == 'play' and iskeyboard.a) then
                object_redo.write_revoke("copy delete",table.copy(copy_tab))
            else
                object_redo.write_revoke("copy delete",{note = table.copy(copy_tab.note),event = {}})

            end

            for i = 1,#chart.note do
                if not table.eq(copy_tab.note[1],chart.note[i]) then
                    local_tab[#local_tab + 1] = chart.note[i]
                else 
                    table.remove(copy_tab.note,1)
                end
            end
            chart.note = table.copy(local_tab)

            local_tab = {}
            if copy_tab.pos ~= 'play' or (copy_tab.pos == 'play' and iskeyboard.a) then -- a完全复制
                for i = 1,#chart.event do
                    if not table.eq(copy_tab.event[1],chart.event[i]) then
                        local_tab[#local_tab + 1] = chart.event[i]
                    else 
                        table.remove(copy_tab.event,1)
                    end
                end
                chart.event = table.copy(local_tab)
            end

            
            copy_tab = {
                note = {},
                event = {},
                type = "", --类型是复制 还是裁剪
                pos = "", --位置是游玩区域还是编辑区域
            }

        elseif key == "v" or key == "b" or key == "n" or key == "m" then
            local copy_tab2 = table.copy(copy_tab)
                        --先对表进行处理
            local min_track
            if copy_tab2.note[1] then
                min_track = copy_tab2.note[1].track
            end
            if copy_tab2.event[1] then
                min_track = copy_tab2.event[1].track
            end
            for i = 1,#copy_tab2.note do
                if min_track > copy_tab2.note[i].track then
                    min_track = copy_tab2.note[i].track
                end
            end
            for i = 1,#copy_tab2.event do
                if min_track > copy_tab2.event[i].track then
                    min_track = copy_tab2.event[i].track
                end
            end

            sidebar.displayed_content = "nil"
            local to_beat = to_nearby_Beat(y_to_beat(mouse.y))

            local frist_beat = {0,0,4}  --作为基准
            if copy_tab.note[1] and copy_tab.event[1] and thebeat(copy_tab.note[1].beat) <= thebeat(copy_tab.event[1].beat) then
                frist_beat = copy_tab.note[1].beat
            elseif copy_tab.note[1] and copy_tab.event[1] and thebeat(copy_tab.note[1].beat) > thebeat(copy_tab.event[1].beat) then
                frist_beat = copy_tab.event[1].beat
            elseif (not copy_tab.note[1]) and copy_tab.event[1] then
                frist_beat = copy_tab.event[1].beat
            elseif copy_tab.note[1] and (not copy_tab.event[1]) then
                frist_beat = copy_tab.note[1].beat
            end

            if copy_tab.note[1] and copy_tab.pos == 'play' and not iskeyboard.a then --不完全复制
                frist_beat = copy_tab.note[1].beat
            end
            for i = 1, #copy_tab2.note do --轨道修改
                if copy_tab.pos ~= 'play' then
                    copy_tab2.note[i].track = track.track
                end
                copy_tab2.note[i].beat = beat_add(beat_sub(copy_tab2.note[i].beat,frist_beat),to_beat)
                if copy_tab2.note[i].type == "hold" then
                    copy_tab2.note[i].beat2 = beat_add(beat_sub(copy_tab2.note[i].beat2,frist_beat),to_beat)
                end
                if key == "n" then --对所有轨道增加
                    local max_track = track_get_max_track() + 1
                    copy_tab2.note[i].track = max_track + copy_tab2.note[i].track - min_track
                end
            end
            for i = 1, #copy_tab2.event do
                if copy_tab.pos ~= 'play' then
                    copy_tab2.event[i].track = track.track
                end
                copy_tab2.event[i].beat = beat_add(beat_sub(copy_tab2.event[i].beat,frist_beat),to_beat)
                copy_tab2.event[i].beat2 = beat_add(beat_sub(copy_tab2.event[i].beat2,frist_beat),to_beat)
                if key == "b" and copy_tab2.event[i].type == "x" then --取反
                    copy_tab2.event[i].from = 100 - copy_tab2.event[i].from
                    copy_tab2.event[i].to = 100 - copy_tab2.event[i].to
                end
                if key == "n" then --对所有轨道增加
                    local max_track = track_get_max_track() + 1
                    copy_tab2.event[i].track = max_track + copy_tab2.event[i].track - min_track
                end
            end
            if key == "n" or key == "m" then
                local pos = 0 --鼠标所在位置
                pos = track_get_near_fence_x()

                for i = 1,#copy_tab2.event do
                    --处理一下位置
                    if copy_tab2.event[i].type == "x" then
                        copy_tab2.event[i].to = copy_tab2.event[i].to - copy_tab2.event[i].from + pos
                        copy_tab2.event[i].from = pos
                    end
                end
            end
            --写入谱面内
            for i = 1, #copy_tab2.note do
                chart.note[#chart.note + 1] = table.copy(copy_tab2.note[i])
            end
            if copy_tab.pos ~= 'play' or (copy_tab.pos == 'play' and iskeyboard.a) then -- a完全复制
                for i = 1, #copy_tab2.event do
                    chart.event[#chart.event + 1] = table.copy(copy_tab2.event[i])
                end
            end
            event_sort()
            note_sort()

            if copy_tab.type == "c" then
                if copy_tab.pos ~= 'play' or (copy_tab.pos == 'play' and iskeyboard.a) then -- a完全复制
                    object_redo.write_revoke("copy",table.copy(copy_tab2))
                else
                    object_redo.write_revoke("copy",{note = table.copy(copy_tab2.note),event = {}})
                end
                return
            end

            --x
            if copy_tab.pos ~= 'play' or (copy_tab.pos == 'play' and iskeyboard.a) then --x
                object_redo.write_revoke("cropping",{table.copy(copy_tab),table.copy(copy_tab2)})
            else
                object_redo.write_revoke("cropping",{{note = table.copy(copy_tab.note),event = {}},{note = table.copy(copy_tab2.note),event = {}}} )
            end
            --x 删除原来的
            local local_tab = {}
            for i = 1,#chart.note do
                if not table.eq(copy_tab.note[1],chart.note[i]) then
                    local_tab[#local_tab + 1] = chart.note[i]
                else 
                    table.remove(copy_tab.note,1)
                end
            end
            chart.note = table.copy(local_tab)
            local_tab = {}
            if copy_tab.pos ~= 'play' or (copy_tab.pos == 'play' and iskeyboard.a) then -- a完全复制
                for i = 1,#chart.event do
                    if not table.eq(copy_tab.event[1],chart.event[i]) then
                        local_tab[#local_tab + 1] = chart.event[i]
                    else 
                        table.remove(copy_tab.event,1)
                    end
                end
                chart.event = table.copy(local_tab)
            end

        end
    end
}