--equalizer界面
local Gequalizer = group:new('equalizer')
Gequalizer.type = "equalizer"
Gequalizer.layout = require('config.layouts.sidebar').equalizer
Gequalizer.open = { value = 1 }
Gequalizer.equalizer = {
    type = 'equalizer',
    lowgain = 1.0,           -- 低频增益 [范围: 0.126 ~ 7.943] (1.0 = 无增益/衰减)
    lowcut = 200,            -- 低切频率 [范围: 50 ~ 800] Hz
    lowmidgain = 1.0,        -- 低中频增益 [范围: 0.126 ~ 7.943] (1.0 = 无增益/衰减)
    lowmidfrequency = 500,   -- 低中频中心频率 [范围: 200 ~ 3000] Hz
    lowmidbandwidth = 1.0,   -- 低中频频带宽度 [范围: 0.01 ~ 1.0]
    highmidgain = 1.0,       -- 高中频增益 [范围: 0.126 ~ 7.943] (1.0 = 无增益/衰减)
    highmidfrequency = 3000, -- 高中频中心频率 [范围: 1000 ~ 8000] Hz
    highmidbandwidth = 1.0,  -- 高中频频带宽度 [范围: 0.01 ~ 1.0]
    highgain = 1.0,          -- 高频增益 [范围: 0.126 ~ 7.943] (1.0 = 无增益/衰减)
    highcut = 6000,          -- 高切频率 [范围: 4000 ~ 16000] Hz
}
Gequalizer.equalizerv = {
    {name = 'lowgain',value = 1.0,scope = {0.126, 7.943}, step = 0.001},
    {name = 'lowcut',value = 200,scope = {50, 800}, step = 1},
    {name = 'lowmidgain',value = 1.0,scope = {0.126, 7.943}, step = 0.001},
    {name = 'lowmidfrequency',value = 500,scope = {200, 3000}, step = 1},
    {name = 'lowmidbandwidth',value = 1.0,scope = {0.01, 1.0}, step = 0.01},
    {name = 'highmidgain',value = 1.0,scope = {0.126, 7.943}, step = 0.001},
    {name = 'highmidfrequency',value = 3000,scope = {1000, 8000}, step = 1},
    {name = 'highmidbandwidth',value = 1.0,scope = {0.01, 1.0}, step = 0.01},
    {name = 'highgain',value = 1.0,scope = {0.126, 7.943}, step = 0.001},
    {name = 'highcut',value = 6000,scope = {4000, 16000}, step = 1},
}
print("Equalizer: "..tostring(love.audio.isEffectsSupported()))
function Gequalizer:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)

    Nui:label(i18n:get("equalizer"))
    if Nui:combobox(self.open, { 'OFF', 'ON' }) and self.open.value == 2 then
        love.audio.setEffect("equalizer", self.equalizer)
        music:setEffect("equalizer")
    end

    --效果表
    for _, param in ipairs(self.equalizerv) do
        Nui:label(i18n:get(param.name))
        if Nui:slider(param.scope[1], param, param.scope[2], param.step) then
            self.equalizer[param.name] = param.value
            if self.open.value == 2 then
                love.audio.setEffect("equalizer", self.equalizer)
            end
        end
    end
end

return Gequalizer
