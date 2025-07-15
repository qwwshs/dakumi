local style = {} --样式
function style:button(x,y,w,h,str,style)
    style = style or 'imgui'
    str = str or ""
    local interval = h * 0.1 --内板间隔
    if w < h then
        interval = w * 0.1
    end
    if style == 'imgui' then --类imgui

        love.graphics.setColor(0.15,0.15,0.15,0.8)
        love.graphics.rectangle("fill",x,y,w,h)


    elseif style == 'dakumi' then --dakumi 旧版风格
        love.graphics.setColor(0.5,0.5,0.5,0.5)
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("line",x,y,w,h)
        love.graphics.setColor(0.5,0.5,0.5,0.5)

        love.graphics.rectangle("fill",x + interval,y + interval,w-2*interval,h-2*interval)
    end
    local fontHeight = love.graphics.getFont():getHeight() --字体高度
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf( str, x + interval, y +h/2-fontHeight/2, w-2*interval, "center")
end

return style