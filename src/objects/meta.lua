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
            trans = {0,0,1,1},
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
local meta_chart_push = {
    now = false,
    add = {event = {}, note = {}},
    del = {event = {}, note = {}},
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

    --note fake填充
    for i = 1, #chart.note do
        chart.note[i].fake = chart.note[i].fake or 0
    end
    --event trans类型填充 并转移event的trans数字部分
    for i = 1, #chart.event do
        local trans = chart.event[i].trans
        if #trans > 0 then
            --记录数字索引
            local trans_tab = {}
            for j = 1, #trans do
                trans_tab[j] = trans[j]
            end
            --删除数字索引
            for j = 1, #trans do
                chart.event[i].trans[j] = nil
            end
            chart.event[i].trans.trans = trans_tab
        end
        trans.type = trans.type or 'bezier'
        trans.easings = trans.easings or 1
    end
    --hold note head和wipe head填充
    for i = 1, #chart.note do
        if chart.note[i].type == 'hold' then
            chart.note[i].note_head = chart.note[i].note_head or 0
            chart.note[i].wipe_head = chart.note[i].wipe_head or 0
        end
    end
    --track填充

end

function meta_chart.__index:load()
    self:update()
    save(chart, 'chart.json')

end

function meta_chart.__index:push()
    meta_chart_push.now = true
end

function meta_chart.__index:pop()
    meta_chart_push.now = false

    --对chart进行增删改查
    --填入event
    for _,v in ipairs(meta_chart_push.add.event) do
        table.insert(chart.event, v)
    end
    --填入note
    for _,v in ipairs(meta_chart_push.add.note) do
        table.insert(chart.note, v)
    end
    fNote:sort()
    fEvent:sort()
    --删去event
    for _,v in ipairs(meta_chart_push.del.event) do
        for i = 1, #chart.event do
            if table.eq(chart.event[i], v) then
                table.remove(chart.event, i)
                break
            end
        end
    end
    --删去note
    for _,v in ipairs(meta_chart_push.del.note) do
        for i = 1, #chart.note do
            if table.eq(chart.note[i], v) then
                table.remove(chart.note, i)
                break
            end
        end
    end
    --填入redo
    redo:writeRevoke(meta_chart_push)

    meta_chart_push.add = {event = {}, note = {}}
    meta_chart_push.del = {event = {}, note = {}}
end


function meta_chart.__index:add(noteorevent)
    --判断类型
    local iseventtype = noteorevent.type == 'x' or noteorevent.type == 'w'
    local isnotetype = noteorevent.type == 'note' or noteorevent.type == 'hold' or noteorevent.type == 'wipe'
    if not iseventtype and not isnotetype then
        return
    end
    if iseventtype then
        if meta_chart_push.now then
            table.insert(meta_chart_push.add.event, noteorevent)
            return
        end
        table.insert(self.event,noteorevent)
        redo:writeRevoke(noteorevent,'add')
        fEvent:sort()
    elseif isnotetype then
        if meta_chart_push.now then
            table.insert(meta_chart_push.add.note, noteorevent)
            return
        end
        table.insert(self.note,noteorevent)
        redo:writeRevoke(noteorevent,'add')
        fNote:sort()
    end
    
end

function meta_chart.__index:delete(noteorevent)
    local iseventtype = noteorevent.type == 'x' or noteorevent.type == 'w'
    local isnotetype = noteorevent.type == 'note' or noteorevent.type == 'hold' or noteorevent.type == 'wipe'
    if not iseventtype and not isnotetype then
        return
    end
    if iseventtype then
        for i = 1, #self.event do
            if table.eq(self.event[i], noteorevent) then
                if meta_chart_push.now then
                    table.insert(meta_chart_push.del.event, noteorevent)
                    return
                end
                table.remove(self.event, i)
                redo:writeRevoke(noteorevent,'del')
                return
            end
        end
    elseif isnotetype then
        for i = 1, #self.note do
            if table.eq(self.note[i], noteorevent) then
                if meta_chart_push.now then
                    table.insert(meta_chart_push.del.note, noteorevent)
                    return
                end
                table.remove(self.note, i)
                redo:writeRevoke(noteorevent,'del')
                return
            end
        end
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
