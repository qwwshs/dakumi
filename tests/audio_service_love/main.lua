-- 真实 LÖVE Source/解码线程回归；只在测试目录临时写合成 WAV。
local root = love.filesystem.getSource():gsub('\\', '/'):gsub('/tests/audio_service_love/?$', '')
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
local Audio = require('src.services.audioService')
local bus = require('src.utils.eventBus')
local offsetMs, bpm = 200, 120
local chart = {
    getOffset = function() return offsetMs end, getBpmCount = function() return 1 end,
    toBeat = function(_, value) return value * bpm / 60 end,
    toTime = function(_, value) return value * 60 / bpm end,
}
local newThread = love.thread.newThread
local service = Audio.new({chart = chart, events = bus, backend = {
    newSource = love.audio.newSource, newSoundData = love.sound.newSoundData,
    newChannel = love.thread.newChannel, setEffect = love.audio.setEffect,
    readAudio = function(path)
        return love.filesystem.newFileData(path)
    end,
    newThread = function(path)
        local f = assert(io.open(root .. '/' .. path, 'rb'))
        local code = f:read('*a'); f:close()
        -- 模拟线程无法再读取原目录：解码输入必须已经是文件快照。
        code = "require('love.sound')\nlocal decode = love.sound.newSoundData\n" ..
            "love.sound.newSoundData = function(input) assert(type(input)=='userdata', 'worker needs file snapshot'); return decode(input) end\n" .. code
        return newThread(love.filesystem.newFileData(code, 'audioThread.lua'))
    end,
}})
local function little(value, bytes)
    local result = {}
    for i = 1, bytes do result[i] = string.char(value % 256); value = math.floor(value / 256) end
    return table.concat(result)
end
local function wav(seconds)
    local pcm = string.rep('\0\0', seconds * 44100)
    return 'RIFF' .. little(#pcm + 36,4) .. 'WAVEfmt ' .. little(16,4) ..
        little(1,2) .. little(1,2) .. little(44100,4) .. little(88200,4) ..
        little(2,2) .. little(16,2) .. 'data' .. little(#pcm,4) .. pcm
end
local function near(a,b) assert(math.abs(a-b)<0.002, tostring(a)..' ~= '..tostring(b)) end
local function wait()
    local deadline = love.timer.getTime() + 5
    while service:isLoading() and love.timer.getTime() < deadline do
        service:update(0); love.timer.sleep(0.005)
    end
    assert(not service:isLoading() and service:getSoundData(), service:getLoadError() or 'decode timeout')
end
local function run()
    for name, seconds in pairs({['A.wav']=1, ['B.wav']=2}) do
        local f=assert(io.open(root .. '/tests/audio_service_love/' .. name, 'wb'))
        f:write(wav(seconds)); f:close()
    end
    local loadedPath
    bus:on('audio:loaded', function(event) loadedPath = event.path end)
    assert(service:load('A.wav', {preview = true}))
    assert(loadedPath == 'A.wav' and service:getSource():isPlaying())
    -- 不等待 A 线程，立即换歌；两次解码通道必须隔离。
    assert(service:load('B.wav')); wait()
    assert(loadedPath == 'B.wav'); near(service:getSoundData():getDuration(),2)
    local data = service:getSoundData()
    assert(service:prepareEditor() and service:getSoundData() == data)
    local source = service:getSource()
    assert(not source:isLooping() and not source:isPlaying())
    service:seek(0.8); near(source:tell('seconds'),0.6); near(service:getCurrentBeat(),1.6)
    service:seek(0); assert(service:resume() and not source:isPlaying())
    service:update(0.1); assert(not source:isPlaying())
    service:update(0.15); assert(source:isPlaying()); near(service:getCurrentTime(),0.25)
    service:setRate(0.5); near(source:getPitch(),0.5)
    service:update(0.2); near(service:getCurrentTime(),0.35)
    service:pause(); assert(not source:isPlaying() and not service:isPlaying())
    service:setVolume(0.3); near(source:getVolume(),0.3)
    -- 相同 BPM 条目数量下改速度，缓存也必须失效；回放通知同样有效。
    near(service:getCurrentBeat(),0.7); bpm=180; bus:emit('chart:mutated', {field='bpm_list'})
    near(service:getCurrentBeat(),1.05); near(service:getAllBeat(),6.6)
    bpm=120; bus:emit('chart:changed', {kind='undo'}); near(service:getCurrentBeat(),0.7)
    offsetMs=-500; bus:emit('chart:mutated', {field='offset'})
    near(service:getDuration(),1.5); service:seek(0); near(source:tell('seconds'),0.5)
    service:resume(); service:update(4)
    assert(not service:isPlaying() and not source:isPlaying()); near(service:getCurrentTime(),1.5)
    near(source:tell('seconds'),2)
    service:stop(); near(service:getCurrentTime(),0)
    service:load('A.wav', {preview=true}); wait()
    near(service:getCurrentTime(),offsetMs/1000); near(service:getAudioTime(),0)
    service:update(3)
    assert(service:isPlaying() and service:getCurrentTime()<service:getDuration())
    assert(service:load('B.wav', {decode=false}))
    assert(service:prepareEditor()); near(service:getSoundData():getDuration(),2)
    local before = service:getSource()
    assert(not service:load('missing.wav') and service:getSource()==before)
    bus:emit('chart:replaced'); assert(not service:isPlaying())
    service:unload(); assert(not service:getSource() and not service:getSoundData())
    assert(not music and not music_data and not music_play and not time and not beat)
    print('PASS: native audio lifecycle, stream seek, offset delay, rate/volume, derived beat caches, worker replacement, reuse, end and preview')
end
function love.load()
    local ok, err = xpcall(run, debug.traceback)
    if not ok then print(err) end
    os.remove(root .. '/tests/audio_service_love/A.wav')
    os.remove(root .. '/tests/audio_service_love/B.wav')
    love.event.quit(ok and 0 or 1)
end
function love.errorhandler(message)
    print(debug.traceback(tostring(message)))
    return function() return 1 end
end
