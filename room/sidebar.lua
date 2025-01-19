displayed_content = "nil" --显示的内容
local pos  = {"edit",'tracks_edit'}
--侧边栏
function room_type(type) -- 房间状态判定
    return type == displayed_content
end
room_sidebar = {
    load = function()
        objact_button_chart_info.load(1250,100,0,150,50)
        objact_button_settings.load(1250,200,0,150,50)
        objact_button_track_sidebar.load(1250,300,0,150,50)
        objact_button_tracks_edit.load(1250,400,0,150,50)

        objact_events_edit.load(1250,100,0,150,50)
        objact_button_break.load(1570,0,0,30,30)
        objact_button_togithub.load(1565,765,0,25,25)
        objact_button_todakumi.load(1540,765,0,25,25)
    end,
    update = function(dt)
        if not the_room_pos(pos) then
            return
        end
        objact_event_edit.update(dt)
    end,
    
    draw = function()
        if not the_room_pos(pos) then
            return
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("fill",1220,0,-3,800) --侧线
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("fill",1220-5,0,-1,800) --侧线2
        love.graphics.setColor(0.1,0.1,0.1,0.5)
        love.graphics.rectangle("fill",1220,0,400,800) --背景板
        objact_chart_info.draw()
        objact_settings.draw()
        objact_track_sidebar.draw()
        objact_tracks_edit.draw()
        objact_event_edit.draw()
        objact_note_edit.draw()
        objact_events_edit.draw()
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(objact_language.get_string_in_languages(displayed_content),1250,50)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(objact_language.get_string_in_languages("version")..version,1500,50)
        local fps = love.timer.getFPS( )
        love.graphics.print("FPS:"..fps,1230,760)
    end,
    keypressed = function(key)
        if not the_room_pos(pos) then
            return
        end
        objact_chart_info.keypressed(key)
        objact_track_sidebar.keypressed(key)
        objact_settings.keypressed(key)
        objact_event_edit.keypressed(key)
        objact_button_break.keyboard(key)
    end,
    
    wheelmoved = function(x,y)
        if not the_room_pos(pos) then
            return
        end
        if mouse.x < 1200 then --限制范围
            return
        end
        objact_chart_info.wheelmoved(x,y)
        objact_settings.wheelmoved(x,y)
        objact_tracks_edit.wheelmoved(x,y)
        objact_track_sidebar.wheelmoved(x,y)
    end,
    mousepressed = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
        objact_chart_info.mousepressed( x, y, button, istouch, presses )
        objact_tracks_edit.mousepressed( x, y, button, istouch, presses )
        objact_settings.mousepressed( x, y, button, istouch, presses )
        objact_event_edit.mousepressed( x, y, button, istouch, presses )
        objact_track_sidebar.mousepressed( x, y, button, istouch, presses )
    end,
    mousereleased = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
        objact_event_edit.mousereleased( x, y, button, istouch, presses )
    end,
}