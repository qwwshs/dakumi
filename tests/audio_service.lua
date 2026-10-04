-- 私有音频状态与播放生命周期回归：只用内存后端，不依赖 LÖVE 或应用全局。
local Audio = require('src.services.audioService')
local offsetMs, bpm = 1000, 120
local chart = {
    getOffset = function() return offsetMs end, getBpmCount = function() return 1 end,
    toBeat = function(_, seconds) return seconds * bpm / 60 end,
    toTime = function(_, value) return value * 60 / bpm end,
}
local function near(a, b) assert(math.abs(a - b) < 1e-8, tostring(a) .. ' ~= ' .. tostring(b)) end
local function source(duration)
    return {
        duration = duration, position = 0, seekCount = 0,
        getDuration = function(self) return self.duration end,
        setPitch = function(self, value) self.pitch = value end,
        setVolume = function(self, value) self.volume = value end,
        setLooping = function(self, value) self.looping = value end,
        setEffect = function(self, name, enabled) self.effect = enabled and name or nil end,
        seek = function(self, value) self.position = value; self.seekCount = self.seekCount + 1 end,
        tell = function(self) return self.position end,
        play = function(self) self.playing = true end,
        pause = function(self) self.playing = false end,
        stop = function(self) self.playing = false; self.position = 0; self.stopped = true end,
        release = function(self) self.released = true end,
    }
end
local jobs, made = {}, {}
local backend = {
    newSource = function(path)
        if path == 'bad' then error('decode failed') end
        local new = source(5); made[#made + 1] = new; return new
    end,
    newSoundData = function(path) return {path = path, sync = true} end,
    newChannel = function()
        return {pop = function(self) local value = self.message; self.message = nil; return value end}
    end,
    newThread = function()
        local job = {running = true}
        function job:start(path, output) self.path, self.output = path, output end
        function job:isRunning() return self.running end
        function job:getError() return 'worker failed' end
        jobs[#jobs + 1] = job
        return job
    end,
    setEffect = function() return true end,
}
local service = Audio.new({chart = chart, backend = backend})
local other = Audio.new({chart = chart, backend = backend})
local first = source(5)
service:setSource(first)
service:setSoundData({name = 'first'})
assert(not other:getSource() and not other:getSoundData(), 'instances share audio state')
assert(not music and not music_data and not music_play and not time and not beat, 'created application globals')
near(service:getDuration(), 6)
assert(service:resume() and service:isPlaying() and not first.playing, 'positive offset must delay the source')
service:update(0.5); near(service:getCurrentTime(), 0.5); assert(not first.playing)
service:update(0.6); near(service:getCurrentTime(), 1.1); near(first.position, 0.1); assert(first.playing)
service:pause(); assert(not first.playing and not service:isPlaying(), 'pause is only a flag')
local seeks = first.seekCount
service:update(0.5); near(service:getCurrentTime(), 1.1)
assert(first.seekCount == seeks, 'paused frames repeatedly seek')
service:seek(2); near(first.position, 1); near(service:getCurrentBeat(), 4)
bpm = 180; near(service:getCurrentBeat(), 6); near(service:getAllBeat(), 18)
assert(service:setRate(2)); service:resume(); service:update(0.5)
near(service:getCurrentTime(), 3); near(first.position, 2); near(first.pitch, 2)
service:setVolume(2); near(first.volume, 1)
assert(not service:setRate(0) and not service:seek(0/0)); near(service:getCurrentTime(), 3)
service:stop(); near(service:getCurrentTime(), 0); assert(first.stopped and not service:isPlaying())
service:seek(99); near(service:getCurrentTime(), 6)
service:resume(); service:update(4); near(service:getCurrentTime(), 6); assert(not service:isPlaying())
offsetMs = -500
near(service:getDuration(), 4.5)
service:seek(0); near(first.position, 0.5)
assert(service:setEffect('equalizer', {type = 'equalizer'}))
local second = source(5)
service:setSource(second)
assert(first.stopped and first.released and not service:getSoundData(), 'replacement retained old resource')
assert(second.effect == 'equalizer', 'effect lost on replacement')
assert(not service:load('bad') and service:getSource() == second, 'failed load destroyed current resource')
assert(service:load('A')); local oldJob = jobs[#jobs]
assert(service:load('B')); local currentJob = jobs[#jobs]
oldJob.output.message, oldJob.running = {data = {path = 'A'}}, false
service:update(0); assert(not service:getSoundData(), 'late previous-song decode was accepted')
currentJob.output.message, currentJob.running = {data = {path = 'B'}}, false
service:update(0); assert(service:getSoundData().path == 'B' and not service:isLoading())
assert(service:load('C')); local pending = jobs[#jobs]
assert(service:prepareEditor()); assert(service:getSoundData().sync and not service:isLoading())
pending.output.message, pending.running = {data = {path = 'wrong'}}, false
service:update(0); assert(service:getSoundData().path == 'C', 'late decode overwrote synchronous editor data')
assert(service:load('D')); jobs[#jobs].running = false
service:update(0); assert(service:getLoadError() == 'worker failed' and not service:isLoading())
assert(service:load('preview', {preview = true, decode = false}))
service:update(20); assert(service:isPlaying() and service:getCurrentTime() < service:getDuration())
assert(service:setEffect('equalizer', false)); assert(not service:getSource().effect)
service:unload(); assert(not service:getSource() and not service:getSoundData() and not service:isPlaying())
service:setSoundData({temporary = true}); service:unload(); assert(not service:getSoundData())
near(service:getDuration(), 0); near(service:getAllBeat(), 0)
print('PASS: private audio state, native pause/seek, offset, rate, BPM derivation, end, resource replacement, async isolation and effects')
