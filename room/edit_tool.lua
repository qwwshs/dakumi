local pos = {"edit",'tracks_edit'} --编辑工具

local tool_canvas

room_edit_tool = {
    load = function()
        objact_note_fake.load(info_to_load(info.edit_tool.note_fake))
        
        objact_music_speed.load(info_to_load(info.edit_tool.music_speed))
        objact_denom.load(info_to_load(info.edit_tool.denom))
        objact_track.load(info_to_load(info.edit_tool.track))
        objact_track_scale.load(info_to_load(info.edit_tool.track_scale))
        objact_track_fence.load(info_to_load(info.edit_tool.track_fence))
        objact_music_play.load(info_to_load(info.edit_tool.music_play))
        objact_note.load(info_to_load(info.edit_tool.note))
        objact_save.load(info_to_load(info.edit_tool.save))
        objact_slider.load(info_to_load(info.edit_tool.slider))
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
        --顶上的工具栏
        love.graphics.setColor(0.1,0.1,0.1,0.9)
        love.graphics.rectangle("fill",info.edit_tool.x,info.edit_tool.y,info.edit_tool.w,info.edit_tool.h)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("fill",info.edit_tool.x,info.edit_tool.y + info.edit_tool.h+info.edit_tool.y,info.edit_tool.w,2)
                    
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