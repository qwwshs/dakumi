local sidebar =  group:new('sidebar')

sidebar.layout = require 'config.layouts.sidebar'

sidebar:addGroup(require 'src.objects.sidebar.nil')
sidebar:addGroup(require 'src.objects.sidebar.track')
sidebar:addGroup(require 'src.objects.sidebar.settings')
sidebar:addGroup(require 'src.objects.sidebar.preference')
sidebar:addGroup(require 'src.objects.sidebar.chart_info')
sidebar:addGroup(require 'src.objects.sidebar.event')

sidebar.displayed_content = "nil" --现在所在的界面
sidebar.incoming = {} --传入的参数
function sidebar:to(type,...) -- 更变房间
    self.incoming = {...}
    self.displayed_content = type
    local g = self:getGroup(self.displayed_content)
    if g.to then
        g:to(...)
    end
end

function sidebar:room_type(type) -- 房间状态判定
    return type == sidebar.displayed_content
end

function sidebar:load()
    self('load')
    object_events_edit.load(1250,100,0,150,50)
end

function sidebar:update(dt)
    self('update',dt)
    local layout = self.layout
    local g = self:getGroup(self.displayed_content)
    if Nui:windowBegin('sidebar', layout.x, layout.y, layout.w, layout.h,'border','scrollbar','background') then
        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:label(i18n:get(sidebar.displayed_content))
        Nui:label(i18n:get("version")..DAKUMI._VERSION)

        if Nui:button(i18n:get("break")) then
            messageBox:add("track")
            sidebar.displayed_content = "nil"
        end
        if g and g.Nui then
            g:Nui()
        end

        Nui:label("FPS:"..love.timer.getFPS( ))
        Nui:windowEnd()
    end

    if g and g.NuiNext then
        g:NuiNext()
    end

end

function sidebar:draw()
    self('draw')

    object_tracks_edit.draw()
    object_note_edit.draw()
    object_events_edit.draw()

end

function sidebar:keypressed(key)
    self('keypressed',key)
end

function sidebar:wheelmoved(x,y)
    if mouse.x < 1200 then --限制范围
        return
    end
    self('wheelmoved',x,y)
    object_tracks_edit.wheelmoved(x,y)
end

function sidebar:mousepressed( x, y, button, istouch, presses )
    self('mousepressed', x, y, button, istouch, presses )
    object_tracks_edit.mousepressed( x, y, button, istouch, presses )
end

function sidebar:mousereleased( x, y, button, istouch, presses )
    self('mousereleased', x, y, button, istouch, presses )
end

return sidebar