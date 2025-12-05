local hit = object:new('hit')

hit.sound = love.audio.newSource('assets/sound/hit.ogg', "stream")
hit.light = isImage.hit_light
hit.soundTab ={}
hit.tab ={}
--用来对照的 true需要播放 false为播放完成
hit.hit = isImage.hit
hit.lightW, hit.lightH = hit.light:getDimensions( ) -- 得到宽高
hit.hitW, hit.hitH = hit.hit:getDimensions( ) -- 得到宽高
hit.size = require 'config.layouts.play'.demo.hitSzie
function hit:load()
    -- 读取音频文件
    local tab = love.filesystem.getDirectoryItems(PATH.usersPath.hit) --得到文件夹下的所有文件
    for i,v in ipairs(tab) do
        if string.find(v,"hit") then
            self.sound = love.audio.newSource(v, "stream")
            break
        end
    end
end

function hit:update(dt)
    for i = 1,#chart.note do
        if not self.soundTab["b"..beat:get(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] and not( chart.note[i].fake == 1) then --不存在 记录
            if beat:get(chart.note[i].beat) <= beat.nowbeat then
                self.soundTab["b"..beat:get(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = false
            else
                self.soundTab["b"..beat:get(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = true
            end
        end
        if beat:get(chart.note[i].beat) < beat.nowbeat and --播放
        self.soundTab["b"..beat:get(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] then
            local x,w = fEvent:get(chart.note[i].track,beat.nowbeat)
            self.soundTab["b"..beat:get(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = false --播放完成

            if self.sound and settings.hit_sound == 1 and music_play and w > 0 and not( chart.note[i].fake == 1) then --播放
                love.audio.setVolume( settings.hit_volume / 100 ) --设置音量大小
                self.sound:seek(0)
                self.sound:play()
            end
            if settings.hit == 1 and music_play  and w > 0 and not( chart.note[i].fake == 1) then
                
                self.tab[#self.tab + 1] = {x = fTrack:to_play_track_x(x),time = time.nowtime,track = chart.note[i].track}
            end
        end
        if beat:get(chart.note[i].beat) >= beat.nowbeat then
           self.soundTab["b"..beat:get(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = true --未播放
        end

    end
end

function hit:draw()
    if settings.hit == 0 then
        return
    end
    local local_hit_tab = {}
    for i = 1,#self.tab do
        local hit_scale_w = 1 / self.hitW * hit.size
        local hit_scale_h = 1 / self.hitH * hit.size / (WINDOW.scale / WINDOW.scale)
        
        local hit_light_scale_w = 1 / self.lightW
        local hit_light_scale_h = 1 / self.lightH  / (WINDOW.scale / WINDOW.scale)
        if demo then
            hit_scale_h = 1 / self.hitH * hit.size / (WINDOW.scale / WINDOW.scale)   / (1 / (WINDOW.w/900))
            hit_scale_w = 1 / self.hitW * hit.size
        end
        love.graphics.setColor(1,1,1,1)
        local hit_time = 0.5 
        local hitlight_frame = 19 --光效帧数
        local hit_alpha = math.floor((time.nowtime - self.tab[i].time) / hit_time * 100) /100
        local hit_light_alpha = math.floor((time.nowtime - self.tab[i].time) / hit_time * hitlight_frame)+1
        if hit_alpha > 1 or hit_alpha < 0 then
            hit_alpha = 0
        else
            local_hit_tab[#local_hit_tab + 1] = self.tab[i]
        end
        hit_alpha = easings.out_quart(hit_alpha)
        love.graphics.setColor(1,1,1,1 - hit_alpha)
        
        if demo then
            love.graphics.draw(self.hit
            ,self.tab[i].x-hit.size / 2 *hit_alpha,settings.judge_line_y - hit.size / 2 *hit_alpha / (WINDOW.scale / WINDOW.scale) / (1 / (WINDOW.w/900)),0,hit_scale_w * hit_alpha,hit_scale_h * hit_alpha)
            
        else
            love.graphics.draw(self.hit
            ,self.tab[i].x-hit.size / 2 *hit_alpha,settings.judge_line_y - hit.size / 2 *hit_alpha  /(WINDOW.scale / WINDOW.scale),0,hit_scale_w* hit_alpha,hit_scale_h* hit_alpha)
        end

        --光效
        if not (hit_light_alpha >= hitlight_frame or hit_light_alpha <= 1) then --防止暂停时滞留
            love.graphics.setColor(1,1,1,(hitlight_frame-hit_light_alpha)/(hitlight_frame*3)) --只要1/4的alpha
            local x,w = fTrack:to_play_track(fEvent:get(self.tab[i].track,beat.nowbeat))
            love.graphics.draw(self.light,x,settings.judge_line_y-hit.size  / (WINDOW.scale / WINDOW.scale),0,hit_light_scale_w*w,hit_light_scale_h*hit.size)
        end
    end
    self.tab = local_hit_tab
end

return hit