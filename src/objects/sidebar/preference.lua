--preference界面
local ChartService = require("src.services.chartService")
local Gpreference = group:new('preference')
Gpreference.type = "preference"
Gpreference.layout = require('config.layouts.sidebar').preference
Gpreference.x_offset_v = {value = '0'}
Gpreference.event_scale_v = {value = '100'}
Gpreference.jumpMode = {value = 1}
function Gpreference:load()
    self.jumpMode.value=ChartService:getPreferenceField('jump_mode')=='cumulative' and 2 or 1
    Gpreference.x_offset_v = {value = tostring(ChartService:getPreferenceField('x_offset') or 0)}
    Gpreference.event_scale_v = {value = tostring(ChartService:getPreferenceField('event_scale') or 100)}
end
function Gpreference:to()
    self:load()
end

function Gpreference:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get"x_offset")
    ui:edit('field',self.x_offset_v)
    Nui:label(i18n:get"event_scale")
    ui:edit('field',self.event_scale_v)

    Nui:label(i18n:get('jump_mode'))
    Nui:combobox(self.jumpMode,{i18n:get('jump_mode_current'),i18n:get('jump_mode_cumulative')})

    if ui:tip(i18n:get('save')) then
        local old = ChartService:getPreferenceField('x_offset')
        ChartService:change('history.edit_preference', function()
            ChartService:setPreferenceField('x_offset', tonumber(self.x_offset_v.value) or 0)
            ChartService:setPreferenceField('event_scale', tonumber(self.event_scale_v.value) or 100)
            ChartService:setPreferenceField('jump_mode',self.jumpMode.value==2 and 'cumulative' or 'current')
        end)

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