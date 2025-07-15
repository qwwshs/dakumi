local speed = object:new('speed')
speed.speed = 1
speed.type = 'custom'
speed.text = 'speed'
speed.layout = require 'config.layouts.editTool'
speed.useToSpeed = {value = "1"}

function speed:Nui() --渲染
    if Nui:groupBegin(self.text,'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text))
        if Nui:button("",isImage.up) then
            self.speed = self.speed + 0.1
            self.useToSpeed.value = tostring(self.speed)
        end
        Nui:edit('field', self.useToSpeed)

        if Nui:button("",isImage.down) then
            self.speed = math.max(self.speed-0.1,0.1)
            self.useToSpeed.value = tostring(self.speed)
        end

        Nui:groupEnd()
    end
end

function speed:update(dt)
    if tonumber(self.useToSpeed.value) then
        self.speed = tonumber(self.useToSpeed.value)
    end
end

function speed:to(sp)
    self.speed = sp
    self.useToSpeed.value = tostring(sp)
end


return speed