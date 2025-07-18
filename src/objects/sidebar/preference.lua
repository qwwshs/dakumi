--preference界面
local Gpreference = group:new('preference')
Gpreference.type = "preference"
Gpreference.layout = require('config.layouts.sidebar').preference
Gpreference.x_offset_v = {value = '0'}

function Gpreference:load()
    Gpreference.x_offset_v = {value = tostring(chart.preference.x_offset or 0)}
end
function Gpreference:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:edit('field',self.x_offset_v)

    if Nui:button(i18n:get('save')) then
        local old = chart.preference.x_offset
        log(tonumber(self.x_offset_v.value))
        chart.preference.x_offset = tonumber(self.x_offset_v.value) or 0

        if love.window.showMessageBox( "", i18n:get("Whether to offset the previously written event value"),{'no','yes'} ) == 2 then
            for i = 1,#chart.event do
                if chart.event[i].type == "x" then
                    chart.event[i].from = chart.event[i].from - chart.preference.x_offset + old
                    chart.event[i].to = chart.event[i].to - chart.preference.x_offset + old
                end
            end
        end
    end
end


return Gpreference