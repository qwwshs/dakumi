--[[
    模块名: nineSlice
    描述: 按九宫格切线绘制音符图片；可拉伸中央或左右/上下两侧。
]]

local NineSlice = {}
local cache = setmetatable({}, {__mode = 'k'})

local function cuts(length, first, last)
    first = math.max(0, math.floor(tonumber(first) or 0))
    last = math.max(0, math.floor(tonumber(last) or 0))
    if first + last >= length then return nil end
    return {0, first, length - last, length}
end

local function sizes(source, target, mode)
    local first, middle, last = source[2] - source[1], source[3] - source[2], source[4] - source[3]
    if mode == 'sides' then
        local fixed = math.min(middle, target)
        local rest = target - fixed
        local sum = first + last
        if sum == 0 then return {0, target, 0} end
        return {rest * first / sum, fixed, rest * last / sum}
    end
    local fixed = first + last
    if target < fixed and fixed > 0 then
        return {target * first / fixed, 0, target * last / fixed}
    end
    return {first, target - fixed, last}
end

local function quads(image, config)
    local iw, ih = image:getDimensions()
    local xs = cuts(iw, config.left, config.right)
    local ys = cuts(ih, config.top, config.bottom)
    if not xs or not ys then return nil end
    local key = table.concat({xs[2], iw - xs[3], ys[2], ih - ys[3]}, ':')
    local byImage = cache[image] or {}
    cache[image] = byImage
    if byImage[key] then return byImage[key] end
    local result = {xs = xs, ys = ys, cells = {}}
    for row = 1, 3 do
        result.cells[row] = {}
        for col = 1, 3 do
            local qw, qh = xs[col + 1] - xs[col], ys[row + 1] - ys[row]
            if qw > 0 and qh > 0 then
                result.cells[row][col] = love.graphics.newQuad(xs[col], ys[row], qw, qh, iw, ih)
            end
        end
    end
    byImage[key] = result
    return result
end

function NineSlice.draw(image, x, y, width, height, config, angle)
    if not image or not width or not height or width == 0 or height == 0 then return end
    local iw, ih = image:getDimensions()
    local grid = type(config) == 'table' and width > 0 and height > 0 and quads(image, config)
    if not grid then
        if angle and angle ~= 0 then
            love.graphics.draw(image, x + width / 2, y + height / 2, angle,
                width / iw, height / ih, iw / 2, ih / 2)
        else
            love.graphics.draw(image, x, y, 0, width / iw, height / ih)
        end
        return
    end

    local ws = sizes(grid.xs, width, config.scale_x)
    local hs = sizes(grid.ys, height, config.scale_y)
    if angle and angle ~= 0 then
        love.graphics.push()
        love.graphics.translate(x + width / 2, y + height / 2)
        love.graphics.rotate(angle)
        x, y = -width / 2, -height / 2
    end
    local py = y
    for row = 1, 3 do
        local px = x
        for col = 1, 3 do
            local quad = grid.cells[row][col]
            local sw = grid.xs[col + 1] - grid.xs[col]
            local sh = grid.ys[row + 1] - grid.ys[row]
            if quad and ws[col] > 0 and hs[row] > 0 then
                love.graphics.draw(image, quad, px, py, 0, ws[col] / sw, hs[row] / sh)
            end
            px = px + ws[col]
        end
        py = py + hs[row]
    end
    if angle and angle ~= 0 then love.graphics.pop() end
end

return NineSlice
