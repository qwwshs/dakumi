--[[
    单次 BPM / 起始静音测量，LuaJIT FFI 实现。
    移植自 https://github.com/qwwshs/bpm 的 bpm.c
    版本：4978169ce0af0f4664a5bdd709d90fb322dabc05。
    保留四频段滤波、1 ms 包络、自相关与峰值拟合；不包含 TUI 和音频播放。
    返回的 offsetMs 是音频开头静音时长，尚未换算为谱面 offset。
]]
local ffi = require('ffi')
local floor, sqrt, abs, min, max = math.floor, math.sqrt, math.abs, math.min, math.max
local function round(x) return floor(x + 0.5) end
local function array(kind, n) return ffi.new(kind .. '[?]', n) end
local Analyzer = {}
local banks = {
    [48000] = {
        {2,1,-1.9357148371211979,.94170045160372695,.001496403620632246},
        {2,1,-1.8590762659582099,.86482489876726276,.0014371582022632194},
        {0,-1,-1.9731491828203316,.97953721714347519,.038683376541251063},
        {0,-1,-1.9383006635720235,.96137281475624847,.038683376541251063},
        {0,-1,-1.9305470566393397,.93953993813607839,.037909869457216396},
        {0,-1,-1.9047367208661594,.92047699481829581,.037909869457216396},
        {0,-1,-1.9341140031258925,.95936683579188464,.076211068056843939},
        {0,-1,-1.834546897615803,.92460252591545578,.076211068056843939},
        {0,-1,-1.8474800548242554,.88234057507713604,.07333821798839002},
        {0,-1,-1.786708494362891,.84711889379273642,.07333821798839002},
        {-2,1,-1.7009643319435259,.78849973981529797,.87236601793970592},
        {-2,1,-1.4796742169311932,.55582154328248878,.75887394005342046},
        {0,0,-1.9522250000000001,.95230941015625004,.0441},
        {2,1,-1.9688774973857579,.97039660175711517,.00037977609283935493},
        {2,1,-1.9285084850826344,.9299964423952546,.0003719893281551018},
        {0,0,-1.4,.48,.2},
    },
    [32000] = {
        {2,1,-1.9006465638071275,.91391293369153381,.0033165924711015399},
        {2,1,-1.791587696777784,.80409284398316283,.0031262868013446823},
        {0,-1,-1.9551331294901764,.96942359724192628,.057589864308760577},
        {0,-1,-1.8914384351956604,.94273848531403681,.057589864308760577},
        {0,-1,-1.8906481524757157,.91056795618768371,.0559132077540236},
        {0,-1,-1.8483764376432956,.88306736308808476,.0559132077540236},
        {0,-1,-1.8832665479670578,.93936089151864399,.11261473189959464},
        {0,-1,-1.6928128227129573,.88994695879396346,.11261473189959464},
        {0,-1,-1.75188517392731,.82786888860462982,.10660246744674093},
        {0,-1,-1.6489134150085212,.77932148942151369,.10660246744674093},
        {-2,1,-1.5182418440638745,.7039626566672621,.80555112518278416},
        {-2,1,-1.2554404734849929,.40901378318031245,.66611356416632628},
        {0,0,-1.9283375,.92852742285156253,.06615},
        {2,1,-1.9525426196393316,.95593497333644439,.00084808842427817996},
        {2,1,-1.8935423413365597,.8968321877643215,.0008224616069403773},
        {0,0,-1.4,.48,.2},
    },
    [44100] = {
        {2,1,-1.9296472648815026,.93671950987931574,.0017680612494532478},
        {2,1,-1.8470012302151446,.8537705737366641,.0016923358803798848},
        {0,-1,-1.9701832899735581,.9777435661450361,.042048320411797346},
        {0,-1,-1.9307644878934767,.95804211074743828,.042048320411797346},
        {0,-1,-1.923734068386191,.93435845766892844,.041138010165536872},
        {0,-1,-1.8951712655794619,.9137505704894946,.041138010165536872},
        {0,-1,-1.925968651733853,.9558199793811436,.082730627558081263},
        {0,-1,-1.8121187013381126,.91831227931931725,.082730627558081263},
        {0,-1,-1.8314525533284556,.87252152856112386,.079370925545494644},
        {0,-1,-1.7636927184274693,.83473849906751341,.079370925545494644},
        {-2,1,-1.6699250371362808,.77254617806529502,.86061780380039399},
        {-2,1,-1.438556103531466,.52695903501152652,.74137878463574813},
        {0,0,-1.948,.94810000000000005,.048},
        {2,1,-1.9660249635383409,.96782223970722425,.00044931904222082926},
        {2,1,-1.9222869522443087,.9240442445437952,.0004393230748716104},
        {0,0,-1.4,.48,.2},
    }
}
local function filter(x, n, bank, first, count)
    local state = array('float', 2)
    local coefficient = array('float', 5)
    for stage = first, first + count - 1 do
        local c = bank[stage + 1]
        for j = 0, 4 do coefficient[j] = c[j + 1] end
        local b0, b1, a1, a2, b2 = coefficient[0], coefficient[1], -coefficient[2], -coefficient[3], coefficient[4]
        state[0], state[1] = 0, 0
        for i = 0, n - 1 do
            local previous = state[0]
            local value = previous * a1 + b2 * x[i] + state[1] * a2
            -- 用 float 数组保存滤波状态，与原库的单精度状态一致。
            x[i] = previous * b0 + value + state[1] * b1
            state[0], state[1] = value, previous
        end
    end
end

local function fft(re, im, n, inverse)
    local j = 0
    for i = 1, n - 1 do
        local bit = n / 2
        while j >= bit do j = j - bit; bit = bit / 2 end
        j = j + bit
        if i < j then re[i], re[j], im[i], im[j] = re[j], re[i], im[j], im[i] end
    end
    local length = 2
    while length <= n do
        local angle = (inverse and 2 or -2) * math.pi / length
        local wr, wi = math.cos(angle), math.sin(angle)
        local half = length / 2
        for start = 0, n - 1, length do
            local r, v = 1, 0
            for k = start, start + half - 1 do
                local q = k + half
                local tr, ti = r * re[q] - v * im[q], r * im[q] + v * re[q]
                re[q], im[q] = re[k] - tr, im[k] - ti
                re[k], im[k] = re[k] + tr, im[k] + ti
                r, v = r * wr - v * wi, r * wi + v * wr
            end
        end
        length = length * 2
    end
    if inverse then for i = 0, n - 1 do re[i], im[i] = re[i] / n, im[i] / n end end
end

local function peak(env, n, center)
    local first, last = max(0, center - 10), min(n - 1, center + 10)
    local best = first
    for i = first + 1, last do if env[i] > env[best] then best = i end end
    return best
end

local function fitOnce(env, n, initial)
    local period = round(initial)
    if period < 180 or period > 2000 then return initial, 1e9, 1 end
    -- 预先缓存局部峰，避免逐相位拟合时反复扫描同一 21 ms 区域。
    local peaks = array('int32_t', n)
    for i = 0, n - 1 do peaks[i] = peak(env, n, i) end
    local bestScore, bestPhase = -1, 0
    for phase = 0, period - 1 do
        local score, b = 0, 0
        while phase + b * initial < n do
            local center = round(phase + b * initial)
            if center >= n then break end
            score, b = score + env[peaks[center]], b + 1
        end
        if score > bestScore then bestScore, bestPhase = score, phase end
    end
    local sx, sy, sxx, sxy, syy, count, b = 0, 0, 0, 0, 0, 0, 0
    while bestPhase + b * initial < n do
        local center = round(bestPhase + b * initial)
        if center >= n then break end
        local p = peaks[center]
        if env[p] > 0 then
            sx, sy, sxx, sxy, syy, count = sx+b, sy+p, sxx+b*b, sxy+b*p, syy+p*p, count+1
        end
        b = b + 1
    end
    if count < 4 or count*sxx <= sx*sx then return initial, 1e9, 1 end
    local xx, xy, yy = sxx-sx*sx/count, sxy-sx*sy/count, syy-sy*sy/count
    local slope = xy/xx
    local sse = max(0, yy-xy*xy/xx)
    return slope > 0 and slope or initial, sqrt(sse/(count-1)), slope > 0 and sqrt(sse/(count-2)/xx)/slope or 1
end

local function estimate(env, n, check)
    local size = 1
    while size < n*2 do size = size*2 end
    local re, im = array('double', size), array('double', size)
    ffi.copy(re, env, n*8)
    fft(re, im, size, false)
    check()
    for i = 0, size-1 do re[i], im[i] = re[i]*re[i]+im[i]*im[i], 0 end
    fft(re, im, size, true)
    check()
    local best, bestScore = 0, -1e300
    local limit = min(2000, math.ceil(n/2)-1)
    for lag = 180, limit do
        local p, localPeak = re[lag], true
        for neighbor = max(1, lag-16), min(lag+16, size/2-1) do
            if neighbor ~= lag and re[neighbor] > p then localPeak = false; break end
        end
        if localPeak then
            local sum, hits = 0, 0
            for h = 1, floor(limit/lag) do
                local value = -1e300
                for i = max(1,h*lag-10), min(h*lag+10, floor(n/2)-1) do
                    if re[i] >= re[i-1] and re[i] >= re[i+1] and re[i] > value then value = re[i] end
                end
                if value > -1e299 then sum, hits = sum+value, hits+1 end
            end
            if hits >= 4 and p*0.7 < sum/hits and sum/hits > bestScore then best, bestScore = lag, sum/hits end
        end
    end
    if best == 0 then
        for lag = 180, limit do if re[lag] > bestScore then best, bestScore = lag, re[lag] end end
    end
    if best == 0 or re[best] <= 0 then return 0, 1 end
    for _, option in ipairs({{0.5,220,270,0.85},{2/3,270,340,0.70}}) do
        local center, p, candidate = round(best*option[1]), 0, 0
        if center >= 180 then
            for i = center-4, center+4 do
                if re[i] > p and re[i] >= re[i-1] and re[i] >= re[i+1] then p, candidate = re[i], i end
            end
            if candidate > 0 and p >= re[best]*option[4] and 60000/candidate >= option[2] and 60000/candidate <= option[3] then best = candidate; break end
        end
    end
    local xx, xy, weight, points = 0, 0, 0, {}
    for h = 1, min(11, floor(limit/best)) do
        local p, index = 0, 0
        for i = max(1,h*best-10), min(h*best+10,limit) do
            if re[i] > p and re[i] >= re[i-1] and re[i] >= re[i+1] then p, index = re[i], i end
        end
        if index > 0 and p >= re[best]*0.35 then
            points[#points+1] = {h,index,p}
            xx, xy, weight = xx+p*h*h, xy+p*h*index, weight+p
        end
    end
    local reliable, period = false, best
    if #points >= 3 and xx > 0 then
        period = xy/xx
        local err = 0
        for _, p in ipairs(points) do err = err+p[3]*(p[2]-p[1]*period)^2 end
        reliable = sqrt(err/weight) <= 1.5
    end
    if not reliable then
        local denom = re[best-1]-2*re[best]+re[best+1]
        local shift = abs(denom)>1e-20 and 0.5*(re[best-1]-re[best+1])/denom or 0
        period = best+max(-0.5,min(0.5,shift))
    end
    re, im = nil, nil
    local first, residual, relative = fitOnce(env,n,period)
    check()
    local second, secondResidual, secondRelative = fitOnce(env,n,first)
    if abs(second-first)<1 and secondResidual<=residual+0.5 then first,residual,relative=second,secondResidual,secondRelative end
    if not reliable or abs(first-period)>0.5 then period=first end
    return 60000/period, relative
end

-- 与原库一样检查连续片段的节奏变化，只提示不可靠，不生成多段 BPM。
local function fluctuates(env, n, whole, check)
    if n < 32000 then return false end
    local windows, outliers, streak, longest = 0, 0, 0, 0
    local tolerance = max(3, whole*0.03)
    local pointer = ffi.cast('double*', env)
    for start = 0, n-16000, 8000 do
        check()
        local bpm = estimate(pointer+start, 16000, check)
        if bpm > 0 then
            local distance = abs(bpm-whole)
            for _, factor in ipairs({0.5,2/3,0.75,1,4/3,1.5,2,3}) do distance=min(distance,abs(bpm*factor-whole)) end
            windows=windows+1
            if distance>tolerance then
                outliers,streak=outliers+1,streak+1
                longest=max(longest,streak)
            else streak=0 end
        else streak=0 end
    end
    return windows>=3 and outliers>=3 and outliers*5>=windows and longest>=3
end

function Analyzer.measure(sound, progress)
    local check = progress or function() end
    local rate, channels, frames = sound:getSampleRate(), sound:getChannelCount(), sound:getSampleCount()
    if frames/rate < 2 then error('too_short') end
    -- 保持内存有界；长音频不静默截取后声称是整曲测量。
    if frames/rate > 1800 then error('too_long') end
    local bits = sound:getBitDepth()
    local pointer = ffi.cast(bits == 16 and 'const int16_t*' or 'const uint8_t*', sound:getPointer())
    local function sample(frame)
        local sum = 0
        for c = 0, channels-1 do
            local value = pointer[frame*channels+c]
            sum = sum + (bits == 16 and value/32768 or (value-128)/128)
        end
        return sum/channels
    end
    assert(bits == 8 or bits == 16, 'unsupported_pcm')
    local originalRate, originalFrames = rate, frames
    if not banks[rate] then rate = 44100; frames = floor(originalFrames*rate/originalRate) end
    local bank, n = banks[rate], math.ceil(frames*1000/rate)
    local mono, rms = array('float',frames), array('double',n)
    for i = 0, frames-1 do
        local p = i*originalRate/rate
        local first = floor(p)
        mono[i] = sample(first)*(1-(p-first))+sample(min(first+1,originalFrames-1))*(p-first)
        local ms = floor(i*1000/rate)
        rms[ms] = rms[ms]+mono[i]*mono[i]
        if i % 262144 == 0 then check() end
    end
    local maximum = 0
    for ms = 0, n-1 do
        rms[ms] = sqrt(rms[ms]/max(1,floor((ms+1)*rate/1000)-floor(ms*rate/1000)))
        maximum = max(maximum,rms[ms])
    end
    if maximum <= 1e-9 then error('silent') end
    local offset = 0
    for ms = 0,n-1 do if rms[ms] > maximum*0.02 then offset=ms; break end end
    rms = nil
    local band, score = array('float',frames), array('float',frames)
    local raw = ffi.cast('uint32_t*',band)
    for b, spec in ipairs({{0,2,320,0.3},{2,4,64,0.2},{6,4,32,0.2},{10,2,0,0.3}}) do
        check()
        ffi.copy(band,mono,frames*4)
        filter(band,frames,bank,spec[1],spec[2])
        for i = 0,frames-1 do band[i]=band[i]*band[i] end
        if b == 1 then filter(band,frames,bank,12,1) end
        local histogram = array('uint32_t',4097)
        for i = 0,frames-1 do
            local bin = min(4096,floor((tonumber(raw[i])%2147483648+262144)/524288))
            histogram[bin]=histogram[bin]+1
        end
        local median, cumulative = 0,0
        while median<4096 and cumulative<floor(frames/2) do cumulative=cumulative+histogram[median]; median=median+1 end
        local threshold = array('uint32_t',1)
        threshold[0]=median*524288
        local scale=2/max(1e-30,tonumber(ffi.cast('float*',threshold)[0]))
        local weight=spec[4]*8.262958317573066e-8
        for i = 0,frames-1-spec[3] do
            -- C 的越界整数转换没有定义；稀疏/静音段用饱和保护，避免溢出污染整段包络。
            local quantized=min(2147483647,max(0,floor(band[i+spec[3]]*scale+1)-1))
            score[i]=score[i]+quantized*weight
        end
    end
    mono, band, raw = nil,nil,nil
    check()
    filter(score,frames,bank,13,2)
    local env, forward, reverse = array('double',n),array('float',n),array('float',n)
    for ms = 0,n-1 do local source=round(ms*rate/1000); if source<frames then forward[ms]=score[source] end end
    for ms = 0,n-1 do reverse[ms]=forward[n-1-ms] end
    score=nil
    filter(forward,n,bank,15,1); filter(reverse,n,bank,15,1)
    env[n-1],env[0]=-forward[n-2],reverse[n-2]
    for ms=1,n-2 do env[ms]=reverse[n-2-ms]-forward[ms-1] end
    local mean=0
    for ms=0,n-1 do mean=mean+env[ms] end
    mean=mean/n
    for ms=0,n-1 do env[ms]=env[ms]-mean end
    forward,reverse=nil,nil
    check()
    local bpm, relative=estimate(env,n,check)
    if bpm~=bpm or bpm<=0 or bpm==math.huge then error('no_rhythm') end
    if relative<=0.00005 then
        local factors,tolerances={1,2,3,10,20,100,200},{3,2.5,2,2,1.5,1.5,1}
        for i,f in ipairs(factors) do
            if abs(bpm-round(bpm*f)/f)<=bpm*relative*tolerances[i] then bpm=round(bpm*f)/f; break end
        end
    end
    return {bpm=round(bpm*10)/10, offsetMs=offset, uncertain=relative>0.00005 or fluctuates(env,n,bpm,check)}
end

return Analyzer
