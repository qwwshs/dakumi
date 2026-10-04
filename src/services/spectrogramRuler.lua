local AudioService = require('src.services.audioService')
--[[
    模块名: spectrogramRuler
    描述: 轨道信息下方的 Nuklear 频率尺；频率缩放只在尺上接收滚轮，不改变编辑区的时间操作。
]]
local Config = require('src.services.spectrogramConfig')
local Ruler = {}
local rulerFrame, bounds = nil, {}
local function clamp(n, low, high) return math.max(low, math.min(high, n)) end

function Ruler:zoom(factor, position, pan)
    if not AudioService:getSoundData() then return end
    local o = Config.read(settings, AudioService:getSoundData():getSampleRate())
    local low, high, limit = o.minHz, o.maxHz, AudioService:getSoundData():getSampleRate() / 2
    local logarithmic = o.scale ~= 'linear'
    if logarithmic then low, high, limit = math.log(low), math.log(high), math.log(limit) end
    local minimum = logarithmic and 0 or 1
    local span = clamp((high - low) / factor, logarithmic and math.log(2) / 120 or 1, limit - minimum)
    local anchor = low + (high - low) * position
    low = clamp(anchor - span * position + (pan or 0) * span, minimum, limit - span)
    high = low + span
    settings.spectrogram_min_hz = logarithmic and math.exp(low) or low
    settings.spectrogram_max_hz = logarithmic and math.exp(high) or high
end

function Ruler:wheelmoved(_, y)
    if not settings or settings.spectrogram ~= 1 or settings.spectrogram_ruler == 0 or rulerFrame ~= elapsed_time then return false end
    for _, r in ipairs(bounds) do
        if mouse.x >= r.x and mouse.x < r.x + r.w and mouse.y >= r.y and mouse.y < r.y + r.h then
            local pan = love.keyboard.isDown('lshift', 'rshift')
            self:zoom(pan and 1 or 1.25 ^ y, clamp((mouse.x - r.axisX) / r.axisWidth, 0, 1), pan and -y * 0.15 or 0)
            return true
        end
    end
    return false
end

function Ruler:contains(x, y)
    if not settings or settings.spectrogram ~= 1 or settings.spectrogram_ruler == 0 or rulerFrame ~= elapsed_time then return false end
    for _, r in ipairs(bounds) do
        if x >= r.x and x < r.x + r.w and y >= r.y and y < r.bottom then return true end
    end
    return false
end

function Ruler:draw(ui, x, width)
    if not AudioService:getSoundData() or settings.spectrogram ~= 1 or settings.spectrogram_ruler == 0 then return end
    local o = Config.read(settings, AudioService:getSoundData():getSampleRate())
    ui:layoutRow('dynamic', 28, 1)
    local rx, ry, rw, rh = ui:widgetBounds()
    ui:label('')
    if rulerFrame ~= elapsed_time then rulerFrame, bounds = elapsed_time, {} end
    local left = math.max(rx, play and play.layout.x or rx)
    local right = math.min(rx + rw, play and play.layout.x + play.layout.w or rx + rw)
    local hitArea = {x = left, y = ry, w = math.max(0, right - left), h = rh, bottom = ry + rh, axisX = x, axisWidth = width}
    bounds[#bounds + 1] = hitArea
    local r, g, b, a = love.graphics.getColor()
    local lineWidth = love.graphics.getLineWidth()
    if settings.theme == 'light' then love.graphics.setColor(0.12, 0.14, 0.17, 1)
    else love.graphics.setColor(0.85, 0.87, 0.91, 1) end
    love.graphics.setLineWidth(1)
    local lastLabel = -math.huge
    local function tick(hz, label, major)
        local px = x + Config.position(o, hz) * width
        if px < rx or px >= rx + rw then return end
        ui:line(px, ry, px, ry + (major and 7 or 3))
        if label and px - lastLabel >= 30 and px < rx + rw - 14 then
            ui:text(label, clamp(px - 15, rx, rx + rw - 36), ry + 8, 42, 18)
            lastLabel = px
        end
    end
    if o.scale == 'pitch' then
        local first, last = Config.midi(o.minHz), Config.midi(o.maxHz)
        local semitonePixels = width / (last - first)
        local step = semitonePixels >= 24 and 0.5 or 1
        for midi = math.ceil(first / step) * step, last, step do
            local hz = Config.hz(midi)
            local label = Config.pitchName(hz):match('^(%S+)')
            local major = midi % 1 == 0 and (semitonePixels >= 8 or midi % 12 == 0)
            tick(hz, major and label or nil, major)
        end
    elseif o.scale == 'linear' then
        local step = 10 ^ math.floor(math.log((o.maxHz - o.minHz) / 6) / math.log(10))
        for hz = math.ceil(o.minHz / step) * step, o.maxHz, step do
            tick(hz, hz >= 1000 and string.format('%gk', hz / 1000) or string.format('%g', hz), true)
        end
    else
        for power = math.floor(math.log(o.minHz) / math.log(10)), math.ceil(math.log(o.maxHz) / math.log(10)) do
            for _, multiple in ipairs({1, 2, 5}) do
                local hz = multiple * 10 ^ power
                tick(hz, hz >= 1000 and string.format('%gk', hz / 1000) or string.format('%g', hz), true)
            end
        end
    end
    love.graphics.setColor(r, g, b, a)
    love.graphics.setLineWidth(lineWidth)
end

return Ruler
