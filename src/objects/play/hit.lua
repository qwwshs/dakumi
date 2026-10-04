local AudioService = require('src.services.audioService')
local hit = object:new('hit')
local ChartService = require("src.services.chartService")
hit.sw = 1
hit.sh = 1
hit.ex = 0
hit.ey = 0

hit.sound = love.audio.newSource('assets/sound/hit.ogg', "static")
hit.soundtab = {}
for i = 1, 5 do
    hit.soundtab[i] = love.audio.newSource('assets/sound/hit.ogg', "static")
end
hit.light = isImage.hit_light
hit.hittab = {}
hit.tab = {}
--用来对照的 true需要播放 false为播放完成
hit.hit = isImage.hit

hit.size = require 'config.layouts.play'.demo.hitSzie

local ui_tab = nativefs.getDirectoryItems(PATH.usersPath.ui) --得到文件夹下的所有文件
if ui_tab and #ui_tab > 0 then
    for i=1,#ui_tab do
        local v = ui_tab[i]
        if string.find(v,"hit") then
            hit.hit = love.graphics.newImage(PATH.usersPath.ui..v)
        elseif string.find(v,"hit_light") then
            hit.light = love.graphics.newImage(PATH.usersPath.ui..v)
        end
    end
end

hit.lightW, hit.lightH = hit.light:getDimensions() -- 得到宽高
hit.hitW, hit.hitH = hit.hit:getDimensions()       -- 得到宽高

function hit:load()
    -- 读取音频文件
    local tab = love.filesystem.getDirectoryItems(PATH.usersPath.hit) --得到文件夹下的所有文件
    for i, v in ipairs(tab) do
        if string.find(v, "hit") then
            if not menu:check('music',v) then
                return
            end
            self.sound = love.audio.newSource(v, "static")
            for _ = 1, 5 do
                hit.soundtab[_] = love.audio.newSource('assets/sound/hit.ogg', "static")
            end
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

local previous_frame_beat = 0 -- 上一帧的节拍
local previous_frame_starting_point = 1 -- 上一帧的遍历起点
function hit:update(dt)
    if settings.hit == 0 and settings.hit_sound == 0 then
        return
    end
    if not AudioService:isPlaying() then
        return
    end
    
    local will_play_sound_number = 0
    local now_track = play:get_all_track_pos()

    --减少重复遍历
    local index_start = 1
    if AudioService:getCurrentBeat() >= previous_frame_beat then
        index_start = math.max(1, previous_frame_starting_point)
    elseif AudioService:getCurrentBeat() < previous_frame_beat then
        index_start = 1
    end
    previous_frame_beat = AudioService:getCurrentBeat()
    previous_frame_starting_point = 0

    for i = index_start, ChartService:getNoteCount() do
        local n = ChartService:getNote(i)
        local noteBeat = n:getBeatValue()
        local noteTrack = n:getTrack()
        local noteType = n:getType()
        self.hittab[noteBeat] = self.hittab[noteBeat] or {}
        self.hittab[noteBeat][noteTrack] = self.hittab[noteBeat][noteTrack] or {}
        local will_play = self.hittab[noteBeat][noteTrack]
        if will_play[noteType] == nil and not n:isFakeNote() then --不存在 记录
            will_play[noteType] = true
            if noteBeat <= AudioService:getCurrentBeat() then --时间过了 不播放
                will_play[noteType] = false
            end
        end
        if noteBeat <= AudioService:getCurrentBeat() and --播放
            will_play[noteType] then
            local x, w = now_track[noteTrack].x, now_track[noteTrack].w
            w = math.abs(w)
            will_play[noteType] = false                                            --播放完成
            index_start = i
            if self.sound and settings.hit_sound == 1 and AudioService:isPlaying() and w > 0 and not n:isFakeNote() then --播放
                will_play_sound_number = will_play_sound_number + 1

            end
            if settings.hit == 1 and AudioService:isPlaying() and w > 0 and not n:isFakeNote() and AudioService:getCurrentTime() - ChartService:toTime(noteBeat) < 0.5 then
                self.tab[#self.tab + 1] = { x = fTrack:to_play_track_x(x), time = AudioService:getCurrentTime(), track = noteTrack }
            end
        end
        if AudioService:getCurrentTime() - ChartService:toTime(noteBeat) < 0.5 and previous_frame_starting_point == 0 then
                previous_frame_starting_point = i - 1
        end
        if noteBeat > AudioService:getCurrentBeat() then --时间未到 记录
            will_play[noteType] = true --未播放
        end
    end
    will_play_sound_number = math.min(will_play_sound_number, 5) --限制同时播放的音效数量，避免过多重叠
    for i = 1,will_play_sound_number do
        self.soundtab[i]:setVolume(settings.hit_volume / 100) 
        self.soundtab[i]:seek(0) --重置音效播放位置
        self.soundtab[i]:play()
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
    local delete_it = false --删除这个键
    love.graphics.push()
    love.graphics.translate(ex, ey)

    for i,v in pairs(self.tab) do
        local hit_scale_w = 1 / self.hitW * size
        local hit_scale_h = 1 / self.hitH * size

        local hit_light_scale_w = 1 / self.lightW
        local hit_light_scale_h = 1 / self.lightH
        love.graphics.setColor(1,1,1)
        local hit_time = settings.hit_time
        local hit_alpha = (AudioService:getCurrentTime() - v.time) / hit_time
        hit_alpha = easings.out_quart(hit_alpha)

        local hit_light_time = settings.hit_light_time
        local hit_light_alpha = (AudioService:getCurrentTime() - v.time) / hit_light_time
        hit_light_alpha = hit_light_alpha * 0.5 --最大透明度为0.5

        if AudioService:getCurrentTime() - v.time > hit_time or AudioService:getCurrentTime() - v.time < 0  then
            delete_it = true
            hit_alpha = 1
        end
        if AudioService:getCurrentTime() - v.time > hit_light_time or AudioService:getCurrentTime() - v.time < 0 then
            hit_light_alpha = 1
        end


        if AudioService:isPlaying() then
            local x = v.x * sw - size / 2 * hit_alpha
            local y = judgePos - size / 2 * hit_alpha
            local w = hit_scale_w * hit_alpha
            local h = hit_scale_h * hit_alpha

            love.graphics.setColor(1, 1, 1, 1 - hit_alpha)

            love.graphics.draw(self.hit, x, y, 0, w, h)

            local x, w = fTrack:to_play_track(fEvent:get(v.track, AudioService:getCurrentBeat()))
            x = x * sw
            w = w * sw

            love.graphics.setColor(1, 1, 1,0.5 - hit_light_alpha)

            love.graphics.draw(self.light, x, judgePos - size, 0, hit_light_scale_w * w, hit_light_scale_h * size)
        end
        if delete_it then
            delete_it = false
            table.remove(self.tab, i)
        end
    end

    love.graphics.pop()
end

return hit
