local hit = object:new('hit')
hit.sw = 1
hit.sh = 1
hit.ex = 0
hit.ey = 0

hit.sound = love.audio.newSource('assets/sound/hit.ogg', "stream")
hit.light = isImage.hit_light
hit.soundTab = {}
hit.tab = {}
--用来对照的 true需要播放 false为播放完成
hit.hit = isImage.hit
hit.lightW, hit.lightH = hit.light:getDimensions() -- 得到宽高
hit.hitW, hit.hitH = hit.hit:getDimensions()       -- 得到宽高
hit.size = require 'config.layouts.play'.demo.hitSzie
function hit:load()
    -- 读取音频文件
    local tab = love.filesystem.getDirectoryItems(PATH.usersPath.hit) --得到文件夹下的所有文件
    for i, v in ipairs(tab) do
        if string.find(v, "hit") then
            self.sound = love.audio.newSource(v, "stream")
            break
        end
    end
end

function hit:Setup(x, y, w, h)
    local sw = w / play.layout.demo.w
    local sh = h / play.layout.demo.h
    self.ex = x
    self.ey = y
    self.sw = sw
    self.sh = sh
end

function hit:update(dt)
    for i = 1, #chart.note do
        local noteBeat = beat:get(chart.note[i].beat)
        local noteTrack = chart.note[i].track

        self.soundTab[noteBeat] = self.soundTab[noteBeat] or {}
        self.soundTab[noteBeat][noteTrack] = self.soundTab[noteBeat][noteTrack] or {}
        if not self.soundTab[noteBeat][noteTrack][chart.note[i].type] and not (chart.note[i].fake == 1) then --不存在 记录
            self.soundTab[noteBeat][noteTrack][chart.note[i].type] = true
            if noteBeat <= beat.nowbeat then
                self.soundTab[noteBeat][noteTrack][chart.note[i].type] = false
            end
        end
        if noteBeat < beat.nowbeat and --播放
            self.soundTab[noteBeat][noteTrack][chart.note[i].type] then
            local x, w = fEvent:get(noteTrack, beat.nowbeat)
            self.soundTab[noteBeat][noteTrack][chart.note[i].type] = false                                            --播放完成

            if self.sound and settings.hit_sound == 1 and music_play and w > 0 and not (chart.note[i].fake == 1) then --播放
                love.audio.setVolume(settings.hit_volume / 100)                                                       --设置音量大小
                self.sound:seek(0)
                self.sound:play()
            end
            if settings.hit == 1 and music_play and w > 0 and not (chart.note[i].fake == 1) and time.nowtime - beat:toTime(chart.bpm_list,noteBeat) < 0.5 then
                self.tab[#self.tab + 1] = { x = fTrack:to_play_track_x(x), time = time.nowtime, track = noteTrack }
            end
        end
        if noteBeat >= beat.nowbeat then
            self.soundTab[noteBeat][noteTrack][chart.note[i].type] = true --未播放
        end
    end
end

function hit:draw()
    if settings.hit == 0 then
        return
    end
    local sw = self.sw
    local sh = self.sh
    local ex = self.ex
    local ey = self.ey
    local judgePos = settings.judge_line_y * sh
    local size = self.size * sw
    love.graphics.push()
    love.graphics.translate(ex, ey)

    local local_hit_tab = {}
    for i = 1, #self.tab do
        local hit_scale_w = 1 / self.hitW * size
        local hit_scale_h = 1 / self.hitH * size

        local hit_light_scale_w = 1 / self.lightW
        local hit_light_scale_h = 1 / self.lightH
        love.graphics.setColor(1, 1, 1, 1)
        local hit_time = 0.5
        local hit_alpha = (time.nowtime - self.tab[i].time) / hit_time
        hit_alpha = easings.out_quart(hit_alpha)

        local hit_light_time = 0.5
        local hit_light_alpha = (time.nowtime - self.tab[i].time) / hit_light_time
        hit_light_alpha = hit_light_alpha * 0.5

        if time.nowtime - self.tab[i].time > hit_time or time.nowtime - self.tab[i].time < 0  then
            hit_alpha = 1
        else
            local_hit_tab[#local_hit_tab + 1] = self.tab[i]
        end
        if time.nowtime - self.tab[i].time > hit_light_time or time.nowtime - self.tab[i].time < 0 then
            hit_light_alpha = 1
        end


        if music_play then
            local x = self.tab[i].x * sw - size / 2 * hit_alpha
            local y = judgePos - size / 2 * hit_alpha
            local w = hit_scale_w * hit_alpha
            local h = hit_scale_h * hit_alpha

            love.graphics.setColor(1, 1, 1, 1 - hit_alpha)

            love.graphics.draw(self.hit, x, y, 0, w, h)

            local x, w = fTrack:to_play_track(fEvent:get(self.tab[i].track, beat.nowbeat))
            x = x * sw
            w = w * sw

            love.graphics.setColor(1, 1, 1,0.5 - hit_light_alpha)

            love.graphics.draw(self.light, x, judgePos - size, 0, hit_light_scale_w * w, hit_light_scale_h * size)
        end
    end
    self.tab = local_hit_tab
    love.graphics.pop()
end

return hit
