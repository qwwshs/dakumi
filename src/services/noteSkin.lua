-- 音符图像统一绘制入口；未配置九宫格时保持原来的整图缩放。
local ThemeService = require('src.services.themeService')
local NineSlice = require('src.utils.nineSlice')

local NoteSkin = {}

function NoteSkin.draw(kind, image, x, y, width, height, angle)
    NineSlice.draw(image, x, y, width, height, ThemeService:slice(kind), angle)
end

return NoteSkin
