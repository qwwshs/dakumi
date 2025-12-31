--轨道渲染
local demoPlay = object:new("demoPlay")
demoPlay.sw = 1
demoPlay.sh = 1
demoPlay.ex = 0
demoPlay.ey = 0

demoPlay.ui = {}
demoPlay.ui.note = isImage.note2
demoPlay.ui.wipe = isImage.wipe2
demoPlay.ui.hold = isImage.hold_head2
demoPlay.ui.holdBody = isImage.hold_body2
demoPlay.ui.holdTail = isImage.hold_tail2
local ui_tab = nativefs.getDirectoryItems(PATH.usersPath.ui) --得到文件夹下的所有文件
if ui_tab and #ui_tab > 0 then
    for i=1,#ui_tab do
        local v = ui_tab[i]
        if string.find(v,"note") then
            demoPlay.ui.note = love.graphics.newImage(PATH.usersPath.ui..v)
        elseif string.find(v,"wipe") then
            demoPlay.ui.wipe = love.graphics.newImage(PATH.usersPath.ui..v)
        elseif string.find(v,"holdHead") then
            demoPlay.ui.hold = love.graphics.newImage(PATH.usersPath.ui..v)
        elseif string.find(v,"holdBody") then
            demoPlay.ui.holdBody = love.graphics.newImage(PATH.usersPath.ui..v)
        elseif string.find(v,"holdTail") then
            demoPlay.ui.holdTail = love.graphics.newImage(PATH.usersPath.ui..v)
        end
    end
end
function demoPlay:Setup(x,y,w,h)
    local sw = w / play.layout.demo.w
    local sh = h / play.layout.demo.h
    self.ex = x
    self.ey = y
    self.sw = sw
    self.sh = sh
end
function demoPlay:draw()
    local sw = self.sw
    local sh = self.sh
    local ex = self.ex
    local ey = self.ey
    love.graphics.push()
    love.graphics.translate(ex,ey)
    local judgePos = settings.judge_line_y *sh
    local effect = play:get_init_effect()
    love.graphics.setColor(play.colors.demoInJudgheLineDownBg) --游玩区域显示的背景板
    love.graphics.rectangle("fill",0,0,play.layout.demo.w*sw,WINDOW.h*sh)

    local all_track_pos = play:get_all_track_pos()

    local all_track = fTrack:track_get_all_track()
    
    if next(all_track_pos) == nil then --没有轨道
        love.graphics.pop()
        return
    end

    love.graphics.setColor(0,0,0,0.5 * effect.track_alpha / 100 )  --底板

    for i=1 ,#all_track do --轨道底板绘制
            local x,w = all_track_pos[all_track[i]].x,all_track_pos[all_track[i]].w
            x,w = fTrack:to_play_track(x,w) --为了居中
            x = x * sw
            w = w * sw
        if w ~= 0 then
            love.graphics.rectangle("fill",x,0,w,judgePos*sh)
        end
    end

    for i=1 ,#all_track do --轨道侧线绘制
            local x,w = all_track_pos[all_track[i]].x,all_track_pos[all_track[i]].w
            x,w = fTrack:to_play_track(x,w) --为了居中
            x = x * sw
            w = w * sw
            if track.track == all_track[i] and (not demo.open ) then --选择到的底板
                love.graphics.setColor(play.colors.selectingTrack) 
                love.graphics.rectangle("fill",x,0,w,WINDOW.h)
            end
            if w ~= 0 then
                love.graphics.setColor(1,1,1,effect.track_line_alpha / 100) --侧线
                love.graphics.rectangle("line",x,0,w,WINDOW.h)
            end
            if not demo.open then
                love.graphics.setColor(play.colors.trackNum) --轨道编号
                if track.track == all_track[i] then
                    love.graphics.setColor(play.colors.selectingTrackNum) --轨道编号
                end
                love.graphics.printf(  all_track[i], x,judgePos-20,w, "center")
            end
    end

    --游玩区域侧线
    love.graphics.setColor(play.colors.demoTrackline)
    local x,w = fTrack:to_play_track(-chart.preference.x_offset,0.002*chart.preference.event_scale)
    x = x*sw
    w = w*sw
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    x,w = fTrack:to_play_track(-chart.preference.x_offset + chart.preference.event_scale,0.002*chart.preference.event_scale)
    x = x*sw
    w = w*sw
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)

    love.graphics.setColor(play.colors.demoTrackline2) --游玩区域侧线(外侧)
    x,w = fTrack:to_play_track(-chart.preference.x_offset- 0.01 * chart.preference.event_scale,0.005 * chart.preference.event_scale)
    x = x*sw
    w = w*sw
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    x,w = fTrack:to_play_track(-chart.preference.x_offset + 1.01 * chart.preference.event_scale,0.005 * chart.preference.event_scale)
    x = x*sw
    w = w*sw
    love.graphics.rectangle("fill",x,0,w,WINDOW.h)
    
    local note_h = settings.note_height*sh --25 * denom.scale
    local _width, _height = demoPlay.ui.note:getDimensions() -- 得到宽高
    love.graphics.setColor(1,1,1,effect.note_alpha / 100)

    --展示侧note渲染
    local spacing = 20*sw --note和track的间距
        for i = 1,#chart.note do
            local isnote = chart.note[i]
            local x,w = fTrack:to_play_track(all_track_pos[isnote.track].x,all_track_pos[isnote.track].w)
            x = x * sw
            w = w * sw

            x = x + w /2
            if w > spacing*2 then --增加间隙
                w = w - spacing
            elseif w <= spacing*2 and w > spacing  then
                w = spacing
            end
            x = x - w /2
            local y = beat:toY(isnote.beat)
            local y2 = y
            if isnote.type == "hold" then
                y2 = beat:toY(isnote.beat2)
            end
            y = y * sh
            y2 = y2 * sh
            local _scale_w = 1 / _width * w

            local _scale_h = 1 / _height * note_h
            if y < 0 then break end --超出范围
            if (not (y2 > judgePos + note_h or y < 0)) and (not  (y > judgePos and isnote.fake == 1 ) )then
                if y ~= y2 and y > judgePos then y = judgePos end --hold头保持在线上

                if isnote.type == "note" then
                    love.graphics.draw(demoPlay.ui.note,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2) --后面两个值用于旋转
                elseif isnote.type == "wipe" then
                    love.graphics.draw(demoPlay.ui.wipe,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                else --hold
                    local _scale_h2 = 1 / _height * (y - y2 - note_h - note_h)
                    love.graphics.draw(demoPlay.ui.hold,x,y-note_h,0,_scale_w,_scale_h)
                    love.graphics.draw(demoPlay.ui.holdBody,x,y2+note_h,0,_scale_w,_scale_h2) --身
                    love.graphics.draw(demoPlay.ui.holdTail,x,y2,0,_scale_w,_scale_h)
                    if isnote.note_head == 1 then
                        love.graphics.draw(demoPlay.ui.note,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                    end
                    if isnote.wipe_head == 1 then
                        love.graphics.draw(demoPlay.ui.wipe,x+w/2,y-note_h+note_h/2,effect.note_rotate,_scale_w,_scale_h,_width/2,_height/2)
                    end
                end
            end

        end

    --遮挡板
    local start_x = fTrack:to_play_track(-chart.preference.x_offset,0) *sw
    local end_x = fTrack:to_play_track(-chart.preference.x_offset + chart.preference.event_scale,0) *sw
    love.graphics.setColor(play.colors.Shield)
    love.graphics.rectangle("fill",start_x,judgePos,end_x - start_x,WINDOW.h - judgePos)

    --进度条
    local progress_bar = fTrack:to_play_track(-chart.preference.x_offset + chart.preference.event_scale * 0.2,0) *sw
    love.graphics.setColor(play.colors.ProgressBar)
    love.graphics.rectangle("fill",start_x + (end_x - start_x)/2-(progress_bar*time.nowtime/time.alltime) / 2,judgePos+30,time.nowtime/time.alltime * progress_bar,5)

    love.graphics.rectangle("fill",start_x + (end_x - start_x)/2-progress_bar/2,judgePos+29,1,7)
    love.graphics.rectangle("fill",start_x + (end_x - start_x)/2+progress_bar/2,judgePos+29,1,7)

    --判定线
    love.graphics.setColor(play.colors.judgeLine) --判定线内部
    love.graphics.rectangle("fill",start_x,judgePos-5,end_x - start_x,10)


    love.graphics.setColor(play.colors.judge) --判定线 play

    love.graphics.rectangle("line",start_x,judgePos-8,end_x - start_x,16) --8是为了对其中心
    love.graphics.pop()
end

return demoPlay