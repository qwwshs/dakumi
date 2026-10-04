--[[
    模块名: AudioService
    描述: 持有音频资源与播放时钟，统一加载、定位、变速、音量及后台解码。
    依赖: 启动入口注入的音频后端、谱面时间接口和事件总栈。
    所有时间接口使用秒；谱面 offset 由谱面接口提供（毫秒）。
]]
local Service = {}
Service.__index = Service
local private = setmetatable({}, {__mode = 'k'})
local DRIFT_LIMIT = 0.05 -- 音频与谱面时钟相差 50ms 时补正。
local function finite(value)
    return type(value) == 'number' and value == value and value ~= math.huge and value ~= -math.huge
end
local function emit(self, name, payload)
    local s = private[self]
    if s.events then s.events:emit(name, payload) end
end
local function offset(self)
    local chart = private[self].chart
    return chart and chart:getOffset() / 1000 or 0
end
local function dispose(source)
    if not source then return end
    source:stop()
    if source.release then source:release() end
end
local function failure(self, err, path)
    local s = private[self]
    s.error = tostring(err)
    if s.report then s.report('Audio: ' .. s.error) end
    emit(self, 'audio:error', {path = path or s.path, error = s.error})
    return false, s.error
end
local function align(self)
    local s = private[self]
    if not s.source then return end
    local audioTime = self:getCurrentTime() - offset(self)
    s.source:seek(math.max(0, math.min(s.duration, audioTime)), 'seconds')
    if s.playing and audioTime >= 0 and audioTime < s.duration then
        s.source:play()
        s.audible = true
    else
        s.source:pause()
        s.audible = false
    end
    s.lastOffset = offset(self)
end
function Service.new(options)
    local self = setmetatable({}, Service)
    private[self] = {position = 0, duration = 0, playing = false, audible = false,
        rate = 1, volume = 1, revision = 0, effects = {}}
    if options then self:init(options) end
    return self
end
-- 构造/初始化均不读取应用全局，测试可注入内存后端。
function Service:init(options)
    assert(options.chart and options.backend, 'audio service requires chart and backend')
    local s = private[self]
    for _, unsubscribe in ipairs(s.subscriptions or {}) do unsubscribe() end
    s.subscriptions = {}
    s.beatPosition, s.totalDuration = nil, nil
    s.chart, s.backend, s.events, s.report = options.chart, options.backend, options.events, options.report
    if s.events then
        local function invalidate()
            s.beatPosition, s.totalDuration = nil, nil
        end
        s.subscriptions = {
            s.events:on('chart:replaced', function() invalidate(); self:stop() end),
            s.events:on('chart:mutated', invalidate),
            s.events:on('chart:changed', invalidate),
        }
    end
    return self
end
function Service:getSource() return private[self].source end -- 兼容接口；播放控制请调用服务。
function Service:getSoundData() return private[self].data end -- 分析/绘制只读使用。
function Service:getPath() return private[self].path end
function Service:getRate() return private[self].rate end
function Service:getVolume() return private[self].volume end
function Service:getRevision() return private[self].revision end
function Service:getLoadError() return private[self].error end
function Service:isLoading() return private[self].decode ~= nil end
function Service:isPlaying() return private[self].playing end
function Service:getRawDuration() return private[self].duration end
function Service:getDuration()
    local s = private[self]
    return s.source and s.duration > 0 and math.max(0, s.duration + offset(self)) or 0
end
function Service:getCurrentTime() return private[self].position end
function Service:getAudioTime()
    local s = private[self]
    return math.max(0, math.min(s.duration, s.position - offset(self)))
end
function Service:getCurrentBeat()
    local s = private[self]
    -- 同一播放位置的绘制复用换算结果；谱面变更通知会清掉缓存。
    if not s.events or s.beatPosition ~= s.position then
        s.currentBeat = s.chart and s.chart:getBpmCount() > 0 and s.chart:toBeat(s.position) or 0
        s.beatPosition = s.position
    end
    return s.currentBeat
end
function Service:getAllBeat()
    local s = private[self]
    local duration = self:getDuration()
    if not s.events or s.totalDuration ~= duration then
        s.totalBeat = s.chart and s.chart:getBpmCount() > 0 and s.chart:toBeat(duration) or 0
        s.totalDuration = duration
    end
    return s.totalBeat
end
function Service:setSoundData(data)
    local s = private[self]
    s.data, s.decode, s.error = data, nil, nil
    s.revision = s.revision + 1
    emit(self, 'audio:decoded', {path = s.path, revision = s.revision})
end
-- 接管外部构造的源（例如内存音频）；时长从资源读取，不允许另写一份总时长。
function Service:setSource(source, path, preview)
    local s = private[self]
    if source and source == s.source then return true end
    local duration = source and source:getDuration('seconds') or 0
    self:pause()
    if s.source then dispose(s.source) end
    s.source, s.duration, s.position = source, duration, 0
    s.data, s.path, s.decode, s.error = nil, path, nil, nil
    s.playing, s.audible, s.preview = false, false, preview == true
    s.revision = s.revision + 1
    if source then
        source:setPitch(s.rate)
        source:setVolume(s.volume)
        source:setLooping(s.preview)
        for name in pairs(s.effects) do source:setEffect(name, true) end
        align(self)
    end
    emit(self, 'audio:loaded', {path = s.path, revision = s.revision})
    return true
end
-- 新资源构造成功才替换旧资源；失败返回错误，保留原歌曲。
function Service:load(path, options)
    local s = private[self]
    options = options or {}
    if type(path) ~= 'string' or path == '' then return failure(self, 'empty audio path', path) end
    local ok, source = pcall(s.backend.newSource, path, 'stream')
    if not ok then return failure(self, source, path) end
    self:setSource(source, path, options.preview)
    if options.decode ~= false then self:requestSoundData() end
    if s.preview then
        self:setRate(1)
        -- 菜单从原音频第 0 秒试听，负 offset 可以对应负的谱面时间。
        s.position = offset(self)
        self:resume()
    end
    return true
end
function Service:unload() return self:setSource(nil) end
-- 每次解码独占通道。换歌后旧线程的结果不会混进新歌曲。
function Service:requestSoundData()
    local s = private[self]
    if s.data or s.decode then return true end
    if not s.path then return false, 'no audio path' end
    local job = {path = s.path, revision = s.revision}
    local ok, err = pcall(function()
        job.input = s.backend.readAudio and s.backend.readAudio(job.path) or job.path
        job.output = s.backend.newChannel()
        job.thread = s.backend.newThread('src/thread/audioThread.lua')
        job.thread:start(job.input, job.output)
    end)
    if not ok then return failure(self, err) end
    s.decode = job
    return true
end
function Service:pollDecode()
    local s, job = private[self], private[self].decode
    if not job then return end
    local message = job.output:pop()
    if not message and job.thread:isRunning() then return end
    s.decode = nil
    if job.path ~= s.path or job.revision ~= s.revision then return end
    if message and message.data then self:setSoundData(message.data)
    else failure(self, message and message.error or job.thread:getError() or 'audio decoding failed') end
end
-- 进入编辑器前保证分析数据可用；已在后台解码的歌曲直接复用。
function Service:prepareEditor()
    local s = private[self]
    if not s.source then return false, 'no audio source' end
    self:pause()
    s.preview = false
    s.source:setLooping(false)
    if not s.data then
        if not s.path then return false, 'no audio data' end
        local ok, data = pcall(function()
            local input = s.backend.readAudio and s.backend.readAudio(s.path) or s.path
            return s.backend.newSoundData(input)
        end)
        if not ok then return failure(self, data) end
        self:setSoundData(data)
    end
    self:seek(0)
    return true
end
function Service:seek(seconds, options)
    if not finite(seconds) then return false, 'invalid time' end
    local s = private[self]
    if options and options.pause then self:pause() end
    s.position = math.max(0, math.min(self:getDuration(), seconds))
    align(self)
    return true
end
function Service:setCurrentTime(seconds) return self:seek(seconds) end
function Service:setCurrentBeat(value, options)
    local s = private[self]
    if not s.chart or s.chart:getBpmCount() == 0 then return false, 'no BPM' end
    return self:seek(s.chart:toTime(value), options)
end
function Service:pause()
    local s = private[self]
    local changed = s.playing
    s.playing, s.audible = false, false
    if s.source then s.source:pause() end
    if changed then emit(self, 'audio:playing_changed', {playing = false}) end
end
function Service:resume()
    local s = private[self]
    if not s.source or s.duration <= 0 or (not s.preview and self:getDuration() <= 0) then return false end
    local ending = s.preview and s.duration + offset(self) or self:getDuration()
    if s.position >= ending then s.position = s.preview and offset(self) or 0 end
    local changed = not s.playing
    s.playing = true
    align(self)
    if changed then emit(self, 'audio:playing_changed', {playing = true}) end
    return true
end
function Service:setPlaying(playing)
    if playing then return self:resume() end
    self:pause()
    return true
end
function Service:toggle() return self:setPlaying(not self:isPlaying()) end
function Service:stop()
    self:pause()
    local s = private[self]
    s.position = 0
    if s.source then s.source:stop() end
end
function Service:setRate(rate)
    if not finite(rate) or rate <= 0 then return false, 'invalid playback rate' end
    local s = private[self]
    if rate ~= s.rate then
        s.rate = rate
        if s.source then s.source:setPitch(rate) end
    end
    return true
end
function Service:setVolume(volume)
    if not finite(volume) then return false, 'invalid volume' end
    local s = private[self]
    volume = math.max(0, math.min(1, volume))
    if volume ~= s.volume then
        s.volume = volume
        if s.source then s.source:setVolume(volume) end
    end
    return true
end
function Service:setEffect(name, parameters)
    local s = private[self]
    local enabled = parameters ~= false
    local ok, err = pcall(function()
        if enabled and s.backend.setEffect(name, parameters) == false then error('audio effect is unavailable') end
        if s.source and s.source:setEffect(name, enabled) == false then error('source effect is unavailable') end
    end)
    if not ok then return failure(self, err) end
    s.effects[name] = enabled or nil
    return true
end
-- 单一更新入口。暂停时不反复 seek/play；谱面时间可早于音频起点（正 offset）。
function Service:update(dt)
    local s = private[self]
    self:pollDecode()
    if not s.source then return end
    if s.lastOffset ~= offset(self) then
        if s.preview then
            s.position = s.position + offset(self) - s.lastOffset
        else
            s.position = math.min(s.position, self:getDuration())
        end
        align(self)
    end
    if not s.playing then return end
    s.position = s.position + math.max(0, dt) * s.rate
    local ending = s.preview and s.duration + offset(self) or self:getDuration()
    if s.position >= ending then
        if s.preview then
            s.position = offset(self) + (s.position - offset(self)) % s.duration
            align(self)
        else
            s.position = self:getDuration()
            self:pause()
            align(self)
        end
        return
    end
    local audioTime = s.position - offset(self)
    if audioTime < 0 then return end
    if not s.audible then align(self)
    elseif math.abs(s.source:tell('seconds') - audioTime) >= DRIFT_LIMIT then align(self) end
end
return Service.new()
