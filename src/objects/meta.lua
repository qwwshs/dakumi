meta_chart = { --谱面基本格式 元表
    __index = {
        bpm_list = {
            { beat = { 0, 0, 1 }, bpm = 120 },
        },
        note = {},
        event = {},
        effect = {},
        offset = 0,
        info = {
            song_name = [[]],
            chart_name = [[]],
            chartor = [[]],
            artist = [[]],
        },
        preference = {
            x_offset = 0,
            event_scale = 100,
        },
        track = {},
        version = 1
    }
}
meta_event = { --谱面事件格式 元表
    __index = {
        beat = { 0, 0, 1 },
        beat2 = { 0, 0, 1 },
        track = 1,
        type = 'x',
        from = 1,
        to = 1,
        trans = {
            1,
            1,
            1,
            1,
            type = 'bezier',
            easings = 1
        },
    }
}
meta_note = { --谱面音符格式 元表
    __index = {
        beat = { 0, 0, 1 },
        track = 1,
        type = 'note',
        fake = 0,
    }
}
function meta_chart.__index:update()
    local find_form = false
    for i = 1, #chart.event do
        if chart.event[i].form then                   --遗留问题 当时打错字了
            chart.event[i].from = chart.event[i].form --更新
            chart.event[i].form = nil
            find_form = true
        end
    end
    if find_form then
        save(chart, 'chart.json')
    end
    --note fake填充
    for i = 1, #chart.note do
        chart.note[i].fake = chart.note[i].fake or 0
    end
    --event trans类型填充
    for i = 1, #chart.event do
        local trans = chart.event[i].trans
        trans.type = trans.type or 'bezier'
    end
    --hold note head和wipe head填充
    for i = 1, #chart.note do
        if chart.note[i].type == 'hold' then
            chart.note[i].note_head = chart.note[i].note_head or 0
            chart.note[i].wipe_head = chart.note[i].wipe_head or 0
        end
    end
end

function meta_chart.__index:load()
    self:update()
    --解决谱面trans索引混乱的问题
    local function sortNumericKeys(tbl)
        -- 收集数字键值对
        local numericEntries = {}
        local otherEntries = {}

        -- 分离数字索引和其他类型的键
        for k, v in pairs(tbl) do
            if type(k) == "number" then
                table.insert(numericEntries, { key = k, value = v })
            else
                otherEntries[k] = v
            end
        end

        -- 按数字键排序
        table.sort(numericEntries, function(a, b)
            return a.key < b.key
        end)

        -- 创建新表，重新设置连续的数字索引
        local newTable = {}

        -- 添加其他类型的键
        for k, v in pairs(otherEntries) do
            newTable[k] = v
        end

        -- 重新设置数字索引（从1开始连续）
        for i, entry in ipairs(numericEntries) do
            newTable[i] = entry.value
        end

        return newTable
    end

    for i = 1, #chart.event do
        local v = chart.event[i]
        --先化索引为数字
        for k, val in pairs(v.trans) do
            if type(k) ~= "number" and tonumber(k) then
                v.trans[tonumber(k)] = val
                v.trans[k] = nil
            end
        end
        v.trans = sortNumericKeys(v.trans)
    end
end

meta_settings = { --设置基本格式 元表
    __index = {

        judge_line_y = 700,
        music_volume = 100,
        hit_volume = 100,
        hit = 0,
        hit_sound = 0,
        track_w_scale = 8,
        language = "zh-CN",
        contact_roller = 1, --鼠标滚动系数
        note_height = 75,
        bg_alpha = 50,
        denom_alpha = 70,
        window_width = WINDOW.w,
        window_height = WINDOW.h,
        auto_save = 1, --自动保存,
    }
}
