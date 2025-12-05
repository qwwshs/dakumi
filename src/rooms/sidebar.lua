local sidebar =  group:new('sidebar')
sidebar.layout = require 'config.layouts.sidebar'

sidebar:addGroup(require 'src.objects.sidebar.nil')
sidebar:addGroup(require 'src.objects.sidebar.track')
sidebar:addGroup(require 'src.objects.sidebar.settings')
sidebar:addGroup(require 'src.objects.sidebar.preference')
sidebar:addGroup(require 'src.objects.sidebar.chart_info')
sidebar:addGroup(require 'src.objects.sidebar.event')
sidebar:addGroup(require 'src.objects.sidebar.note')
sidebar:addGroup(require 'src.objects.sidebar.events')

sidebar.displayed_content = "nil" --现在所在的界面
sidebar.incoming = {} --传入的参数

function sidebar:to(ty,...) -- 更变房间
    self.incoming = {...}
    self.displayed_content = ty
    local g = self:getGroup(self.displayed_content)
    if type(g.to) == 'function' then
        g:to(...)
    end
end

function sidebar:room_type(type) -- 房间状态判定
    return type == sidebar.displayed_content
end

function sidebar:load()
    self('load')
end

function sidebar:update(dt)
    self('update',dt)
    local layout = self.layout
    local g = self:getGroup(self.displayed_content)
    if Nui:windowBegin('sidebar', layout.x, layout.y, layout.w, layout.h,'border','scrollbar','background') then
        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:label(i18n:get(sidebar.displayed_content))
        Nui:label(i18n:get("version")..DAKUMI._VERSION)
        
        if self.displayed_content ~= 'nil' then
            if Nui:button(i18n:get("break")) then
                messageBox:add("track")
                sidebar:to("nil")
            end
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
end

function sidebar:keypressed(key)
    self('keypressed',key)
end

function sidebar:wheelmoved(x,y)
    if mouse.x < self.layout.x then --限制范围
        return
    end
    self('wheelmoved',x,y)
end

function sidebar:mousepressed( x, y, button, istouch, presses )
    self('mousepressed', x, y, button, istouch, presses )
end

function sidebar:mousereleased( x, y, button, istouch, presses )
    self('mousereleased', x, y, button, istouch, presses )
end

return sidebar