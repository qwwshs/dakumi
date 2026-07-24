beat = object:new('beat')
beat.nowbeat = 0
beat.allbeat = 1

function beat:toBeat(bpm, nowtime) --时间转换为beat
    local usetime = 0

    if #bpm == 1 then  
        return bpm[1].bpm / 60 * nowtime 
    end

    for i = 1, #bpm - 1 do
        local beat_start = beat:get(bpm[i].beat)
        local beat_end = beat:get(bpm[i + 1].beat)
        local beat_diff = beat_end - beat_start --beat差值
        local bpm_start = bpm[i].bpm
        local bpm_end = bpm[i + 1].bpm
        
        local temp_nowtime = 0
        
        if bpm[i].linear_ramp == 1 then -- 线性渐变
            if beat_diff == 0 then
                -- 如果beat差为0，瞬间切换
                temp_nowtime = usetime
            elseif bpm_start == bpm_end then
                -- BPM不变，按恒定BPM计算
                temp_nowtime = beat_diff / bpm_start * 60 + usetime
            else
                -- 线性渐变公式：时间 = (bpm_end - bpm_start) / (斜率 * bpm_start * bpm_end)
                -- 更准确：time = (1/slope) * ln(bpm_end / bpm_start)
                local slope = (bpm_end - bpm_start) / beat_diff
                -- 注意：beat_diff 是 beat 差值，slope 单位是 BPM/beat
                -- 时间 = ∫(1/bpm) d(beat) = (1/slope) * ln(bpm_end / bpm_start)
                -- 但这里需要的是从 beat_start 到 beat_end 的时间
                -- 正确公式：time = beat_diff / (bpm_end - bpm_start) * 60 * ln(bpm_end / bpm_start)
                if slope ~= 0 then
                    temp_nowtime = usetime + (beat_diff / (bpm_end - bpm_start)) * 60 * math.log(bpm_end / bpm_start)
                else
                    temp_nowtime = usetime + beat_diff / bpm_start * 60
                end
            end
        else -- 突变 (linear_ramp == 0)
            temp_nowtime = beat_diff / bpm_start * 60 + usetime
        end

        if temp_nowtime < nowtime then
            usetime = temp_nowtime
        else
            -- 根据模式计算对应的beat值
            if bpm[i].linear_ramp == 1 and beat_diff ~= 0 and bpm_start ~= bpm_end then
                -- 渐变模式：需要反向计算beat
                local slope = (bpm_end - bpm_start) / beat_diff
                -- 从公式 time = (1/slope) * ln(bpm(t)/bpm_start) 反推
                -- bpm(t) = bpm_start * exp(slope * (nowtime - usetime))
                -- beat = beat_start + (bpm(t) - bpm_start) / slope
                local elapsed_time = nowtime - usetime
                local current_bpm = bpm_start * math.exp(slope * elapsed_time / 60)  -- 注意时间单位转换
                return beat_start + (current_bpm - bpm_start) / slope
            else
                -- 突变模式或恒定BPM
                return beat_start + (bpm_start / 60 * (nowtime - usetime))
            end
        end
    end

    return beat:get(bpm[#bpm].beat) + (bpm[#bpm].bpm / 60 * (nowtime - usetime))
end

function beat:toTime(bpm, isbeat) -- 根据bpm和beat计算时间
    if type(isbeat) == "table" then 
        isbeat = beat:get(isbeat) 
    end
    
    local function thetime(thebeat, bpm)
        return thebeat / bpm * 60
    end
    
    -- 只有一个BPM或者beat小于第一个BPM的beat时刻
    if #bpm == 1 or isbeat <= beat:get(bpm[2].beat) then
        return thetime(isbeat, bpm[1].bpm)
    end
    
    local usebeat = 0  -- 累计beat
    local total_time = 0  -- 累计时间
    
    for i = 1, #bpm - 1 do
        local beat_start = beat:get(bpm[i].beat)
        local beat_end = beat:get(bpm[i + 1].beat)
        local beat_diff = beat_end - beat_start
        local bpm_start = bpm[i].bpm
        local bpm_end = bpm[i + 1].bpm
        
        local segment_time = 0
        
        if bpm[i].linear_ramp == 1 then -- 线性渐变
            if beat_diff == 0 then
                -- beat差为0，瞬间切换
                segment_time = 0
            elseif bpm_start == bpm_end then
                -- BPM不变
                segment_time = beat_diff / bpm_start * 60
            else
                -- 线性渐变公式：时间 = beat_diff / (bpm_end - bpm_start) * 60 * ln(bpm_end / bpm_start)
                segment_time = (beat_diff / (bpm_end - bpm_start)) * 60 * math.log(bpm_end / bpm_start)
            end
        else -- 突变 (linear_ramp == 0)
            segment_time = beat_diff / bpm_start * 60
        end
        
        local temp_beat = usebeat + beat_diff
        
        -- 检查目标beat是否在当前段内
        if isbeat <= temp_beat then
            -- 在当前段内，计算具体时间
            if bpm[i].linear_ramp == 1 and beat_diff ~= 0 and bpm_start ~= bpm_end then
                -- 渐变模式：需要反向计算时间
                local slope = (bpm_end - bpm_start) / beat_diff
                -- 从公式 beat = beat_start + (bpm(t) - bpm_start) / slope 反推
                -- 其中 bpm(t) = bpm_start * exp(slope * time / 60)
                -- 需要解方程：isbeat - usebeat = (bpm(t) - bpm_start) / slope
                -- bpm(t) = bpm_start + slope * (isbeat - usebeat)
                local current_bpm = bpm_start + slope * (isbeat - usebeat)
                -- 验证current_bpm是否在有效范围内
                if current_bpm > 0 and current_bpm >= math.min(bpm_start, bpm_end) and current_bpm <= math.max(bpm_start, bpm_end) then
                    -- time = (60 / slope) * ln(current_bpm / bpm_start)
                    local time_offset = (60 / slope) * math.log(current_bpm / bpm_start)
                    return total_time + time_offset
                else
                    -- 如果超出范围，使用近似值
                    local avg_bpm = (bpm_start + bpm_end) / 2
                    return total_time + (isbeat - usebeat) / avg_bpm * 60
                end
            else
                -- 突变模式或恒定BPM
                return total_time + thetime(isbeat - usebeat, bpm_start)
            end
        end
        
        -- 否则累加，进入下一段
        usebeat = temp_beat
        total_time = total_time + segment_time
    end
    
    -- 大于最后一个BPM段
    return total_time + thetime(isbeat - beat:get(bpm[#bpm].beat), bpm[#bpm].bpm)
end

function beat:get(table) --beat转成数值
    if table then
        return table[1] + table[2] / table[3]
    else
        return 0
    end
end

function beat:bpmListSort()
    local bpmlist = {}
    while #chart.bpm_list > 0 do
        local bpm_beat_min = 1
        for i = 1, #chart.bpm_list do
            if beat:get(chart.bpm_list[i].beat) < beat:get(chart.bpm_list[bpm_beat_min].beat) then
                bpm_beat_min = i
            end
        end
        bpmlist[#bpmlist + 1] = chart.bpm_list[bpm_beat_min]
        table.remove(chart.bpm_list, bpm_beat_min)
    end
    for i = 1, #bpmlist do
        chart.bpm_list[i] = bpmlist[i]
    end
    beat.allbeat = beat:toBeat(chart.bpm_list, time.alltime)
end

function beat:yToBeat(pos)
    return (pos - settings.judge_line_y) / (-denom.scale * 100) + beat.nowbeat
end

function beat:toY(isbeat)
    if type(isbeat) == "table" then
        return settings.judge_line_y + (beat.nowbeat - beat:get(isbeat)) * denom.scale * 100
    elseif type(isbeat) == "number" then
        return settings.judge_line_y + (beat.nowbeat - isbeat) * denom.scale * 100
    end
end

function beat:add(beat1, beat2) --两个beat相加
    local local_beat1
    local local_beat2

    if type(beat1) == "number" then
        local_beat1 = { math.floor(beat1), math.getNearNumerator(beat1, denom.denom), denom.denom }
    else
        local_beat1 = beat1
    end
    if type(beat2) == "number" then
        local_beat2 = { math.floor(beat2), math.getNearNumerator(beat2, denom.denom), denom.denom }
    else
        local_beat2 = beat2
    end

    local new_numor, new_denom = math.addFractions(local_beat1[2], local_beat1[3], local_beat2[2], local_beat2[3])
    return { local_beat1[1] + local_beat2[1], new_numor, new_denom }
end

function beat:sub(beat1, beat2) --beat相减
    local local_beat1
    local local_beat2
    if type(beat1) == "number" then
        local_beat1 = { math.floor(beat1), math.getNearNumerator(beat1, denom.denom), denom.denom }
    else
        local_beat1 = beat1
    end
    if type(beat2) == "number" then
        local_beat2 = { math.floor(beat2), math.getNearNumerator(beat2, denom.denom), denom.denom }
    else
        local_beat2 = beat2
    end

    local new_numor, new_denom = math.addFractions(local_beat1[2], local_beat1[3], -local_beat2[2], local_beat2[3])
    return { local_beat1[1] - local_beat2[1], new_numor, new_denom }
end

function beat:toNearby(isbeat) --取最近的beat
    return { math.floor(isbeat), math.getNearNumerator(isbeat, denom.denom), denom.denom }
end