
local buttonMusicPlay = object:new('music_play')
buttonMusicPlay.type = 'button'
buttonMusicPlay.text = 'play'
buttonMusicPlay.text2 = 'pause'
buttonMusicPlay.img = isImage.play
buttonMusicPlay.img2 = isImage.pause

function buttonMusicPlay:click()
    music_play = not music_play
    music:seek(time.nowtime - chart.offset / 1000 )
    buttonMusicPlay.img,buttonMusicPlay.img2 = buttonMusicPlay.img2,buttonMusicPlay.img
    buttonMusicPlay.text,buttonMusicPlay.text2 = buttonMusicPlay.text2,buttonMusicPlay.text
end

function buttonMusicPlay:keypressed(key)
    if key == "space" and mouse.x < 1200 then
        self:click()
    end
end

function buttonMusicPlay:update(dt)
    if music_play then
        time.nowtime = time.nowtime + dt * musicSpeed.speed
        beat.nowbeat = time_to_beat(chart.bpm_list,time.nowtime)
        
        if not music then return end
        
        if math.abs(music:tell("seconds") - (time.nowtime - chart.offset / 1000)) >= 0.05 then --疑似love2d有bug 音频在刚播放0.5s内时间对不上
            music:seek(time.nowtime - chart.offset / 1000 ) --补正播放差值
        end

        if time.nowtime - chart.offset / 1000 >= 0 then
            music:setPitch(musicSpeed.speed)
            love.audio.setVolume( settings.music_volume / 100 ) --设置音量大小
            music:play()
        end

    else
        if not music then return end

        music:pause() 
        if time.nowtime - (chart.offset / 1000) >= 0 and time.nowtime  <= time.alltime then
                music:seek(time.nowtime - chart.offset / 1000 )
        else -- 超时
            music:seek(0)
            love.audio.setVolume( 0 ) --设置音量大小
            time.nowtime = chart.offset / 1000
        end
    end
end

return buttonMusicPlay