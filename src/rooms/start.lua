local ui_dakumi = isImage.dakumi
local ui_dakumi_pixel = isImage.dakumi_pixel
local display_duration = 1 -- 显示长
local icon = 'dakumi'
start = room:new("start")
room:addRoom(start)
function start:load()
    -- 设置窗口为无边框模式，并调整大小为 300x300
    love.window.setMode(300, 300, {
                fullscreen = false,
                resizable = false,
                borderless = true
    })
    if math.random() > 0.7 then
        love.window.setIcon(love.image.newImageData('assets/img/dakumi-pixel.png'))
        icon = 'dakumi-pixel'
    else
        love.window.setIcon(love.image.newImageData('assets/img/icon.png'))
    end
end

function start:draw()
    love.graphics.setColor(1, 1, 1, 1)
    if icon == 'dakumi-pixel' then
        local _width, _height = ui_dakumi_pixel:getDimensions( ) -- 得到宽高
        local _scale = 1 / _height * 300
        love.graphics.draw(ui_dakumi_pixel, 0, 0, 0, _scale, _scale)
    elseif icon == 'dakumi' then
        local _width, _height = ui_dakumi:getDimensions( ) -- 得到宽高
        local _scale = 1 / _height * 300
        love.graphics.draw(ui_dakumi, 0, 0, 0, _scale, _scale)
    end
    
end

function start:update(dt)
    if elapsed_time > display_duration then 
        love.resize( settings.window_width, settings.window_height )  --缩放窗口
        love.window.setMode(settings.window_width, settings.window_height, {resizable = true})
        room:to('menu')
    end

end