-- 声纹图信号与坐标回归。只使用内存中的合成音频，不读写用户设置或谱面。
local Analyzer = require('src.services.spectrogramAnalyzer')
local Config = require('src.services.spectrogramConfig')
local function sound(rate, channels, sample)
    return {
        getSampleRate = function() return rate end, getSampleCount = function() return rate * 2 end,
        getChannelCount = function() return channels or 1 end,
        getSample = function(_, i, c) assert(i >= 0 and i < rate * 2 and c >= 1); return sample(i / rate, c) end,
    }
end
local function db(power) return 10 * math.log(math.max(power, 1e-30)) / math.log(10) end
local function powerAt(values, plan, rate, frequency, radius)
    local bin = math.floor(frequency * plan.size / rate + 0.5)
    local power = values[bin]
    for i = math.max(0, bin - (radius or 0)), math.min(plan.bins - 1, bin + (radius or 0)) do
        power = math.max(power, values[i])
    end
    return power
end
local rate, plan = 48000, Analyzer.new('harmonics', 'hann')
local frame = math.floor(rate / plan.hop)
local frequency = 300 * rate / plan.size
local tone = sound(rate, 1, function(t) return 0.2 * math.sin(2 * math.pi * frequency * t) end)
local values = plan:analyze(tone, frame)
assert(plan.bins == 8193, 'all one-sided FFT bins, including DC and Nyquist, must survive')
assert(math.abs(db(values[300]) - 20 * math.log(0.2) / math.log(10)) < 0.001, 'coherent amplitude calibration')
assert(db(values[310]) < -130, 'Hann must not generate distant harmonics')

local stereo = sound(rate, 2, function(t, c) return tone:getSample(math.floor(t * rate + 0.5), 1) * (c == 1 and 1 or -1) end)
local inverted = plan:analyze(stereo, frame)
assert(math.abs(db(inverted[300]) - db(values[300])) < 0.001, 'opposite-phase stereo must not cancel')
local leftOnly = sound(rate, 2, function(t, c) return c == 1 and 0.2 * math.sin(2 * math.pi * frequency * t) or 0 end)
assert(math.abs(db(plan:analyze(leftOnly, frame)[300]) - db(values[300]) + 3.0103) < 0.001,
    'stereo should average channel energy')
local dc = sound(rate, 1, function() return 0.25 end)
assert(math.abs(plan:analyze(dc, frame)[0] - 0.0625) < 1e-7, 'DC must not receive double-sided gain')
local nyquist = sound(rate, 1, function(t) return math.floor(t * rate + 0.5) % 2 == 0 and 0.25 or -0.25 end)
assert(math.abs(plan:analyze(nyquist, frame)[plan.size / 2] - 0.0625) < 1e-7, 'Nyquist gain')

local pair = sound(rate, 1, function(t)
    return 0.1 * (math.sin(2 * math.pi * 1000 * t) + math.sin(2 * math.pi * 1040 * t))
end)
local pairValues = plan:analyze(pair, frame)
local valley = db(powerAt(pairValues, plan, rate, 1020))
assert(db(powerAt(pairValues, plan, rate, 1000, 1)) > valley + 20)
assert(db(powerAt(pairValues, plan, rate, 1040, 1)) > valley + 20)

local weakPlan = Analyzer.new('harmonics', 'blackman_harris')
local weak = sound(rate, 1, function(t)
    return 0.2 * math.sin(2 * math.pi * 3200 * t) + 0.002 * math.sin(2 * math.pi * 3320 * t)
end)
local weakValues = weakPlan:analyze(weak, frame)
local strongDB = db(powerAt(weakValues, weakPlan, rate, 3200, 1))
local weakDB = db(powerAt(weakValues, weakPlan, rate, 3320, 1))
assert(weakDB > db(powerAt(weakValues, weakPlan, rate, 3260)) + 30, 'weak overtone must stand above leakage')
assert(math.abs(strongDB - weakDB - 40) < 1, 'a 40 dB loudness difference must stay 40 dB')
local quiet = sound(rate, 1, function(t) return 1e-6 * math.sin(2 * math.pi * frequency * t) end)
assert(math.abs(db(plan:analyze(quiet, frame)[300]) + 120) < 0.001,
    'raw data below the visible floor must remain available for later gain changes')

-- 低音模式分辨 55 Hz 附近一个半音的间距；显示更多刻度本身不能提高这个分辨能力。
local bass = Analyzer.new('bass', 'hann')
local semitone = Config.hz(Config.midi(55) + 1)
local bassPair = sound(rate, 1, function(t)
    return 0.1 * (math.sin(2 * math.pi * 55 * t) + math.sin(2 * math.pi * semitone * t))
end)
local low = bass:analyze(bassPair, math.floor(rate / bass.hop))
local lowValley = db(powerAt(low, bass, rate, (55 + semitone) / 2))
assert(db(powerAt(low, bass, rate, 55)) > lowValley + 2, 'low semitones need an actual spectral valley')
assert(db(powerAt(low, bass, rate, semitone)) > lowValley + 2)

local transient = Analyzer.new('transient', 'hann')
local pulse = sound(rate, 1, function(t)
    return t >= 1 and t < 1.003 and 0.2 * math.sin(2 * math.pi * 4000 * t) or 0
end)
assert(powerAt(transient:analyze(pulse, math.floor(1.002 * rate / transient.hop)), transient, rate, 4000, 1) > 1e-4)
assert(powerAt(transient:analyze(pulse, math.floor(0.97 * rate / transient.hop)), transient, rate, 4000, 1) == 0)
assert(powerAt(transient:analyze(pulse, math.floor(1.04 * rate / transient.hop)), transient, rate, 4000, 1) == 0)
local silence = sound(rate, 1, function() return 0 end)
for _, data in ipairs({plan:analyze(silence, frame), plan:analyze(tone, -1), plan:analyze(tone, rate)}) do
    for bin = 0, plan.bins - 1 do assert(data[bin] == 0, 'silence and invalid time must be empty') end
end

assert(math.abs(Config.midi(440) - 69) < 1e-10)
assert(Config.pitchName(440) == 'A4 +0ct')
for _, scale in ipairs({'pitch', 'log', 'linear'}) do
    local o = Config.read({spectrogram_min_hz = 50, spectrogram_max_hz = 8000, spectrogram_scale = scale}, rate)
    for _, position in ipairs({0, 0.01, 0.5, 0.99, 1}) do
        assert(math.abs(Config.position(o, Config.frequency(o, position)) - position) < 1e-10)
    end
end
local bad = Config.read({spectrogram_mode = '../../bad', spectrogram_min_hz = math.huge,
    spectrogram_max_hz = -5, spectrogram_floor_db = 0/0, spectrogram_ceiling_db = -999}, 8000)
assert(bad.mode == 'harmonics' and bad.minHz > 0 and bad.maxHz > bad.minHz and bad.maxHz <= 4000)
assert(bad.ceiling >= bad.floor + 6)
print('PASS: calibrated power, stereo, harmonics, weak -120 dB signal, bass semitones, transients and safe frequency coordinates')
