local sidebar =  group:new('sidebar')

sidebar.layout = require 'config.layouts.sidebar'

sidebar:addGroup(require 'src.objects.sidebar.nil')

sidebar.displayed_content = "nil" --现在所在的界面

function sidebar:room_type(type) -- 房间状态判定
    return type == sidebar.displayed_content
end

function sidebar:load()
    self('load')
    object_events_edit.load(1250,100,0,150,50)
    object_button_break.load(1570,0,0,30,30)
    object_button_togithub.load(1565,765,0,25,25)
    object_button_todakumi.load(1540,765,0,25,25)
end

function sidebar:update(dt)
    self('update',dt)
    local layout = self.layout
    if Nui:windowBegin('sidebar', layout.x, layout.y, layout.w, layout.h,'border') then
        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:label(i18n:get(sidebar.displayed_content))
        Nui:label(i18n:get("version")..DAKUMI._VERSION)

        local g = self:getGroup(self.displayed_content)
        if g then
            g:Nui()
        end

        Nui:label("FPS:"..love.timer.getFPS( ))
        Nui:windowEnd()
    end

    object_event_edit.update(dt)
end

function sidebar:draw()
    self('draw')

    object_chart_info.draw()
    object_preference.draw()
    object_settings.draw()
    object_track_sidebar.draw()
    object_tracks_edit.draw()
    object_event_edit.draw()
    object_note_edit.draw()
    object_events_edit.draw()

end

function sidebar:keypressed(key)
    self('keypressed',key)
    object_chart_info.keypressed(key)
    object_track_sidebar.keypressed(key)
    object_settings.keypressed(key)
    object_event_edit.keypressed(key)
    object_button_break.keypressed(key)
end

function sidebar:wheelmoved(x,y)
    if mouse.x < 1200 then --限制范围
        return
    end
    self('wheelmoved',x,y)
    object_chart_info.wheelmoved(x,y)
    object_preference.wheelmoved(x,y)
    object_settings.wheelmoved(x,y)
    object_tracks_edit.wheelmoved(x,y)
    object_track_sidebar.wheelmoved(x,y)
end

function sidebar:mousepressed( x, y, button, istouch, presses )
    self('mousepressed', x, y, button, istouch, presses )
    object_chart_info.mousepressed( x, y, button, istouch, presses )
    object_tracks_edit.mousepressed( x, y, button, istouch, presses )
    object_settings.mousepressed( x, y, button, istouch, presses )
    object_event_edit.mousepressed( x, y, button, istouch, presses )
    object_track_sidebar.mousepressed( x, y, button, istouch, presses )
end

function sidebar:mousereleased( x, y, button, istouch, presses )
    self('mousereleased', x, y, button, istouch, presses )
    object_event_edit.mousereleased( x, y, button, istouch, presses )
end

return sidebar