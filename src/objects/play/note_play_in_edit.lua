--edit区域渲染

local ui_note = isImage.note
local ui_wipe = isImage.wipe
local ui_hold = isImage.hold_head
local ui_hold_body = isImage.hold_body
local ui_hold_tail = isImage.hold_tail

local note_w = 75
local _width, _height = ui_note:getDimensions( ) -- 得到宽高
local _scale_w = 1 / _width * note_w
local track_info = info.play.track

object_note_play_in_edit = {
    draw = function(pos,istrack)
        local all_track_pos = play:get_all_track_pos()
        local all_track = track_get_all_track()
        local note_h = settings.note_height --25 * denom.scale
        local _scale_h = 1 / _height * note_h
        pos = pos or track_info.x
        istrack = istrack or track.track
        love.graphics.setColor(1,1,1,1) --轨道
        love.graphics.rectangle("line",pos,0,track_info.one_track_w,track_info.h)

        love.graphics.setColor(1,1,1,1) -- 侧线左
        love.graphics.rectangle("fill",pos,0,3,track_info.h)

        love.graphics.setColor(1,1,1,1) -- x轨道
        love.graphics.rectangle("line",pos + track_info.interval,track_info.y,track_info.one_track_w,track_info.h)
        
        love.graphics.setColor(1,1,1,1) -- w轨道
        love.graphics.rectangle("line",pos + track_info.interval * 2,track_info.y,track_info.one_track_w,track_info.h)

        love.graphics.setColor(1,1,1,1) -- 侧线右
        love.graphics.rectangle("fill",pos +track_info.one_track_w+ track_info.interval * 2,track_info.y,3,track_info.h)

        love.graphics.setColor(1,1,1,1) --判定线
        love.graphics.rectangle("fill",pos,settings.judge_line_y,track_info.one_track_w+ track_info.interval * 2,10)

    
        love.graphics.setColor(1,1,1,1)
        --note(edit区域渲染)
        for i=1,#chart.note do
            if chart.note[i].track == istrack then
                
                local y = beat:toY(chart.note[i].beat)
                local y2 = y
                if chart.note[i].type == "hold" then
                    y2 = beat:toY(chart.note[i].beat2)
                end
                if not (y2 > WINDOW.h + note_h or y < -note_h) then
            
                    if chart.note[i].type == "note" then
                        love.graphics.draw(ui_note,pos,y-note_h,0,_scale_w,_scale_h)
                    elseif chart.note[i].type == "wipe" then
                    
                            love.graphics.draw(ui_wipe,pos,y-note_h,0,_scale_w,_scale_h)
                    else --hold
    
                            love.graphics.draw(ui_hold,pos,y-note_h,0,_scale_w,_scale_h) -- 头
                        local note_h2 = y - y2 -note_h * 2
                        local _scale_h2 = 1 / _height * note_h2
                        love.graphics.draw(ui_hold_tail,pos,y2,0,_scale_w,_scale_h) -- 尾
                        love.graphics.draw(ui_hold_body,pos,y2+note_h,0,_scale_w,_scale_h2) --身
                    end
                    if chart.note[i].fake and chart.note[i].fake == 1 then --假note
                        love.graphics.setColor(1,0,0,1) 
                        love.graphics.rectangle('line',pos,y-note_h,note_w,note_h)
                        love.graphics.printf('false',pos,y-note_h,info.play.track.one_track_w,'center')
                        love.graphics.setColor(1,1,1,1) 
                    end
                elseif y < -note_h then
                    break
                end
            end
            
        end
        --放置一半的长条渲染
        local thelocal_hold = note:getHoldTable()
        if thelocal_hold.beat and thelocal_hold.track == istrack then -- 存在
            love.graphics.setColor(1,1,1,1)
            local y = beat:toY(thelocal_hold.beat)
            local y2 = beat:toY(beat:toNearby(beat:yToBeat(mouse.y)))
            local note_h2 = y - y2 -note_h  * 2
            local _scale_h2 = 1 / _height * note_h2
                if not (y2 > track_info.y + track_info.h + note_h or y < -note_h) then
                    love.graphics.draw(ui_hold,pos,y-note_h,0,_scale_w,_scale_h) --头
                    love.graphics.draw(ui_hold_body,pos,y2+note_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(ui_hold_tail,pos,y2,0,_scale_w,_scale_h) --尾
                end
        end
        
        local note_index = sidebar.incoming[1] --选中的note
        if sidebar.displayed_content == "note" and --选中note框绘制
            chart.note[note_index] and
            chart.note[note_index].track == track.track then --框出现在编辑的note
                local y = beat:toY(chart.note[note_index].beat)
                local y2 = y - note_h
                if chart.note[note_index].type == 'hold' then
                    y2 = beat:toY(chart.note[note_index].beat2)
                end
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",pos,y2,track_info.one_track_w,y - y2)
                
        end
    
            --event渲染
            local event_h = settings.note_height
            local event_w = 75
            for i=1,#chart.event do
                if chart.event[i].track == istrack then
                    love.graphics.setColor(1,1,1,1)
                    local y = beat:toY(chart.event[i].beat)
                    local y2 = beat:toY(chart.event[i].beat2)
                    local event_h2 = y - y2 - event_h * 2
                    local _scale_h2 = 1 / _height * event_h2
                    local x_pos = pos + track_info.interval
                    if chart.event[i].type == "w" then
                        x_pos = pos + track_info.interval *2
                    end
                    if not (y2 > WINDOW.h + note_h or y < -note_h) then
                        love.graphics.draw(ui_hold,x_pos,y-event_h,0,_scale_w,_scale_h) -- 头
                        love.graphics.printf(chart.event[i].from,x_pos,y-event_h,track_info.one_track_w,'center')
                        love.graphics.draw(ui_hold_body,x_pos,y2+event_h,0,_scale_w,_scale_h2) --身
    
                        love.graphics.draw(ui_hold_tail,x_pos,y2,0,_scale_w,_scale_h) --尾
                        love.graphics.printf(chart.event[i].to,x_pos,y2,track_info.one_track_w,'center')
                    -- beizer曲线
                        for k = 1,10 do
                            local nowx = low_bezier(1,10,(chart.event[i].from - 50) / 100 * track_info.one_track_w + x_pos +track_info.one_track_w/2,x_pos + track_info.one_track_w/2 + (chart.event[i].to - 50) / 100 *track_info.one_track_w,chart.event[i].trans,k) --减去50是为了使50居中
                            local nowy = y + (y2 - y) * k / 10
                            love.graphics.rectangle("fill",nowx,nowy -  (y2 - y)/10,5, (y2 - y)/10) --减去一个 (y2 - y)/10是为了与头对齐
                        end
                    elseif  y < -note_h then
                        break
                    end
                end
            end
            --放置一半的event渲染
            local thelocal_event = event:getHoldTable()
            if thelocal_event.beat and thelocal_event.track == istrack then -- 存在
                love.graphics.setColor(1,1,1,1)
                local y = beat:toY(thelocal_event.beat)
                local y2 = beat:toY(beat:toNearby(beat:yToBeat(mouse.y)))
                local event_h2 = y - y2 - event_h * 2
                local _scale_h2 = 1 / _height * event_h2
                local x_pos = pos + track_info.interval
    
                if thelocal_event.type == "w" then
                    x_pos = pos + track_info.interval *2
                end
                if not (y2 > WINDOW.h + note_h or y < -note_h) then
                    love.graphics.draw(ui_hold,x_pos,y-note_h,0,_scale_w,_scale_h) --头
                    love.graphics.draw(ui_hold_body,x_pos,y2+event_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(ui_hold_tail,x_pos,y2,0,_scale_w,_scale_h) --尾
                end
            end
            
            local event_index = sidebar.incoming[1] --选中的event
            if sidebar.displayed_content == "event" and chart.event[event_index] and --选中event框绘制
            chart.event[event_index].track == track.track then --框出现在编辑的event
                local y = beat:toY(chart.event[event_index].beat)
                local y2 = beat:toY(chart.event[event_index].beat2)
                love.graphics.setColor(1,1,1,0.5)
                if chart.event[event_index].type == "x" then
                    love.graphics.rectangle("fill",pos + track_info.interval,y2,track_info.one_track_w,y - y2)
                else
                    love.graphics.rectangle("fill",pos + track_info.interval*2,y2,track_info.one_track_w,y - y2)
                end
                
            end
            
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",pos,settings.judge_line_y + 10,track_info.w,WINDOW.h - settings.judge_line_y) --遮罩
                love.graphics.setColor(1,1,1,1) --现在节拍
                love.graphics.print(i18n:get('beat')..":"..math.floor(beat.nowbeat*100)/100,pos,settings.judge_line_y+20)
                love.graphics.print(i18n:get('time')..":"..math.floor(time.nowtime*100)/100,pos,settings.judge_line_y+40)
                local now_x,now_w = 0,0
                if all_track_pos[istrack] then
                    now_x,now_w = all_track_pos[istrack].x,all_track_pos[istrack].w
                end
                love.graphics.print(i18n:get('x')..":"..math.floor(now_x*100)/100,pos + 100,settings.judge_line_y+20)
                love.graphics.print(i18n:get('w')..":"..math.floor(now_w*100)/100,pos + 200,settings.judge_line_y+20)
                love.graphics.print(i18n:get('track')..":"..istrack,pos,settings.judge_line_y+60)

    end
}