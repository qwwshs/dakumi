local denom = object:new('denom')
local AudioService = require("src.services.audioService")
denom.scale = 1
denom.denom = 4
denom.type = 'custom'
denom.text = 'denom'
denom.text2 = 'scale'
denom.layout = require 'config.layouts.editTool'
denom.useToDenom = { value = "4" }
denom.useToScale = { value = "1" }
denom.usemouse_denom = false
denom.usemouse_scale = false
function denom:keypressed(key)
    if input('denomUp') then
        self:to('denom', self.denom + 1)
    elseif input('denomDown') then
        self:to('denom', math.max(self.denom - 1, 1))
    end
end

function denom:wheelmovedInEditTool(x, y)
    if self.usemouse_denom then
        if y > 0 then
            self:to('denom', self.denom + 1)
        elseif y < 0 then
            self:to('denom', math.max(self.denom - 1, 1))
        end
    end
    if self.usemouse_scale then
        if y > 0 then
            self:to('scale', self.scale + 0.1)
        elseif y < 0 then
            self:to('scale', math.max(self.scale - 0.1, 0.1))
        end
    end
end

function denom:wheelmovedInPlay(x, y)
    --beat更改
    local temp = settings.contact_roller     --临时数值
    if input('accelerate') then
        temp = temp * 4
    end
    if y > 0 then
        temp = temp / self.denom
    else
        temp = -temp / self.denom
    end

    local current = math.max(math.min(AudioService:getCurrentBeat() + temp, AudioService:getAllBeat()), 0)
    local min_denom = 0 -- 取最近的节拍分度。
    for i = 1, self.denom do
        if math.abs(current - (math.floor(current) + i / self.denom)) <
            math.abs(current - (math.floor(current) + min_denom / self.denom)) then
            min_denom = i
        end
    end
    AudioService:setCurrentBeat(math.floor(current) + min_denom / self.denom, {pause = true})
end

function denom:Nui() --渲染
    self.usemouse_denom = false
    self.usemouse_scale = false
    if Nui:groupBegin(self.text, 'border') then
        Nui:layoutRow('dynamic', self.layout.groupRowH, 2)
        Nui:label(i18n:get(self.text))
        if ui:imageButton(isImage.up) then
            self.denom = self.denom + 1
            self.useToDenom.value = tostring(self.denom)
        end
        local active, changed = ui:edit('field', self.useToDenom)
        if active == 'active' then
            mouse.cursor = 'sizens'
            if iskeyboard['ctrl'] then
                self.usemouse_denom = true
            end
        end
        if ui:imageButton(isImage.down) then
            self.denom = math.max(self.denom - 1, 1)
            self.useToDenom.value = tostring(self.denom)
        end

        Nui:groupEnd()
    end
    if Nui:groupBegin(self.text2, 'border') then
        Nui:layoutRow('dynamic', self.layout.groupRowH, 2)
        Nui:label(i18n:get(self.text2))
        if ui:imageButton(isImage.up) then
            self.scale = self.scale + 0.1
            self.useToScale.value = tostring(self.scale)
        end
        local active = ui:edit('field', self.useToScale)
        if active == 'active' then
            mouse.cursor = 'sizens'
            if iskeyboard['ctrl'] then
                self.usemouse_scale = true
            end
        end
        if ui:imageButton(isImage.down) then
            self.scale = math.max(self.scale - 0.1, 0.1)
            self.useToScale.value = tostring(self.scale)
        end

        Nui:groupEnd()
    end
end

function denom:update(dt)
    if tonumber(self.useToDenom.value) then
        self.denom = math.max(math.floor(tonumber(self.useToDenom.value)), 1)
    end
    if tonumber(self.useToScale.value) then
        self.scale = math.max(tonumber(self.useToScale.value), 0.1)
    end
end

function denom:to(type, num)
    if type == 'denom' then
        self.denom = num
        self.useToDenom.value = tostring(self.denom)
    elseif type == 'scale' then
        self.scale = num
        self.useToScale.value = tostring(self.scale)
    end
end

return denom
