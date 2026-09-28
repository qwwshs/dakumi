--[[
    模块名: colors/editTool
    描述: 编辑工具栏的颜色配置，从 base 基色派生
]]

local c = require('config.colors.base')
local rgba = c.rgba
local base = c.base

local colors = {
    sliderLine = rgba(base.white, 0.5),    -- 半透白: 滑块轨道线
    slider     = rgba(base.dgray, 0.7),    -- 深灰: 滑块背景
    progress   = rgba(base.white, 1),      -- 纯白: 进度条
}

function colors.setTheme(theme)
    local light = theme == 'light'
    local ink = light and {0.13, 0.14, 0.16} or {1, 1, 1}
    local panel = light and {0.88, 0.90, 0.93} or {0.18, 0.18, 0.18}
    for _, key in ipairs({'sliderLine', 'progress'}) do
        local color = colors[key]
        color[1], color[2], color[3] = ink[1], ink[2], ink[3]
    end
    local slider = colors.slider
    slider[1], slider[2], slider[3] = panel[1], panel[2], panel[3]
end

return colors
