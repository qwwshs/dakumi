--[[
    模块名: colors/menu
    描述: 菜单界面的颜色配置，从 base 基色派生
]]

local c = require('config.colors.base')
local rgba = c.rgba
local base = c.base

local colors = {
    -- 白色系（文字/线条）
    white       = rgba(base.white, 1),     -- 纯白: selectThisMusicText, selectThischartText, line3
    white_half  = rgba(base.white, 0.5),   -- 半透白: unSelectThisMusicText, unSelectThischartText, fft, line2
    white_fade  = rgba(base.white, 0.2),   -- 淡白: selectThisMusicTextBg, chartInofoBg, line1
    white_dim   = rgba(base.white, 0.1),   -- 极淡白: line4

    -- 背景/特殊色
    dgray = rgba(base.dgray, 0.7),         -- 深灰: bg
    lred  = rgba(base.lred, 1),            -- 浅红: errorChart
}

function colors.setTheme(theme)
    local light = theme == 'light'
    local ink = light and {0.13, 0.14, 0.16} or {1, 1, 1}
    for _, key in ipairs({'white', 'white_half', 'white_fade', 'white_dim'}) do
        local color = colors[key]
        color[1], color[2], color[3] = ink[1], ink[2], ink[3]
    end
    local bgColor = colors.dgray
    local bg = light and {0.88, 0.90, 0.93} or {0.18, 0.18, 0.18}
    bgColor[1], bgColor[2], bgColor[3] = bg[1], bg[2], bg[3]
end

return colors
