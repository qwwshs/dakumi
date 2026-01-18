beat = object:new('beat')
beat.nowbeat = 0
beat.allbeat = 1
function beat:toBeat(bpm, time) --时间转换为beat
    local usetime = 0
    if #bpm == 1 or time <= beat:get(bpm[2].beat) / bpm[1].bpm * 60 then return (bpm[1].bpm / 60 * time) end --只有一个 或时间小于变bpm前 直接返回

    local bpm_beat = beat:get(bpm[2].beat)                                                                   -- 转数值
    usetime = bpm_beat / bpm[1].bpm * 60                                                                     --得到时间计算 直到当前时间

    for i = 2, #bpm - 1 do
        bpm_beat = beat:get(bpm[i + 1].beat) - beat:get(bpm[i].beat) -- 转数值 得到差值 继续算usetime
        local temp_time = bpm_beat / bpm[i].bpm * 60 + usetime       --得到加法后时间 如果加了后小于当前时间就加上去
        if temp_time < time then
            usetime = temp_time
        else --如果不是转成结果
            return beat:get(bpm[i].beat) + (bpm[i].bpm / 60 * (time - usetime))
        end
    end

    return beat:get(bpm[#bpm].beat) + (bpm[#bpm].bpm / 60 * (time - usetime))
end

function beat:toTime(bpm, isbeat)                              -- 根据bpm和beat计算时间
    if type(isbeat) == "table" then isbeat = beat:get(isbeat) end  -- 转数值
    local function thetime(thebeat, bpm)                      -- 转时间的函数
        return thebeat / bpm * 60
    end

    if #bpm == 1 or isbeat <= beat:get(bpm[2].beat) then -- 只有一个或者beat小于第一个bpm的beat时刻
        return thetime(isbeat, bpm[1].bpm)
    end


    local usebeat = beat:get(bpm[2].isbeat)        --累加beat 直到当前beat
    local bpm_time = thetime(usebeat, bpm[1].bpm) -- 转换为数值
    local all_bpm_time = bpm_time
    for i = 2, #bpm - 1 do
        bpm_time = thetime(beat:get(bpm[i + 1].beat) - beat:get(bpm[i].beat), bpm[i].bpm) -- 计算时间差值

        local temp_beat = (bpm[i].bpm * bpm_time / 60) + usebeat
        if temp_beat < beat then
            usebeat = temp_beat
        else
            return all_bpm_time + thetime((isbeat - usebeat), bpm[i].bpm)
        end
        all_bpm_time = all_bpm_time + bpm_time
    end
    --大于最后一个
    return all_bpm_time + thetime((isbeat - beat:get(bpm[#bpm].beat)), bpm[#bpm].bpm)
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