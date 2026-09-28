--[[
    模块名: editTool/noteOptions
    描述: 将假 note、note 头和 wipe 头开关合并到一个 Nuklear group
]]

local noteOptions = object:new('noteOptions')
noteOptions.type = 'custom'
noteOptions.layout = require 'config.layouts.editTool'
noteOptions.controls = {
    require 'src.objects.editTool.noteFake',
    require 'src.objects.editTool.holdNoteHead',
    require 'src.objects.editTool.holdWipeHead',
}

function noteOptions:update(dt)
    for _, control in ipairs(self.controls) do
        control:update(dt)
    end
end

function noteOptions:Nui()
    if Nui:groupBegin('note_options', 'border') then
        Nui:layoutRow('dynamic', 20, 1)
        for _, control in ipairs(self.controls) do
            Nui:checkbox(i18n:get(control.text), control)
        end
        Nui:groupEnd()
    end
end

return noteOptions
