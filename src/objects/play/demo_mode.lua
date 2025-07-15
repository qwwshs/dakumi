
object_demo_mode ={ --演示谱面用的
    draw = function()
        if demo then
            love.graphics.translate(0,0)
            love.graphics.scale( WINDOW.w / 900,1)
            mouse.x = 0 --解决x 大于1200无法进行space tab的问题
        end
    end,
    keyboard = function(key)
        if key == "tab"  then
            if not demo then
                musicSpeed.speed = 1
            end
            demo = not demo
            musicSpeed:to(1)
        end
        if key == "space" and demo then --弥补一下没法在demo模式下按空格
            music_play = not music_play
        end
    end
}