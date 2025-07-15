local ui_dakumi = isImage.dakumi
local _width, _height = ui_dakumi:getDimensions( ) -- 得到宽高
local _scale = 1 / _height * 300 


start = room:new("start")
room:addRoom(start)
function start:load()
    -- 设置窗口为无边框模式，并调整大小为 300x300
    love.window.setMode(300, 300, {
                fullscreen = false,
                resizable = false,
                borderless = true
    })
end

function start:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ui_dakumi, 0, 0, 0, _scale, _scale)
end

function start:update(dt)
    if elapsed_time > 0 then 
        room_tracks_edit.load()
        love.resize( settings.window_width, settings.window_height )  --缩放窗口
        love.window.setMode(settings.window_width, settings.window_height, {resizable = true})

        room:to('menu')
    end

end