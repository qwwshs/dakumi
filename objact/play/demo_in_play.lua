
local ui_note = love.graphics.newImage("asset/ui_note2.png")
local ui_wipe = love.graphics.newImage("asset/ui_wipe2.png")
local ui_hold = love.graphics.newImage("asset/ui_hold_head2.png")
local ui_hold_body = love.graphics.newImage("asset/ui_hold_body2.png")
local ui_hold_tail = love.graphics.newImage("asset/ui_hold_tail2.png")
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
--演示的
objact_demo_inplay = {
    draw = function(sx,sy) --x缩放和y缩放
    sx = sx or 1
    sy = sy or 1
    local effect = get_effect()
    if not demo_mode then effect = get_init_effect() end
    
    love.graphics.push()
    love.graphics.scale(sx,sy)

    love.graphics.setColor(RGBA_hexToRGBA("#64000000")) --游玩区域显示的背景板
    love.graphics.rectangle("fill",0,0,900,800)

    all_track_pos = get_all_track_pos()

    local all_track = track_get_all_track()
    love.graphics.setColor(0,0,0,0.5 * effect.track_alpha / 100 )  --底板

    for i=1 ,#all_track do --轨道底板绘制
            local x,w = all_track_pos[all_track[i]].x,all_track_pos[all_track[i]].w
            x,w = to_play_track(x,w) --为了居中
        if w ~= 0 then
            love.graphics.rectangle("fill",x,0,w,settings.judge_line_y)
        end
    end

    for i=1 ,#all_track do --轨道侧线绘制
            local x,w = all_track_pos[all_track[i]].x,all_track_pos[all_track[i]].w
            x,w = to_play_track(x,w) --为了居中
            --倾斜计算
            if track.track == all_track[i] and (not demo_mode ) then --选择到的底板
                love.graphics.setColor(1,1,1,0.2) 
                love.graphics.rectangle("fill",x,0,w,settings.judge_line_y)
            end
            if w ~= 0 then
                love.graphics.setColor(1,1,1,effect.track_line_alpha / 100) --侧线
                love.graphics.rectangle("line",x,0,w,settings.judge_line_y)
            end
            if not demo_mode then
                love.graphics.setColor(1,1,1,1) --轨道编号
                if track.track == all_track[i] then
                    love.graphics.setColor(0,1,1,1) --轨道编号
                end
                love.graphics.printf(  all_track[i], x,settings.judge_line_y-20,w, "center")
            end
    end

    --游玩区域侧线
    love.graphics.setColor(1,1,1,0.5)
    local x,w = to_play_original_track(0,0.2)
    love.graphics.rectangle("fill",x,0,w,800)
    x,w = to_play_original_track(100,0.2)
    love.graphics.rectangle("fill",x,0,w,800)
    
    love.graphics.setColor(1,1,1,1)
    x,w = to_play_original_track(-1,0.5)
    love.graphics.rectangle("fill",x,0,w,800)
    x,w = to_play_original_track(101,0.5)
    love.graphics.rectangle("fill",x,0,w,800)
    
    local note_h = settings.note_height --25 * denom.scale
    local note_w = 75
    local _width, _height = ui_note:getDimensions() -- 得到宽高
    love.graphics.setColor(1,1,1,effect.note_alpha / 100)

    --展示侧note渲染

        for i = 1,#chart.note do
            local x,w = to_play_track(all_track_pos[chart.note[i].track].x,all_track_pos[chart.note[i].track].w)
            x = x + w /2
            if w > 40 and chart.note[i].type ~= "wipe" then --增加间隙
                w = w - 20
            elseif w <= 40 and w > 20 and chart.note[i].type ~= "wipe" then
                w = 20
            elseif w > 60 and chart.note[i].type == "wipe" then --增加间隙
                w = w - 30
            elseif w <= 60 and w > 30 and chart.note[i].type == "wipe" then
                w = 30
            end
            x = x - w /2
            local y = beat_to_y(chart.note[i].beat)
            local y2 = y
            if chart.note[i].type == "hold" then
                y2 = beat_to_y(chart.note[i].beat2)
            end

            local _scale_w = 1 / _width * w

            local _scale_h = 1 / _height * note_h
            if y <  0 -  note_h then break end --超出范围
            if (not  (y2 > settings.judge_line_y + note_h or y < 0 -  note_h)) and (not  (y > settings.judge_line_y and chart.note[i].fake == 1  ) )then
                if y ~= y2 and y > settings.judge_line_y then y = settings.judge_line_y end --hold头保持在线上

                if chart.note[i].type == "note" then
                    love.graphics.draw(ui_note,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2) --后面两个值用于旋转
                elseif chart.note[i].type == "wipe" then
                    love.graphics.draw(ui_wipe,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                else --hold
                    local _scale_h2 = 1 / _height * (y - y2 - note_h - note_h)
                    love.graphics.draw(ui_hold,x,y-note_h,0,_scale_w,_scale_h)
                    love.graphics.draw(ui_hold_body,x,y2+note_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(ui_hold_tail,x,y2,0,_scale_w,_scale_h)
                end
            end

        end

    local start_x = to_play_original_track(0,0)
    local end_x = to_play_original_track(100,0)

    local progress_bar = to_play_original_track(20,0)
    love.graphics.setColor(0,0,0,1)
    --遮挡板
    love.graphics.rectangle("fill",start_x,settings.judge_line_y,end_x - start_x,800 - settings.judge_line_y)

    --进度条
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

    
    --hit
    objact_hit.draw()
    love.graphics.pop()
end
}