--[[
    模块名: spectrogram 后台任务
    描述: 固定采样网格的 STFT 与时间缩小汇总；通过共享内存分批返回，界面线程不等待 FFT。
]]
return function(requests, responses, cancellation)
    require('love.sound')
    require('love.data')
    require('love.timer')
    local ffi = require('ffi')
    local Analyzer = require('src.services.spectrogramAnalyzer')
    local analyzer, signature
    while true do
        local job = requests:demand(2)
        if not job then break end
        local ok, message = pcall(function()
            local nextSignature = job.mode .. '|' .. job.window
            if signature ~= nextSignature then
                analyzer, signature = Analyzer.new(job.mode, job.window), nextSignature
            end
            local bins, keys, data, values, frames = analyzer.bins, {}, nil, nil, 0
            local scratch = Analyzer.array(bins)
            local function flush()
                if #keys == 0 then return true end
                -- 暂停绘制或隐藏声纹时，未接收的结果最多占约 8 MiB。
                while responses:getCount() >= math.max(1, math.floor(8 * 1024 * 1024 / (8 * bins * 4))) do
                    if cancellation:peek() ~= job.token then return false end
                    love.timer.sleep(0.005)
                end
                if #keys < 8 then data = love.data.newByteData(data:getString():sub(1, #keys * bins * 4)) end
                responses:push({generation = job.generation, token = job.token, keys = keys,
                    data = data, frames = frames})
                keys, data, values, frames = {}, nil, nil, 0
                return true
            end
            for _, cell in ipairs(job.cells) do
                if cancellation:peek() ~= job.token then break end
                if not data then
                    data = love.data.newByteData(8 * bins * 4)
                    values = ffi.cast('float*', data:getPointer())
                end
                local offset, canceled = #keys * bins, false
                local lastFrame = math.floor((job.sound:getSampleCount() - 1) / analyzer.hop)
                for sub = 0, math.min(job.step - 1, lastFrame - cell * job.step) do
                    if cancellation:peek() ~= job.token then canceled = true; break end
                    local frame = cell * job.step + sub
                    if sub == 0 then
                        analyzer:analyze(job.sound, frame, values, offset)
                    else
                        analyzer:analyze(job.sound, frame, scratch)
                        for bin = 0, bins - 1 do values[offset + bin] = math.max(values[offset + bin], scratch[bin]) end
                    end
                    frames = frames + 1
                end
                if canceled then break end
                keys[#keys + 1] = job.step .. ':' .. cell
                if #keys == 8 and not flush() then return end
            end
            flush()
        end)
        if not ok then responses:push({error = tostring(message)}); break end
    end
end
