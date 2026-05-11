--Nui的封装
local ui = object:new('ui')

function ui:tip(...)
    Nui:stylePush({
    ['button'] = {
        ['normal'] = '#17373F', -- 按钮默认
        ['hover'] = '#3D3D3D', -- 按钮悬停
        ['active'] = '#1E6F9F'
    }
    })
    local res = Nui:button((...))
    Nui:stylePop()
    return res
end

function ui:transOrgin()
    Nui:translate((WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2, (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2)
    Nui:scale(WINDOW.scale, WINDOW.scale)
end
return ui
