local pos = {"edit",'tracks_edit'} --编辑工具

local tool_canvas

room_edit_tool = {
    load = function()
        -- 设置Canvas为当前绘图目标
            tool_canvas = love.graphics.newCanvas(1300, 120) --画布
            love.graphics.setCanvas(tool_canvas)

            -- 在Canvas上绘制一些内容
            love.graphics.clear() -- 清空
            --顶上的工具栏
            love.graphics.setColor(0.1,0.1,0.1,0.9)
            love.graphics.rectangle("fill",0,0,1220-5,100)
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("fill",0,100,1220-5,2)
            
            love.graphics.setColor(1,1,1,1)
        
            -- 重置绘图目标为默认（屏幕）
            love.graphics.setCanvas()

        
        objact_note_fake.load(100,25,0,25,25)
        
        objact_music_speed.load(575,50,0,25,25)
        objact_denom.load(875,50,0,25,25)
        objact_track.load(725,50,0,25,25)
        objact_track_scale.load(800,50,0,25,25)
        objact_track_fence.load(650,50,0,25,25)
        objact_music_play.load(400,50,0,50,50)
        objact_note.load(400,50,0,50,16.6)
        objact_save.load(50,50,0,50,50)
        objact_slider.load(0,100,0,20,700)
    end,
    update = function(dt)
        if not the_room_pos(pos) then
            return
        end
        objact_music_play.update(dt)
        objact_slider.update(dt)
        objact_save.update(dt)
    end,
    draw = function()
        if not the_room_pos(pos) then
            return
        end
        if demo_mode then
            return
        end
        love.graphics.draw(tool_canvas, 0, 0)
        --放置假note
        objact_note_fake.draw()
        --ui 节拍线
        objact_denom.draw()
    
        --ui 播放速度调节
        objact_music_speed.draw()
    
        --ui 轨道缩放 第几轨道
        objact_track_scale.draw()
        objact_track.draw()
        objact_track_fence.draw()
        --播放键
        objact_music_play.draw()
    
        --保存键
        objact_save.draw()
    
    
        --进度条
        objact_slider.draw()
    
    
    end,
    keypressed = function(key)
        if not the_room_pos(pos) then
            return
        end
        if demo_mode then
            return
        end
        objact_denom.keyboard(key)
        objact_music_speed.keyboard(key)
        objact_track.keyboard(key)
        objact_track_scale.keyboard(key)
    
        objact_music_play.keyboard(key)
        objact_save.keyboard(key)
    
    
    end,
    mousepressed = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
        if demo_mode then
            return
        end
        objact_denom.mousepressed( x, y, button, istouch, presses )
        objact_music_speed.mousepressed( x, y, button, istouch, presses )
        objact_track_scale.mousepressed( x, y, button, istouch, presses )
        objact_track.mousepressed( x, y, button, istouch, presses )
        objact_track_fence.mousepressed( x, y, button, istouch, presses )
        objact_music_play.mousepressed( x, y, button, istouch, presses )
        objact_save.mousepressed( x, y, button, istouch, presses )
        objact_slider.mousepressed( x, y, button, istouch, presses )
    end,
    textinput = function(input)
        if not the_room_pos(pos) then
            return
        end
        if demo_mode then
            return
        end
        objact_denom.textinput(input)
        objact_music_speed.textinput(input)
        objact_track_scale.textinput(input)
        objact_track.textinput(input)
    end,
    mousereleased = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
        if demo_mode then
            return
        end
        objact_slider.mousereleased(x, y, button, istouch, presses)
    end,
    wheelmoved = function(x,y)
        if not the_room_pos(pos) then
            return
        end
        if demo_mode then
            return
        end
    end,
    quit = function()
        if not the_room_pos(pos) then
            return
        end
        return objact_save.quit()
    end
}