--chartInfo界面
local GchartInfo = group:new('chart info')
GchartInfo.type = "chart info"
GchartInfo.layout = require('config.layouts.sidebar').chartInfo

GchartInfo.chartor_v = {value = '0'}
GchartInfo.artist_v = {value = '0'}
GchartInfo.chart_name_v = {value = '0'}
GchartInfo.song_name_v = {value = '0'}
GchartInfo.offset = {value = '0'}
GchartInfo.bpmList = {}

function GchartInfo:load()
    self.chartor_v.value = chart.info.chartor or ''
    self.artist_v.value = chart.info.artist or ''
    self.chart_name_v.value = chart.info.chart_name or ''
    self.song_name_v.value = chart.info.song_name or ''
    self.offset.value = tostring(chart.offset) or "0"

    for i,v in ipairs(chart.bpm_list) do
        self.bpmList[i] = {
            bpm = {value = tostring(v.bpm)},
            beat = {
                {value = tostring(v.beat[1])},
                {value = tostring(v.beat[2])},
                {value = tostring(v.beat[3])}
            }
        }
    end
end

function GchartInfo:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get'chartor')
    Nui:edit('field',self.chartor_v)
    Nui:label(i18n:get'artist')
    Nui:edit('field',self.artist_v)
    Nui:label(i18n:get'chart')
    Nui:edit('field',self.chart_name_v)
    Nui:label(i18n:get'music')
    Nui:edit('field',self.song_name_v)
    Nui:label(i18n:get'offset(ms)')
    Nui:edit('field',self.offset)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols) --换两行
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    local layout = self.layout.bpmList
    Nui:label(i18n:get'bpmlist')
    if Nui:button(i18n:get('add')) then
        --往当前beat位置添加一个bpm
        local nearBeat = to_nearby_Beat(beat.nowbeat)
        self.bpmList[#self.bpmList + 1] = {
            bpm = {value = '120'},
            beat = {
                {value = tostring(nearBeat[1])},
                {value = tostring(nearBeat[2])},
                {value = tostring(nearBeat[3])}
            }
        }
        table.sort(self.bpmList,function(a,b)
            return tonumber(a.beat[1].value) + (tonumber(a.beat[2].value) / tonumber(a.beat[3].value)) < tonumber(b.beat[1].value) + (tonumber(b.beat[2].value) / tonumber(b.beat[3].value))
        end)
    end

    Nui:layoutRow('dynamic', self.layout.bpmList.uiH, self.layout.bpmList.cols)

    for i,v in ipairs(self.bpmList) do
        Nui:label(i)
        Nui:edit('field',v.bpm)
        Nui:edit('field',v.beat[1])
        Nui:edit('field',v.beat[2])
        Nui:edit('field',v.beat[3])
        if Nui:button(i18n:get('sub')) then
            table.remove(self.bpmList,i)
        end
    end

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    if Nui:button(i18n:get('save')) then
        chart.info.chartor = self.chartor_v.value or ""
        chart.info.artist = self.artist_v.value or ""
        chart.info.chart_name = self.chart_name_v.value or ""
        chart.info.song_name = self.song_name_v.value or ""
        chart.offset = tonumber(self.offset.value) or 0

        if #chart.bpm_list ~= #self.bpmList then
            chart.bpm_list = {}
        end
        for i, v in ipairs(self.bpmList) do
            if not chart.bpm_list[i] then   chart.bpm_list[i] = {}  end
            chart.bpm_list[i].bpm = tonumber(v.bpm.value) or 120
            chart.bpm_list[i].beat[1] = tonumber(v.beat[1].value) or 0
            chart.bpm_list[i].beat[2] = tonumber(v.beat[2].value) or 0
            chart.bpm_list[i].beat[3] = tonumber(v.beat[3].value) or 1
        end

        bpm_list_sort()
    end
end


return GchartInfo