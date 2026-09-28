--Nui的封装
local ui = object:new('ui')

-- 图片按钮保留完整点击区域，图标按原始比例居中绘制。
function ui:imageButton(img, padding)
    local x, y, w, h = Nui:widgetBounds()
    local pressed = Nui:button('')
    local imageW, imageH = img:getDimensions()
    local inset = padding or 6
    local fitW = math.max(0, w - inset * 2)
    local fitH = math.max(0, h - inset * 2)
    local scale = math.min(fitW / imageW, fitH / imageH)
    if scale > 0 then
        local drawW, drawH = imageW * scale, imageH * scale
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(1, 1, 1, 1)
        Nui:image(img, x + (w - drawW) / 2, y + (h - drawH) / 2, drawW, drawH)
        love.graphics.setColor(r, g, b, a)
    end
    return pressed
end

function ui:tip(...)
    local buttonColor
    if settings.theme == 'light' then
        buttonColor = {
            ['normal'] = '#B8D9EE', -- 日间模式：浅蓝底配深色文字
            ['hover'] = '#98C8E7',
            ['active'] = '#78B3D8',
        }
    else
        buttonColor = {
            ['normal'] = '#17373F',
            ['hover'] = '#3D3D3D',
            ['active'] = '#1E6F9F',
        }
    end
    Nui:stylePush({
        ['button'] = buttonColor,
    })
    local res = Nui:button((...))
    Nui:stylePop()
    return res
end

function ui:transOrgin()
    Nui:translate((WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2, (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2)
    Nui:scale(WINDOW.scale, WINDOW.scale)
end

function ui:edit(istype,vtable)
    if iskeyboard['return'] then
        Nui:editUnfocus()
    end
    if iskeyboard['ctrl'] and iskeyboard['a'] then
        Nui:editSetSelection(0, utf8.len(vtable.value))
    end
    return Nui:edit(istype,vtable)
end

return ui
