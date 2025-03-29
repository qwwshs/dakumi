local pos = "start"
local ui_dakumi = love.graphics.newImage("asset/icon.png")
local _width, _height = ui_dakumi:getDimensions( ) -- 得到宽高
local _scale = 1 / _height * 300 

--开始界面
room_start = {
    load = function()
        -- 设置窗口为无边框模式，并调整大小为 300x300
        love.window.setMode(300, 300, {
                    fullscreen = false,
                    resizable = false,
                    borderless = true
        })
        room_pos = "start"
    end,
    draw = function()
        if elapsed_time > 3 then    return  end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(ui_dakumi, 0, 0, 0, _scale, _scale)
    end,
    update = function(dt)
        if elapsed_time > 3 and room_pos == "start" then 
            room_pos = "select"
            room_play.load()
            room_sidebar.load()
            room_select.load()
            objact_mouse.load()
            room_edit_tool.load()
            room_tracks_edit.load()
            love.resize( settings.window_width, settings.window_height )  --缩放窗口
            love.window.setMode(settings.window_width, settings.window_height, {resizable = true})
        end

    end
}