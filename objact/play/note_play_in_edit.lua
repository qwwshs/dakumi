--edit区域渲染

local ui_note = love.graphics.newImage("asset/ui_note.png")
local ui_wipe = love.graphics.newImage("asset/ui_wipe.png")
local ui_hold = love.graphics.newImage("asset/ui_hold_head.png")
local ui_hold_body = love.graphics.newImage("asset/ui_hold_body.png")
local ui_hold_tail = love.graphics.newImage("asset/ui_hold_tail.png")
local ui_tab = love.filesystem.getDirectoryItems("ui") --得到文件夹下的所有文件
if ui_tab and #ui_tab > 0 then
    for i=1,#ui_tab do
        local v = ui_tab[i]
        if string.find(v,"ui_note") then
            ui_note = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_wipe") then
            ui_wipe = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_hold_head") then
            ui_hold = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_hold_body") then
            ui_hold_body = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_hold_tail") then
            ui_hold_tail = love.graphics.newImage("ui/"..v)
        end
    end
end

local note_w = 75
local _width, _height = ui_note:getDimensions( ) -- 得到宽高
local _scale_w = 1 / _width * note_w


objact_note_play_in_edit = {
    draw = function(pos,istrack)
        local all_track_pos = get_all_track_pos()
        local all_track = track_get_all_track()
        local note_h = settings.note_height --25 * denom.scale
        local _scale_h = 1 / _height * note_h
        pos = pos or 900
        istrack = istrack or track.track
        love.graphics.setColor(1,1,1,1) --轨道
        love.graphics.rectangle("line",pos,0,75,800)

        love.graphics.setColor(1,1,1,1) -- 轨道侧线
        love.graphics.rectangle("fill",pos,0,3,800)

        love.graphics.setColor(1,1,1,1) -- x轨道
        love.graphics.rectangle("line",pos + 100,0,75,800)
        
        love.graphics.setColor(1,1,1,1) -- w轨道
        love.graphics.rectangle("line",pos +200,0,75,800)

        love.graphics.setColor(1,1,1,1) -- 侧线
        love.graphics.rectangle("fill",pos +275,0,3,800)

        love.graphics.setColor(1,1,1,1) --判定线
        love.graphics.rectangle("fill",pos,settings.judge_line_y,275,10)

    
        love.graphics.setColor(1,1,1,1)
        --note(edit区域渲染)
        for i=1,#chart.note do
            if chart.note[i].track == istrack then
                
                local y = beat_to_y(chart.note[i].beat)
                local y2 = y
                if chart.note[i].type == "hold" then
                    y2 = beat_to_y(chart.note[i].beat2)
                end
                if not (y2 > 800 + note_h or y < -note_h) then
            
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
                        love.graphics.print('false',pos +10,y-note_h)
                        love.graphics.setColor(1,1,1,1) 
                    end
                elseif y < -note_h then
                    break
                end
            end
            
        end
        --放置一半的长条渲染
        local thelocal_hold = get_hold_table()
        if thelocal_hold.beat and thelocal_hold.track == istrack then -- 存在
            love.graphics.setColor(1,1,1,1)
            local y = beat_to_y(thelocal_hold.beat)
            local y2 = beat_to_y(to_nearby_Beat(y_to_beat(mouse.y)))
            local note_h2 = y - y2 -note_h  * 2
            local _scale_h2 = 1 / _height * note_h2
                if not (y2 > 800 + note_h or y < -note_h) then
                    love.graphics.draw(ui_hold,pos,y-note_h,0,_scale_w,_scale_h) --头
                    love.graphics.draw(ui_hold_body,pos,y2+note_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(ui_hold_tail,pos,y2,0,_scale_w,_scale_h) --尾
                end
        end
    
        if string.sub(displayed_content,1,4) == "note" and --选中note框绘制
            chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))] and
            chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].track == track.track then --框出现在编辑的note
                local y = beat_to_y(chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].beat)
                local y2 = y - note_h
                if chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].type == 'hold' then
                    y2 = beat_to_y(chart.note[tonumber(string.sub(displayed_content,5,#displayed_content))].beat2)
                end
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",pos,y2,75,y - y2)
                
        end
    
            --event渲染
            local event_h = settings.note_height
            local event_w = 75
            for i=1,#chart.event do
                if chart.event[i].track == istrack then
                    love.graphics.setColor(1,1,1,1)
                    local y = beat_to_y(chart.event[i].beat)
                    local y2 = beat_to_y(chart.event[i].beat2)
                    local event_h2 = y - y2 - event_h * 2
                    local _scale_h2 = 1 / _height * event_h2
                    local x_pos = pos + 100
                    if chart.event[i].type == "w" then
                        x_pos = pos + 200
                    end
                    if not (y2 > 800 + note_h or y < -note_h) then
                        love.graphics.draw(ui_hold,x_pos,y-event_h,0,_scale_w,_scale_h) -- 头
                        love.graphics.print(chart.event[i].from,x_pos+37.5-#tostring(chart.event[i].from)*3.5,y-event_h) -- 头 初始
    
                        love.graphics.draw(ui_hold_body,x_pos,y2+event_h,0,_scale_w,_scale_h2) --身
    
                        love.graphics.draw(ui_hold_tail,x_pos,y2,0,_scale_w,_scale_h) --尾
                        love.graphics.print(chart.event[i].to,x_pos+37.5-#tostring(chart.event[i].to)*3.5,y2) --尾 结尾 --tostring是为了居中
                    -- beizer曲线
                        for k = 1,10 do
                            local nowx = low_bezier(1,10,(chart.event[i].from - 50) / 100 * 75 + x_pos +37.5,x_pos + 37.5 + (chart.event[i].to - 50) / 100 *75,chart.event[i].trans,k) --减去50是为了使50居中
                            local nowy = y + (y2 - y) * k / 10
                            love.graphics.rectangle("fill",nowx,nowy -  (y2 - y)/10,5, (y2 - y)/10) --减去一个 (y2 - y)/10是为了与头对齐
                        end
                    elseif  y < -note_h then
                        break
                    end
                end
            end
            --放置一半的event渲染
            local thelocal_event = get_event_table()
            if thelocal_event.beat and thelocal_event.track == istrack then -- 存在
                love.graphics.setColor(1,1,1,1)
                local y = beat_to_y(thelocal_event.beat)
                local y2 = mouse.y
                local event_h2 = y - y2 - event_h * 2
                local _scale_h2 = 1 / _height * event_h2
                local x_pos = pos + 100
    
                if thelocal_event.type == "w" then
                    x_pos = pos + 200
                end
                if not (y2 > 800 + note_h or y < -note_h) then
                    love.graphics.draw(ui_hold,x_pos,y-note_h,0,_scale_w,_scale_h) --头
                    love.graphics.draw(ui_hold_body,x_pos,y2+event_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(ui_hold_tail,x_pos,y2,0,_scale_w,_scale_h) --尾
                end
            end
    
            if string.sub(displayed_content,1,5) == "event" and --选中event框绘制
            chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].track == track.track then --框出现在编辑的event
                local y = beat_to_y(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat)
                local y2 = beat_to_y(chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].beat2)
                love.graphics.setColor(1,1,1,0.5)
                if chart.event[tonumber(string.sub(displayed_content,6,#displayed_content))].type == "x" then
                    love.graphics.rectangle("fill",pos + 100,y2,75,y - y2)
                else
                    love.graphics.rectangle("fill",pos + 200,y2,75,y - y2)
                end
                
            end
            love.graphics.setColor(0,0,0,0.5)
            love.graphics.rectangle("fill",pos,settings.judge_line_y + 10,275,100) --遮罩
            love.graphics.setColor(1,1,1,1) --现在节拍
            love.graphics.print(objact_language.get_string_in_languages('beat')..":"..math.floor(beat.nowbeat*100)/100,pos,settings.judge_line_y+20)
            love.graphics.print(objact_language.get_string_in_languages('time')..":"..math.floor(time.nowtime*100)/100,pos,settings.judge_line_y+40)
            local now_x,now_w = all_track_pos[istrack].x,all_track_pos[istrack].w
            love.graphics.print(objact_language.get_string_in_languages('x')..":"..math.floor(now_x*100)/100,pos + 100,settings.judge_line_y+20)
            love.graphics.print(objact_language.get_string_in_languages('w')..":"..math.floor(now_w*100)/100,pos + 200,settings.judge_line_y+20)
            love.graphics.print(objact_language.get_string_in_languages('track')..":"..istrack,pos,settings.judge_line_y+60)
    end
}