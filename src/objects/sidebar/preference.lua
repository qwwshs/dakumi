--preference界面
local Gpreference = group:new('preference')
Gpreference.type = "preference"
Gpreference.layout = require('config.layouts.sidebar').preference
Gpreference.x_offset_v = {value = '0'}
Gpreference.event_scale_v = {value = '100'}
function Gpreference:load()
    Gpreference.x_offset_v = {value = tostring(chart.preference.x_offset or 0)}
    Gpreference.event_scale_v = {value = tostring(chart.preference.event_scale or 100)}
end
function Gpreference:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get"x_offset")
    Nui:edit('field',self.x_offset_v)
    Nui:label(i18n:get"event_scale")
    Nui:edit('field',self.event_scale_v)

    if Nui:button(i18n:get('save')) then
        local old = chart.preference.x_offset
        chart.preference.x_offset = tonumber(self.x_offset_v.value) or 0
        chart.preference.event_scale = tonumber(self.event_scale_v.value) or 100

        --[[if love.window.showMessageBox( "", i18n:get("Whether to offset the previously written event value"),{'no','yes'} ) == 2 then
            for i = 1,#chart.event do
                if chart.event[i].type == "x" then
                    chart.event[i].from = chart.event[i].from - chart.preference.x_offset + old
                    chart.event[i].to = chart.event[i].to - chart.preference.x_offset + old
                end
            end
        end]]
    end
end


return Gpreference