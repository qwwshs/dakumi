--[[
    模块名: spectrogramService
    描述: 保留完整数值频谱，以固定时间格缓存；按屏幕像素汇总后由 GPU 转分贝、调色。
    改变频率范围不重新分析音频，改变亮度不重建贴图；多标签页共享后台任务与贴图。
]]
local ChartService = require('src.services.chartService')
local CoordinateService = require('src.services.coordinateService')
local Config = require('src.services.spectrogramConfig')
local Analyzer = require('src.services.spectrogramAnalyzer')
local Spectrogram = {}
local hasFFI, ffi = pcall(require, 'ffi')
local TILE_ROWS, CACHE_BYTES, BUILD_BUDGET = 32, 96 * 1024 * 1024, 0.002
local LOG_10 = math.log(10)
local cache = {values = {}, order = {}, next = 1, count = 0}
local view = {tiles = {}, pending = 0}
local worker, requests, responses, cancellation, workerFailed
local scheduled, scheduleToken, generation = {}, 0, 0
local lastRange, lastStep, currentSound, analysisKey, fallback, partial
local renderer
local stats = {analyzedFrames = 0, projectedFrames = 0, uploads = 0}

local function clamp(n, low, high) return math.max(low, math.min(high, n)) end
local function clock() return love.timer.getTime() end
local function cacheKey(step, cell) return step .. ':' .. cell end

local function cancelBuild()
    scheduleToken = scheduleToken + 1
    scheduled, lastRange, lastStep, partial = {}, nil, nil, nil
    if requests then requests:clear() end
    if cancellation then cancellation:clear(); cancellation:push(scheduleToken) end
end

local function reset(sound, options)
    cancelBuild()
    generation = generation + 1
    currentSound, analysisKey = sound, options.mode .. '|' .. options.window
    cache = {values = {}, order = {}, next = 1, count = 0,
        limit = math.floor(CACHE_BYTES / ((options.size / 2 + 1) * 4))}
    view.key, view.axis, view.pending, fallback = nil, nil, 0, nil
    stats.analyzedFrames, stats.projectedFrames, stats.uploads = 0, 0, 0
end

local function cachePut(key, entry)
    if not cache.values[key] then
        local old = cache.order[cache.next]
        if old then cache.values[old] = nil else cache.count = cache.count + 1 end
        cache.order[cache.next], cache.next = key, cache.next % cache.limit + 1
    end
    cache.values[key] = entry
end

local function receiveResults(options)
    if not responses then return end
    while true do
        local result = responses:pop()
        if not result then break end
        if result.error then workerFailed = result.error; break end
        if result.generation == generation then
            local pointer = ffi.cast('const float*', result.data:getPointer())
            local bins = options.size / 2 + 1
            for i, key in ipairs(result.keys) do
                if scheduled[key] == result.token then scheduled[key] = nil end
                cachePut(key, {values = pointer + (i - 1) * bins, owner = result.data})
            end
            stats.analyzedFrames = stats.analyzedFrames + result.frames
        end
    end
end

local workerCode = [[
local path, requests, responses, cancellation = ...
package.path = path
require('src.thread.spectrogram')(requests, responses, cancellation)
]]

local function buildInBackground(sound, options)
    if workerFailed or not hasFFI or not love.thread then return false end
    if not worker or not worker:isRunning() then
        local ok, message = pcall(function()
            requests, responses, cancellation = love.thread.newChannel(), love.thread.newChannel(), love.thread.newChannel()
            cancelBuild()
            worker = love.thread.newThread(workerCode)
            worker:start(package.path, requests, responses, cancellation)
        end)
        if not ok then workerFailed = tostring(message); return false end
    end
    if not view.first then return true end
    -- 普通播放只追加任务。跳到不相交的时间段、切换时间精度时才取消过时工作。
    if lastStep ~= view.step or (lastRange and (view.last < lastRange[1] or view.first > lastRange[2])) then
        cancelBuild()
    end
    lastRange, lastStep = {view.first, view.last}, view.step
    local cells = {}
    local function enqueue(cell)
        local key = cacheKey(view.step, cell)
        if not cache.values[key] and not scheduled[key] then
            cells[#cells + 1], scheduled[key] = cell, scheduleToken
        end
    end
    -- 先补靠近判定线的当前视野，再预取前方 1.5 秒；预取总量受缓存大小约束。
    for cell = view.first, view.last do enqueue(cell) end
    local ahead = math.min(math.ceil(1.5 * sound:getSampleRate() / options.hop / view.step), math.floor(cache.limit * 0.2))
    for cell = view.last + 1, math.min(view.maxCell, view.last + ahead) do enqueue(cell) end
    if #cells > 0 then
        requests:push({sound = sound, mode = options.mode, window = options.window, step = view.step,
            generation = generation, token = scheduleToken, cells = cells})
    end
    return true
end

-- 无后台线程时逐个 STFT 帧推进，缩小视图的大任务也能在帧间继续，避免整段阻塞。
local function buildFallback(sound, options)
    if not view.first then return end
    fallback = fallback or Analyzer.new(options.mode, options.window)
    local deadline = clock() + BUILD_BUDGET
    for cell = view.first, view.last do
        local key = cacheKey(view.step, cell)
        if not cache.values[key] then
            if not partial or partial.key ~= key then
                partial = {key = key, sub = 0, values = Analyzer.array(fallback.bins), scratch = Analyzer.array(fallback.bins)}
            end
            repeat
                local frame = cell * view.step + partial.sub
                if partial.sub == 0 then
                    fallback:analyze(sound, frame, partial.values)
                else
                    fallback:analyze(sound, frame, partial.scratch)
                    for bin = 0, fallback.bins - 1 do
                        partial.values[bin] = math.max(partial.values[bin], partial.scratch[bin])
                    end
                end
                partial.sub = partial.sub + 1
                stats.analyzedFrames = stats.analyzedFrames + 1
                local frameCount = math.min(view.step, math.floor((sound:getSampleCount() - 1) / options.hop) - cell * view.step + 1)
                if partial.sub == frameCount then cachePut(key, {values = partial.values}); partial = nil end
                if clock() >= deadline then return end
            until not partial
        end
    end
end

-- 连续增加明度的黑紫红橙黄，不使用会造成假边界的彩虹色，也不逐行自动提亮。
local stops = {
    {0, 0, 0, 0}, {0.15, 0.07, 0.02, 0.20}, {0.3, 0.31, 0.06, 0.42},
    {0.5, 0.67, 0.16, 0.39}, {0.7, 0.94, 0.38, 0.16}, {0.85, 0.99, 0.67, 0.14}, {1, 1, 0.99, 0.75},
}
local palette = {}
for index = 0, 255 do
    local level, left = index / 255, 1
    while left < #stops - 1 and level > stops[left + 1][1] do left = left + 1 end
    local a, b, color = stops[left], stops[left + 1], {}
    local weight = (level - a[1]) / (b[1] - a[1])
    for channel = 1, 3 do color[channel] = a[channel + 1] * (1 - weight) + b[channel + 1] * weight end
    palette[index] = color
end

local function initRenderer()
    if renderer then return end
    renderer = {format = 'rgba8'}
    local ok, shader = pcall(function()
        return love.graphics.newShader(assert(love.filesystem.read('src/shader/spectrogram.glsl')))
    end)
    if not ok then renderer.error = tostring(shader); return end
    renderer.shader = shader
    local data = love.image.newImageData(256, 1)
    for i = 0, 255 do data:setPixel(i, 0, palette[i][1], palette[i][2], palette[i][3], 1) end
    renderer.palette = love.graphics.newImage(data, {linear = true})
    renderer.palette:setFilter('linear', 'linear')
    shader:send('palette', renderer.palette)
    local supported = pcall(function()
        local probe = love.graphics.newImage(love.image.newImageData(1, 1, 'r32f'), {linear = true})
        probe:release()
    end)
    if supported then renderer.format = 'r32f' end
end

local function rebuildTiles(rows, columns)
    for _, tile in ipairs(view.tiles) do
        if tile.image.release then tile.image:release() end
        if tile.data.release then tile.data:release() end
    end
    view.tiles, view.rows, view.columns, view.key = {}, rows, columns, nil
    for first = 0, rows - 1, TILE_ROWS do
        local data = love.image.newImageData(columns, math.min(TILE_ROWS, rows - first), renderer.format)
        local image = love.graphics.newImage(data, {linear = true})
        image:setFilter('nearest', 'nearest')
        local tile = {first = first, data = data, image = image}
        if hasFFI and data.getPointer then
            tile.pixels = ffi.cast(renderer.format == 'r32f' and 'float*' or 'uint8_t*', data:getPointer())
        end
        view.tiles[#view.tiles + 1] = tile
    end
end

local function signature(y0, y1)
    local parts = {beat.nowbeat, denom.scale, settings.judge_line_y, ChartService:getOffset(), y0, y1}
    for i = 1, ChartService:getBpmCount() do
        local b = ChartService:getBpm(i)
        parts[#parts + 1] = table.concat({b.bpm, b.linear_ramp or 0, b.beat[1], b.beat[2], b.beat[3]}, ',')
    end
    return table.concat(parts, '|')
end

local function prepareRows(sound, options, y0, y1)
    local rate, count, rows = sound:getSampleRate(), sound:getSampleCount(), view.rows
    local offset, seconds = ChartService:getOffset() / 1000, {}
    for row = 0, rows do
        seconds[row] = ChartService:toTime(CoordinateService:yToBeat(y0 + row * (y1 - y0) / rows)) - offset
        if seconds[row] ~= seconds[row] or math.abs(seconds[row]) == math.huge then
            view.step, view.rowCells, view.painted, view.first, view.last = 1, {}, {}, nil, nil
            return
        end
    end
    local frames = math.abs(seconds[rows] - seconds[0]) * rate / options.hop
    -- 显示格不多于物理像素；低音模式的大频谱也保持在缓存预算内。
    local target = math.min(rows, math.floor(cache.limit * 0.55))
    local step = 1
    while step < frames / target do step = step * 2 end
    view.step, view.rowCells, view.painted, view.first, view.last = step, {}, {}, nil, nil
    view.maxCell = math.floor(math.floor((count - 1) / options.hop) / step)
    for row = 0, rows - 1 do
        local low, high = math.min(seconds[row], seconds[row + 1]), math.max(seconds[row], seconds[row + 1])
        if high > 0 and low < count / rate then
            local a = clamp(Config.cellAt(math.max(0, low), rate, options.hop, step), 0, view.maxCell)
            local b = clamp(Config.cellAt(math.min(count / rate, high) - 1e-10, rate, options.hop, step), a, view.maxCell)
            view.rowCells[row] = {a, b}
            view.first, view.last = math.min(view.first or a, a), math.max(view.last or b, b)
        end
    end
end

local function prepareAxis(options, rate)
    local key = table.concat({options.minHz, options.maxHz, options.scale, options.size, rate, view.columns}, '|')
    if view.axis == key then return end
    view.axis, view.bands, view.key = key, {}, nil
    local maxBin = options.size / 2
    for column = 0, view.columns - 1 do
        local low = Config.frequency(options, column / view.columns) * options.size / rate
        local high = Config.frequency(options, (column + 1) / view.columns) * options.size / rate
        local center = Config.frequency(options, (column + 0.5) / view.columns) * options.size / rate
        local left = clamp(math.floor(center), 0, maxBin)
        view.bands[column] = {first = clamp(math.ceil(low), 0, maxBin), last = clamp(math.floor(high), 0, maxBin),
            left = left, right = math.min(left + 1, maxBin), fraction = center - left}
    end
end

local function project(entry)
    if entry.axis == view.axis then return entry.projected end
    local values, projected = entry.values, Analyzer.array(view.columns)
    for column = 0, view.columns - 1 do
        local b = view.bands[column]
        local peak = values[b.left] * (1 - b.fraction) + values[b.right] * b.fraction
        for bin = b.first, b.last do peak = math.max(peak, values[bin]) end
        projected[column] = peak
    end
    entry.axis, entry.projected = view.axis, projected
    stats.projectedFrames = stats.projectedFrames + 1
    return projected
end

local function writePixel(tile, offset, column, row, power, options)
    if renderer.format == 'r32f' then
        if tile.pixels then tile.pixels[offset] = power else tile.data:setPixel(column, row, power, 0, 0, 1) end
    elseif renderer.shader then
        -- 不支持浮点纹理时用两个通道保存 -256..24 dB，精度约 0.0043 dB；仍在 GPU 调色。
        local db = 10 * math.log(math.max(power, 1e-30)) / LOG_10
        local code = math.floor(clamp((db + 256) / 280, 0, 1) * 65535 + 0.5)
        local high, low = math.floor(code / 256), code % 256
        if tile.pixels then
            tile.pixels[offset * 4], tile.pixels[offset * 4 + 1] = high, low
            tile.pixels[offset * 4 + 2], tile.pixels[offset * 4 + 3] = 0, 255
        else tile.data:setPixel(column, row, high / 255, low / 255, 0, 1) end
    else
        local db = 10 * math.log(math.max(power, 1e-30)) / LOG_10
        local level = clamp((db + options.gain - options.floor) / (options.ceiling - options.floor), 0, 1)
        local color, fade = palette[math.floor(level * 255 + 0.5)], clamp(level / 0.06, 0, 1)
        tile.data:setPixel(column, row, color[1], color[2], color[3], options.opacity * fade * fade * (3 - 2 * fade))
    end
end

local function paintRows(options, changed)
    local pending, lookup = 0, {}
    if view.first then
        for cell = view.first, view.last do
            local entry = cache.values[cacheKey(view.step, cell)]
            if entry then lookup[cell] = project(entry) end
        end
    end
    for row = 0, view.rows - 1 do
        local cells, complete = view.rowCells[row], true
        local rowValues = {}
        if cells then
            for cell = cells[1], cells[2] do
                if lookup[cell] then rowValues[#rowValues + 1] = lookup[cell] else complete = false end
            end
        end
        if not complete then pending = pending + 1 end
        if changed or not view.painted[row] then
            local tile = view.tiles[math.floor(row / TILE_ROWS) + 1]
            local localRow = row - tile.first
            for column = 0, view.columns - 1 do
                local peak = 0
                for _, values in ipairs(rowValues) do peak = math.max(peak, values[column]) end
                writePixel(tile, localRow * view.columns + column, column, localRow, peak, options)
            end
            tile.dirty, view.painted[row] = true, complete
        end
    end
    -- 一起提交所有变动图块；移动视野时不能每帧从第一块重新限额，导致底部一直空白。
    for _, tile in ipairs(view.tiles) do
        if tile.dirty then
            tile.image:replacePixels(tile.data)
            tile.dirty, tile.ready = false, true
            stats.uploads = stats.uploads + 1
        end
    end
    view.pending = pending
end

function Spectrogram:draw(sound, x, width, y0, y1)
    if not sound or y1 <= y0 or width <= 0 or sound:getSampleCount() == 0 then return end
    local options = Config.read(settings, sound:getSampleRate())
    if sound ~= currentSound or analysisKey ~= options.mode .. '|' .. options.window then reset(sound, options) end
    initRenderer()
    local scale = clamp(WINDOW and WINDOW.scale or 1, 1, 2)
    local rows, columns = math.ceil((y1 - y0) * scale), math.ceil(width * scale)
    if view.rows ~= rows or view.columns ~= columns then rebuildTiles(rows, columns) end
    prepareAxis(options, sound:getSampleRate())
    receiveResults(options)
    local key = signature(y0, y1)
    if not renderer.shader then key = key .. table.concat({options.floor, options.ceiling, options.gain, options.opacity}, '|') end
    local changed = view.key ~= key
    if changed or (view.pending > 0 and (elapsed_time == nil or view.frame ~= elapsed_time)) then
        if changed then prepareRows(sound, options, y0, y1) end
        if not buildInBackground(sound, options) then buildFallback(sound, options) end
        paintRows(options, changed)
        view.key, view.frame = key, elapsed_time
    end
    local previousShader = love.graphics.getShader()
    if renderer.shader then
        renderer.shader:send('floorDB', options.floor)
        renderer.shader:send('ceilingDB', options.ceiling)
        renderer.shader:send('gainDB', options.gain)
        renderer.shader:send('opacity', options.opacity)
        renderer.shader:send('packedDB', renderer.format ~= 'r32f')
        love.graphics.setShader(renderer.shader)
    end
    love.graphics.setColor(1, 1, 1)
    local height = (y1 - y0) / rows
    for _, tile in ipairs(view.tiles) do
        if tile.ready then love.graphics.draw(tile.image, x, y0 + tile.first * height, 0, width / columns, height) end
    end
    love.graphics.setShader(previousShader)
end

function Spectrogram:getStatus()
    return {pendingRows = view.pending, rows = view.rows or 0, cacheEntries = cache.count,
        analyzedFrames = stats.analyzedFrames, projectedFrames = stats.projectedFrames, uploads = stats.uploads,
        cacheLimit = cache.limit or 0, renderer = renderer and (renderer.shader and renderer.format or 'cpu'),
        workerError = workerFailed, shaderError = renderer and renderer.error, timeStep = view.step or 1}
end

return Spectrogram
