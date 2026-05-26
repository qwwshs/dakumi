--窗口管理
window = {}

function window:new(groupOrRoom,x,y,w,h)
    groupOrRoom._window = {
        x = x or 0,
        y = y or 0,
        w = w or love.graphics.getWidth(),
        h = h or love.graphics.getHeight()
    }
    groupOrRoom._window_now = {
        x = x or 0,
        y = y or 0,
        w = w or love.graphics.getWidth(),
        h = h or love.graphics.getHeight()
    }
    function groupOrRoom:windowTrans(isdraw)
        --根据_window_now与_window调整坐标 并返回新的鼠标坐标
        local scaleX = self._window.w / self._window_now.w
        local scaleY = self._window.h / self._window_now.h
        if isdraw then    
            love.graphics.push()
            love.graphics.translate(-self._window_now.x * scaleX, -self._window_now.y * scaleY)
            love.graphics.scale(scaleX, scaleY)
        else
            local newMouseX = (mouse.x + self._window_now.x) * scaleX
            local newMouseY = (mouse.y + self._window_now.y) * scaleY
            return newMouseX, newMouseY
        end
    end
    function groupOrRoom:windowTransend(isdraw)
        if isdraw then
            love.graphics.pop()
        end
    end
end

