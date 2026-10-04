local AudioService = require('src.services.audioService')
--chartInfo界面
local ChartService = require("src.services.chartService")
local BpmMeasure = require('src.services.bpmMeasureService')
local GchartInfo = group:new('chart info')
GchartInfo.type = "chart info"
GchartInfo.layout = require('config.layouts.sidebar').chartInfo

GchartInfo.chartor_v = {value = '0'}
GchartInfo.artist_v = {value = '0'}
GchartInfo.chart_name_v = {value = '0'}
GchartInfo.song_name_v = {value = '0'}
GchartInfo.offset = {value = '0'}
GchartInfo.bpmList = {}

local function editTextField(field)
    field.value = sanitizeUtf8(field.value)

    -- Do not allow invalid input from an OS clipboard or a malformed import to
    -- bring down the editor while Nuklear's native UTF-8 editor is running.
    local ok, event, changed = pcall(Nui.edit, Nui, 'field', field)
    if not ok then
        log('Skipped invalid chart-info text: ' .. sanitizeUtf8(event, 512))
        field.value = ''
        return nil, false
    end
    return event, changed
end

function GchartInfo:load()
    self.chartor_v.value = sanitizeUtf8(ChartService:getInfoField('chartor'))
    self.artist_v.value = sanitizeUtf8(ChartService:getInfoField('artist'))
    self.chart_name_v.value = sanitizeUtf8(ChartService:getInfoField('chart_name'))
    self.song_name_v.value = sanitizeUtf8(ChartService:getInfoField('song_name'))
    self.offset.value = tostring(ChartService:getOffset()) or "0"

    -- 整份重建：本页每次进入都会 load，残留上一次的多余条目会让保存把已删除的 BPM 写回谱面
    self.bpmList = {}
    for i = 1, ChartService:getBpmCount() do
        local v = ChartService:getBpm(i)
        self.bpmList[i] = {
            bpm = {value = tostring(v.bpm)},
            beat = {
                {value = tostring(v.beat[1])},
                {value = tostring(v.beat[2])},
                {value = tostring(v.beat[3])}
            },
            linear_ramp = v.linear_ramp or 0
        }
    end
end

function GchartInfo:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get'chartor')
    editTextField(self.chartor_v)
    Nui:label(i18n:get'artist')
    editTextField(self.artist_v)
    Nui:label(i18n:get'chart')
    editTextField(self.chart_name_v)
    Nui:label(i18n:get'music')
    editTextField(self.song_name_v)
    Nui:label(i18n:get'offset(ms)')
    ui:edit('field',self.offset)

    Nui:layoutRow('dynamic', self.layout.uiH, 1)
    if Nui:button(i18n:get(BpmMeasure:isBusy() and 'bpm_measure_busy' or 'bpm_measure')) and not BpmMeasure:isBusy() then
        BpmMeasure:start(function(bpm, offset)
            -- 仅更新测量字段，保留本页其它尚未保存的输入。
            self.offset.value = tostring(offset)
            self.bpmList[1] = self.bpmList[1] or {
                bpm = {value = ''}, beat = {{value = '0'}, {value = '0'}, {value = '1'}}, linear_ramp = 0,
            }
            self.bpmList[1].bpm.value = tostring(bpm)
        end)
    end

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols) --换两行
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    local layout = self.layout.bpmList
    Nui:label(i18n:get'bpmlist')
    if Nui:button(i18n:get('add')) then
        --往当前beat位置添加一个bpm
        local nearBeat = beat:toNearby(AudioService:getCurrentBeat())
        self.bpmList[#self.bpmList + 1] = {
            bpm = {value = '120'},
            beat = {
                {value = tostring(nearBeat[1])},
                {value = tostring(nearBeat[2])},
                {value = tostring(nearBeat[3])}
            },
            linear_ramp = 0
        }
        table.sort(self.bpmList,function(a,b)
            return tonumber(a.beat[1].value) + (tonumber(a.beat[2].value) / tonumber(a.beat[3].value)) < tonumber(b.beat[1].value) + (tonumber(b.beat[2].value) / tonumber(b.beat[3].value))
        end)
    end

    Nui:layoutRow('dynamic', self.layout.bpmList.uiH, self.layout.bpmList.cols)

    for i,v in ipairs(self.bpmList) do
        Nui:label(i)
        ui:edit('field',v.bpm)
        ui:edit('field',v.beat[1])
        ui:edit('field',v.beat[2])
        ui:edit('field',v.beat[3])
        if Nui:button(i18n:get('sub')) then
            table.remove(self.bpmList,i)
        end
        Nui:layoutRow('dynamic', self.layout.bpmList.uiH, 2)
        Nui:label(i18n:get 'linear_ramp_to_the_next')
        v.linear_ramp = Nui:combobox(v.linear_ramp + 1, { 'OFF', 'ON' }) - 1


    end

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    if ui:tip(i18n:get('save')) then
        -- 信息/offset/BPM 列表的整次保存归入同一事务
        ChartService:change('history.edit_chart_info', function()
        ChartService:setInfoField('chartor', sanitizeUtf8(self.chartor_v.value))
        ChartService:setInfoField('artist', sanitizeUtf8(self.artist_v.value))
        ChartService:setInfoField('chart_name', sanitizeUtf8(self.chart_name_v.value))
        ChartService:setInfoField('song_name', sanitizeUtf8(self.song_name_v.value))
        ChartService:setOffset(tonumber(self.offset.value) or 0)

        -- 组装新的 BPM 列表并整体替换（保留原有替换/就地修改的语义）
        local new_bpm_list = {}
        for i, v in ipairs(self.bpmList) do
            local bpm = tonumber(v.bpm.value) or 120
            if bpm <= 0 then bpm = 120 end
            new_bpm_list[i] = {
                bpm = bpm,
                beat = {
                    tonumber(v.beat[1].value) or 0,
                    tonumber(v.beat[2].value) or 0,
                    tonumber(v.beat[3].value) or 1,
                },
                linear_ramp = v.linear_ramp,
            }
        end
        ChartService:setBpmList(new_bpm_list)

        ChartService:sortBpmList()
        end)
    end
end


return GchartInfo
