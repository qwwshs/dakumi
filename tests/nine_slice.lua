-- 九宫格回归：验证中间/两侧拉伸的尺寸、旋转和无配置回退。
local drawn, quads, stack = {}, 0, 0
love = {graphics = {
    newQuad = function(x, y, w, h)
        quads = quads + 1
        return {x = x, y = y, w = w, h = h}
    end,
    draw = function(image, quadOrX, xOrY, yOrAngle, angleOrScaleX, scaleXOrScaleY, scaleY)
        if type(quadOrX) == 'table' then
            drawn[#drawn + 1] = {quad = quadOrX, x = xOrY, y = yOrAngle,
                w = quadOrX.w * scaleXOrScaleY, h = quadOrX.h * scaleY}
        else
            drawn[#drawn + 1] = {whole = true, x = quadOrX, y = xOrY}
        end
    end,
    push = function() stack = stack + 1 end,
    pop = function() stack = stack - 1 end,
    translate = function() end,
    rotate = function() end,
}}
local image = {getDimensions = function() return 10, 10 end}
local nineSlice = require('src.utils.nineSlice')
local config = {left = 2, right = 2, top = 2, bottom = 2, scale_x = 'center', scale_y = 'center'}

nineSlice.draw(image, 10, 20, 20, 14, config)
assert(#drawn == 9 and quads == 9)
assert(drawn[1].x == 10 and drawn[1].y == 20 and drawn[1].w == 2 and drawn[1].h == 2)
assert(drawn[2].x == 12 and drawn[2].w == 16)
assert(drawn[5].w == 16 and drawn[5].h == 10)
assert(drawn[9].x == 28 and drawn[9].y == 32)

drawn = {}
config.scale_x, config.scale_y = 'sides', 'sides'
nineSlice.draw(image, 10, 20, 20, 14, config, 0.5)
assert(#drawn == 9 and quads == 9 and stack == 0)
assert(drawn[1].w == 7 and drawn[1].h == 4)
assert(drawn[5].w == 6 and drawn[5].h == 6)
assert(drawn[9].x == 3 and drawn[9].y == 3)

drawn = {}
nineSlice.draw(image, 1, 2, 20, 14)
assert(#drawn == 1 and drawn[1].whole and drawn[1].x == 1 and drawn[1].y == 2)
drawn = {}
nineSlice.draw(image, 1, 2, 20, 14, {left = 6, right = 6})
assert(#drawn == 1 and drawn[1].whole)
print('nine slice PASS')
