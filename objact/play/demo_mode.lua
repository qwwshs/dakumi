
objact_demo_mode ={ --演示谱面用的
    draw = function()
        if demo_mode then
            love.graphics.translate(0,0)
            love.graphics.scale( 1600 / 900,1)
            mouse.x = 0 --解决x 大于1200无法进行space tab的问题
        end
    end,
    keyboard = function(key)
        if key == "tab"  then
            if not demo_mode then
                music_speed = 1
            end
            demo_mode = not demo_mode
            objact_music_speed.update()
            objact_mouse.update()
        end
        if key == "space" and demo_mode then --弥补一下没法在demo模式下按空格
            objact_music_play.keyboard("space")
        end
    end
}