-- 运行：love tests/spectrogram_love。输出 .zcode/spectrogram_love.txt/.png；不访问用户数据。
local root = love.filesystem.getSource():gsub('\\', '/'):gsub('/tests/spectrogram_love/?$', '')
package.path = root .. '/?.lua;' .. package.path
local function save(name, data)
    local f = assert(io.open(root .. '/.zcode/' .. name, 'wb'))
    f:write(data); f:close()
end
local originalRead = love.filesystem.read
love.filesystem.read = function(path, ...)
    if path == 'src/shader/spectrogram.glsl' then
        local f = assert(io.open(root .. '/' .. path, 'rb'))
        local data = f:read('*a'); f:close(); return data
    end
    return originalRead(path, ...)
end
local currentBeat = (1 - 0.163) * 163 / 60
package.loaded['src.services.audioService'] = {getCurrentBeat = function() return currentBeat end}
local Spec = require('src.services.spectrogramService')
local Config = require('src.services.spectrogramConfig')
local Analyzer = require('src.services.spectrogramAnalyzer')
local Chart = require('src.services.chartService')
Chart.toTime = function(_, b) return b * 60 / 163 end
Chart.getOffset = function() return -163 end
Chart.getBpmCount = function() return 0 end
denom = {scale = 5}
settings = {judge_line_y = 680}
WINDOW = {scale = 1.4}
elapsed_time = 0
local frame, tone, silence, pulse, canvas, firstComplete, started = 0
local minimum, costs, maximum, draws = 896, 0, 0, 0
local snapshot, freeze
local function pixels()
    return canvas:newImageData()
end
local function covered(data, x)
    local count = 0
    for y = 56, 951 do
        local _, _, _, alpha = data:getPixel(x, y)
        if alpha > 0.1 then count = count + 1 end
    end
    return count
end
function love.load(args)
    save('spectrogram_love.txt', 'RUNNING')
    if args[1] == 'packed' then
        local newImage = love.graphics.newImage
        love.graphics.newImage = function(data, ...)
            if data:getFormat() == 'r32f' then error('test: float texture unavailable') end
            return newImage(data, ...)
        end
    end
    -- FFI 的 8/16 位和单/双声道读取必须与 LÖVE 接口一致。
    local analyzer = Analyzer.new('harmonics', 'hann')
    for _, bits in ipairs({8,16}) do for _, channels in ipairs({1,2}) do
        local sd = love.sound.newSoundData(8192, 44100, bits, channels)
        for i = 0, 8191 do for c = 1, channels do sd:setSample(i,c,0.2 * math.sin(2 * math.pi * 440 * i / 44100)) end end
        local proxy = {}
        for _, name in ipairs({'getSampleCount','getChannelCount','getSample'}) do
            proxy[name] = function(_, ...) return sd[name](sd, ...) end
        end
        local a, b = analyzer:analyze(sd, 32), analyzer:analyze(proxy, 32)
        for bin = 0, analyzer.bins - 1 do
            assert(math.abs(a[bin] - b[bin]) < 1e-8,
                string.format('PCM pointer mismatch: bits=%d channels=%d bin=%d actual=%g expected=%g', bits, channels, bin, a[bin], b[bin]))
        end
    end end
    tone = love.sound.newSoundData(12 * 44100, 44100, 16, 2)
    silence = love.sound.newSoundData(12 * 44100, 44100, 16, 2)
    pulse = love.sound.newSoundData(12 * 44100, 44100, 16, 1)
    for i = 0, tone:getSampleCount() - 1 do
        local t = i / 44100
        local v = 0.1 * math.sin(2 * math.pi * 1000 * t) + 0.04 * math.sin(2 * math.pi * 1040 * t)
        tone:setSample(i, 1, v); tone:setSample(i, 2, -v)
        if t >= 6 and t < 6.003 then pulse:setSample(i, 0.2 * math.sin(2 * math.pi * 1000 * t)) end
    end
    canvas = love.graphics.newCanvas(940,990)
    started = love.timer.getTime()
end
function love.update() frame = frame + 1; elapsed_time = frame / 60 end
function love.draw()
    local sound = frame >= 350 and frame <= 400 and silence or tone
    if frame >= 461 then sound = pulse end
    if frame >= 61 and frame <= 300 then
        local t = frame <= 180 and 1 + (frame - 60)/60 or 3 + (frame - 180)/60 * 2
        currentBeat = (t - 0.163) * 163 / 60
    elseif frame == 301 then
        currentBeat = (1 - 0.163) * 163 / 60
    elseif frame == 330 then
        settings.spectrogram_floor_db, settings.spectrogram_gain_db = -120, 12
    elseif frame == 331 then
        settings.spectrogram_min_hz, settings.spectrogram_max_hz = 980, 1060
    elseif frame >= 350 and frame <= 358 then
        currentBeat = (frame % 7) * 163 / 60
    elseif frame == 389 then
        settings.spectrogram_floor_db, settings.spectrogram_gain_db = -180, 48
    elseif frame == 401 then
        settings.spectrogram_floor_db, settings.spectrogram_gain_db = -84, 0
    elseif frame == 461 then
        settings.spectrogram_mode, settings.spectrogram_min_hz, settings.spectrogram_max_hz = 'transient', 40, 12000
        currentBeat, denom.scale = -0.163 * 163 / 60, 0.025
    end
    love.graphics.setCanvas(canvas); love.graphics.clear(0,0,0,0)
    love.graphics.push(); love.graphics.scale(1.4)
    local begin = love.timer.getTime()
    Spec:draw(sound,20,300,40,680)
    local status = Spec:getStatus()
    local count = status.uploads
    Spec:draw(sound,340,300,40,680)
    assert(Spec:getStatus().uploads == count, 'second tab uploaded the same view again')
    local duration = love.timer.getTime() - begin
    if frame > 60 and frame <= 300 then
        costs, maximum, draws = costs + duration, math.max(maximum, duration), draws + 1
    end
    love.graphics.pop(); love.graphics.setCanvas()
    assert(not status.workerError, status.workerError)
    assert(not status.shaderError, status.shaderError)
    assert(status.renderer == 'r32f' or status.renderer == 'rgba8', 'GPU color path required')
    if not firstComplete and status.pendingRows == 0 then firstComplete = love.timer.getTime() - started end
    if frame % 6 == 0 and frame <= 300 then
        local o = Config.read(settings,44100)
        local px = math.floor((20 + 300 * Config.position(o,1000)) * 1.4)
        local lit = covered(pixels(),px)
        if frame >= 90 then minimum = math.min(minimum,lit); assert(status.pendingRows == 0, 'playback has unfinished rows') end
    end
    if frame == 329 then freeze = status end
    if frame == 330 then
        assert(status.uploads == freeze.uploads and status.projectedFrames == freeze.projectedFrames,
            'display gain must not rebuild numeric textures')
        assert(status.analyzedFrames == freeze.analyzedFrames, 'gain must not trigger FFT')
    end
    if frame == 331 then
        assert(status.projectedFrames > freeze.projectedFrames, 'frequency zoom must use raw spectrum')
        assert(status.analyzedFrames == freeze.analyzedFrames, 'frequency zoom must not trigger FFT')
    end
    if frame == 340 then save('spectrogram_love.png',pixels():encode('png'):getString()) end
    if frame == 390 then
        assert(status.pendingRows == 0, 'replacement audio did not finish')
        assert(covered(pixels(),140) == 0, 'stale sound data leaked into silence')
    end
    if frame == 400 then love.timer.sleep(2.2) end
    if frame == 460 then
        assert(status.pendingRows == 0, 'idle worker failed to restart')
        local px = math.floor((20 + 300 * Config.position(Config.read(settings,44100),1000)) * 1.4)
        assert(covered(pixels(),px) == 896, 'idle restart has holes')
        assert(minimum == 896, 'continuous playback lost rows')
        assert(status.cacheEntries <= status.cacheLimit)
    end
    if frame == 560 then
        assert(status.pendingRows == 0 and status.timeStep > 1, 'time overview did not complete')
        local px = math.floor((20 + 300 * Config.position(Config.read(settings,44100),1000)) * 1.4)
        assert(covered(pixels(),px) > 0, 'time downsampling skipped a 3 ms pulse')
        save('spectrogram_love.txt',string.format(
            'PASS: PCM parity; float shader; 896/896 rows at 1x/2x; shared tabs; gain/frequency zoom without FFT; rapid seek; audio replacement; idle restart.\nfirst_complete_ms=%.2f average_playback_draw_ms=%.3f max_playback_draw_ms=%.3f renderer=%s\n',
            firstComplete * 1000,costs/draws*1000,maximum*1000,status.renderer))
        love.event.quit()
    end
    love.timer.sleep(1/120)
end
function love.errorhandler(message)
    save('spectrogram_love.txt','FAIL: '..tostring(message)..'\n'..debug.traceback())
    os.exit(1)
end
