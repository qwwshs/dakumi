local hit_sound = love.audio.newSource('assets/sound/hit.ogg', "stream")
local hit_light = isImage.hit_light
local hit_sound_tab ={}
local hit_tab ={}
--用来对照的 true需要播放 false为播放完成
local hit = isImage.hit
local hitlight_w, hitlight_h = hit_light:getDimensions( ) -- 得到宽高
local hit_w, hit_h = hit:getDimensions( ) -- 得到宽高
--note的打击
object_hit = {
    load = function()
        -- 读取音频文件
        local tab = love.filesystem.getDirectoryItems(PATH.usersPath.hit) --得到文件夹下的所有文件
        for i,v in ipairs(tab) do
            if string.find(v,"hit") then
                hit_sound = love.audio.newSource(v, "stream")
                break
            end
        end
    end,
    update = function(dt)
        for i = 1,#chart.note do
            if not hit_sound_tab["b"..thebeat(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] and not( chart.note[i].fake == 1) then --不存在 记录
                if thebeat(chart.note[i].beat) <= beat.nowbeat then
                    hit_sound_tab["b"..thebeat(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = false
                else
                    hit_sound_tab["b"..thebeat(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = true
                end
            end
            if thebeat(chart.note[i].beat) < beat.nowbeat and --播放
            hit_sound_tab["b"..thebeat(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] then
                local x,w = event_get(chart.note[i].track,beat.nowbeat)
                hit_sound_tab["b"..thebeat(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = false --播放完成

                if hit_sound and settings.hit_sound == 1 and music_play and w > 0 and not( chart.note[i].fake == 1) then --播放
                    love.audio.setVolume( settings.hit_volume / 100 ) --设置音量大小
                    hit_sound:seek(0)
                    hit_sound:play()
                end
                if settings.hit == 1 and music_play  and w > 0 and not( chart.note[i].fake == 1) then
                    
                    hit_tab[#hit_tab + 1] = {x = to_play_track_original_x(x),time = time.nowtime,track = chart.note[i].track}
                end
            end
            if thebeat(chart.note[i].beat) >= beat.nowbeat then
                hit_sound_tab["b"..thebeat(chart.note[i].beat).."tk"..chart.note[i].track.."ty"..chart.note[i].type] = true --未播放
            end

        end
    end,
    draw = function()
        if settings.hit == 0 then
            return
        end
        local local_hit_tab = {}
        for i = 1,#hit_tab do
            local hit_scale_w = 1 / hit_w * 300
            local hit_scale_h = 1 / hit_h * 300 / (WINDOW.scale / WINDOW.scale)
            
            local hit_light_scale_w = 1 / hitlight_w
            local hit_light_scale_h = 1 / hitlight_h  / (WINDOW.scale / WINDOW.scale)
            if demo then
                hit_scale_h = 1 / hit_h * 300 / (WINDOW.scale / WINDOW.scale)   / (1 / (WINDOW.w/900))
                hit_scale_w = 1 / hit_w * 300
            end
            love.graphics.setColor(1,1,1,1)
            local hit_alpha = math.floor((time.nowtime - hit_tab[i].time) / 0.5 * 40) /40
            local hit_light_alpha = math.floor((time.nowtime - hit_tab[i].time) / 0.5 * 19)+1
            if hit_alpha > 1 or hit_alpha < 0 then
                hit_alpha = 0
            else
                local_hit_tab[#local_hit_tab + 1] = hit_tab[i]
            end
            hit_alpha = easings.easings_use_string.out_quart(hit_alpha)
            love.graphics.setColor(1,1,1,1 - hit_alpha)
            
            if demo then
                love.graphics.draw(hit
                ,hit_tab[i].x-150 *hit_alpha,settings.judge_line_y - 150 *hit_alpha / (WINDOW.scale / WINDOW.scale) / (1 / (WINDOW.w/900)),0,hit_scale_w * hit_alpha,hit_scale_h * hit_alpha)
                
            else
                love.graphics.draw(hit
                ,hit_tab[i].x-150 *hit_alpha,settings.judge_line_y - 150 *hit_alpha  /(WINDOW.scale / WINDOW.scale),0,hit_scale_w* hit_alpha,hit_scale_h* hit_alpha)
            end

            --光效
            if not (hit_light_alpha >= 19 or hit_light_alpha <= 1) then --防止暂停时滞留
                love.graphics.setColor(1,1,1,(19-hit_light_alpha)/(19*3)) --只要1/4的alpha
                local x,w = to_play_track(event_get(hit_tab[i].track,beat.nowbeat))
                love.graphics.draw(hit_light,x,settings.judge_line_y-300  / (WINDOW.scale / WINDOW.scale),0,hit_light_scale_w*w,hit_light_scale_h*300)
            end

        end
        hit_tab = local_hit_tab
    end
}