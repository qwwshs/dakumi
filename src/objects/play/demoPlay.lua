--轨道渲染
local demoPlay = object:new("demoPlay")
demoPlay.ui = {}
demoPlay.ui.note = isImage.note2
demoPlay.ui.wipe = isImage.wipe2
demoPlay.ui.hold = isImage.hold_head2
demoPlay.ui.holdBody = isImage.hold_body2
demoPlay.ui.holdTail = isImage.hold_tail2
local ui_tab = love.filesystem.getDirectoryItems("ui") --得到文件夹下的所有文件
if ui_tab and #ui_tab > 0 then
    for i=1,#ui_tab do
        local v = ui_tab[i]
        if string.find(v,"ui_note") then
            demoPlay.ui.note = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_wipe") then
            demoPlay.ui.wipe = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_hold_head") then
            demoPlay.ui.hold = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_hold_body") then
            demoPlay.ui.holdBody = love.graphics.newImage("ui/"..v)
        elseif string.find(v,"ui_hold_tail") then
            demoPlay.ui.holdTail = love.graphics.newImage("ui/"..v)
        end
    end
end

function demoPlay:draw()
    local sx = 1
    local sy = 1
    local effect = play:get_effect()
    if not demo then effect = play:get_init_effect() end
    
    love.graphics.push()
    love.graphics.scale(sx,sy)

    love.graphics.setColor(0,0, 0, 0.4) --游玩区域显示的背景板
    love.graphics.rectangle("fill",0,0,900,WINDOW.h)

    local all_track_pos = play:get_all_track_pos()

    local all_track = fTrack:track_get_all_track()
    
    if next(all_track_pos) == nil then --没有轨道
        return
    end

    love.graphics.setColor(0,0,0,0.5 * effect.track_alpha / 100 )  --底板

    for i=1 ,#all_track do --轨道底板绘制
            local x,w = all_track_pos[all_track[i]].x,all_track_pos[all_track[i]].w
            x,w = fTrack:to_play_track(x,w) --为了居中
        if w ~= 0 then
            love.graphics.rectangle("fill",x,0,w,settings.judge_line_y)
        end
    end

    for i=1 ,#all_track do --轨道侧线绘制
            local x,w = all_track_pos[all_track[i]].x,all_track_pos[all_track[i]].w
            x,w = fTrack:to_play_track(x,w) --为了居中
            --倾斜计算
            if track.track == all_track[i] and (not demo ) then --选择到的底板
                love.graphics.setColor(1,1,1,0.2) 
                love.graphics.rectangle("fill",x,0,w,settings.judge_line_y)
            end
            if w ~= 0 then
                love.graphics.setColor(1,1,1,effect.track_line_alpha / 100) --侧线
                love.graphics.rectangle("line",x,0,w,settings.judge_line_y)
            end
            if not demo then
                love.graphics.setColor(1,1,1,1) --轨道编号
                if track.track == all_track[i] then
                    love.graphics.setColor(0,1,1,1) --轨道编号
                end
                love.graphics.printf(  all_track[i], x,settings.judge_line_y-20,w, "center")
            end
    end

    --游玩区域侧线
    love.graphics.setColor(1,1,1,0.5)
    local x,w = fTrack:to_play_track(-chart.preference.x_offset,0.002*chart.preference.event_scale)
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    x,w = fTrack:to_play_track(-chart.preference.x_offset + chart.preference.event_scale,0.002*chart.preference.event_scale)
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    
    love.graphics.setColor(1,1,1,1)
    x,w = fTrack:to_play_track(-chart.preference.x_offset- 0.01 * chart.preference.event_scale,0.005 * chart.preference.event_scale)
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    x,w = fTrack:to_play_track(-chart.preference.x_offset + 1.01 * chart.preference.event_scale,0.005 * chart.preference.event_scale)
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    
    local note_h = settings.note_height --25 * denom.scale
    local note_w = 75
    local _width, _height = demoPlay.ui.note:getDimensions() -- 得到宽高
    love.graphics.setColor(1,1,1,effect.note_alpha / 100)

    --展示侧note渲染
    local spacing = 20 --note和track的间距
        for i = 1,#chart.note do
            local x,w = fTrack:to_play_track(all_track_pos[chart.note[i].track].x,all_track_pos[chart.note[i].track].w)
            x = x + w /2
            if w > spacing*2 then --增加间隙
                w = w - spacing
            elseif w <= spacing*2 and w > spacing  then
                w = spacing
            end
            x = x - w /2
            local y = beat:toY(chart.note[i].beat)
            local y2 = y
            if chart.note[i].type == "hold" then
                y2 = beat:toY(chart.note[i].beat2)
            end

            local _scale_w = 1 / _width * w

            local _scale_h = 1 / _height * note_h
            if y < play.layout.demo.y - note_h then break end --超出范围
            if (not (y2 > settings.judge_line_y + note_h or y < play.layout.demo.y -  note_h)) and (not  (y > settings.judge_line_y and chart.note[i].fake == 1 ) )then
                if y ~= y2 and y > settings.judge_line_y then y = settings.judge_line_y end --hold头保持在线上

                if chart.note[i].type == "note" then
                    love.graphics.draw(demoPlay.ui.note,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2) --后面两个值用于旋转
                elseif chart.note[i].type == "wipe" then
                    love.graphics.draw(demoPlay.ui.wipe,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                else --hold
                    local _scale_h2 = 1 / _height * (y - y2 - note_h - note_h)
                    love.graphics.draw(demoPlay.ui.hold,x,y-note_h,0,_scale_w,_scale_h)
                    love.graphics.draw(demoPlay.ui.holdBody,x,y2+note_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(demoPlay.ui.holdTail,x,y2,0,_scale_w,_scale_h)
                    if chart.note[i].note_head == 1 then
                        love.graphics.draw(demoPlay.ui.note,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                    end
                    if chart.note[i].wipe_head == 1 then
                        love.graphics.draw(demoPlay.ui.wipe,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                    end
                end
            end

        end

    --遮挡板
    local start_x = fTrack:to_play_track(-chart.preference.x_offset,0)
    local end_x = fTrack:to_play_track(-chart.preference.x_offset + chart.preference.event_scale,0)
    love.graphics.setColor(0,0,0,1)
    love.graphics.rectangle("fill",start_x,settings.judge_line_y,end_x - start_x,WINDOW.h - settings.judge_line_y)

    --进度条
    local progress_bar = fTrack:to_play_track(-chart.preference.x_offset + chart.preference.event_scale * 0.2,0)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill",start_x + (end_x - start_x)/2-(progress_bar*time.nowtime/time.alltime) / 2,settings.judge_line_y+30,time.nowtime/time.alltime * progress_bar,5)

    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill",start_x + (end_x - start_x)/2-progress_bar/2,settings.judge_line_y+29,1,7)
    love.graphics.rectangle("fill",start_x + (end_x - start_x)/2+progress_bar/2,settings.judge_line_y+29,1,7)

    --判定线
    love.graphics.setColor(0,0.7,0.7,1) --判定线内部
    love.graphics.rectangle("fill",start_x,settings.judge_line_y-5,end_x - start_x,10)


    love.graphics.setColor(1,1,1,1) --判定线 play

    love.graphics.rectangle("line",start_x,settings.judge_line_y-8,end_x - start_x,16) --8是为了对其中心

    love.graphics.pop()
end

return demoPlay