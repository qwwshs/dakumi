local ctx
--equalizer界面
local AudioService = require('src.services.audioService')
local Gequalizer = group:new('equalizer')
Gequalizer.type = "equalizer"
Gequalizer.layout = {cols = 2, uiH = 20}
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
function Gequalizer:Nui()
    ctx.ui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)

    ctx.ui:label(ctx.i18n:get("equalizer"))
    if ctx.ui:combobox(self.open, {'OFF', 'ON'}) then
        AudioService:setEffect('equalizer', self.open.value == 2 and self.equalizer or false)
    end

    --效果表
    for _, param in ipairs(self.equalizerv) do
        ctx.ui:label(ctx.i18n:get(param.name))
        if ctx.ui:slider(param.scope[1], param, param.scope[2], param.step) then
            self.equalizer[param.name] = param.value
            if self.open.value == 2 then
                AudioService:setEffect('equalizer', self.equalizer)
            end
        end
    end
end

local sidebarRoom, homeGroup, navigation

return {
    name = 'equalizer',
    version = '1.0.0',
    description = '侧边栏均衡器',
    target = 'edit/sidebar',

    init = function(context)
        ctx = context
        sidebarRoom = ctx.root:findContainer('edit/sidebar')
        homeGroup = sidebarRoom:getGroup('nil')
        navigation = object:new('equalizer navigation')
        function navigation:Nui()
            if ctx.ui:button(ctx.i18n:get('equalizer')) then
                messageBox:add('equalizer')
                sidebarRoom:to('equalizer')
            end
        end
        sidebarRoom:addGroup(Gequalizer)
        homeGroup:addObject(navigation, 20)
    end,

    destroy = function()
        if homeGroup and navigation then homeGroup:deleteObject(navigation) end
        if sidebarRoom then
            if sidebarRoom.displayed_content == 'equalizer' then sidebarRoom:to('nil') end
            sidebarRoom:deleteGroup(Gequalizer)
        end
        sidebarRoom, homeGroup, navigation = nil, nil, nil
        ctx = nil
    end,
}
