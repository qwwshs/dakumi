local play = nil
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function will_draw_play()
    return music_play and the_room_pos({"edit",'tracks_edit'}) and not demo_mode
end
local function will_draw_pause()
    return (not music_play) and the_room_pos({"edit",'tracks_edit'}) and not demo_mode
end
local function will_do ()
    music_play = not music_play
    music:seek(time.nowtime - chart.offset / 1000 )
end
objact_music_play = { --分度改变用的
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("music_play",will_do,x,y,w,h,ui:pause(x,y,w,h),{will_draw = will_draw_play}) --ui反着写因为play与pause是相反显示的
        button_new("music_pause",will_do,x,y,w,h,ui:play(x,y,w,h),{will_draw = will_draw_pause})
    end,
    draw = function()
    end,
    keyboard = function(key)
        if key == "space" and mouse.x < 1200 then
            will_do()
        end
    end,
    mousepressed = function( x1, y1, button, istouch, presses )
    end,
    update = function(dt)
        if music_play then
            time.nowtime = time.nowtime + dt * music_speed
            beat.nowbeat = time_to_beat(chart.bpm_list,time.nowtime)

            if math.abs(music:tell("seconds") - (time.nowtime - chart.offset / 1000)) >= 0.05 then --不知道出来什么bug在开头的一段时间内滚动滚轮 然后音乐时间就会翻倍
                music:seek(time.nowtime - chart.offset / 1000 ) --补正播放差值
            end
            if time.nowtime - chart.offset / 1000 >= 0 then
                if music then
                    music:setPitch(music_speed)
                    love.audio.setVolume( settings.music_volume / 100 ) --设置音量大小
                    music:play()
                end
            end
    
        else
            if music then
                music:pause() 
            end
            if time.nowtime - (chart.offset / 1000) >= 0 and time.nowtime  <= time.alltime then
                if music then
                    music:seek(time.nowtime - chart.offset / 1000 )
                end
            else -- 超时
                if music then
                    music:seek(0)
                    love.audio.setVolume( 0 ) --设置音量大小
                    time.nowtime = chart.offset / 1000
                end
            end
        end
    end,
}