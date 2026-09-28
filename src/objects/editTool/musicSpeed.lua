local speed = object:new('speed')
speed.speed = 1
speed.type = 'custom'
speed.text = 'speed'
speed.layout = require 'config.layouts.editTool'
speed.useToSpeed = {value = "1"}
speed.usemouse = false

function speed:wheelmovedInEditTool(x, y)
    if self.usemouse then
        if y > 0 then
            self:to(self.speed+0.1)
        elseif y < 0 then
            self:to(math.max(self.speed-0.1,0.1))
        end
    end
end
function speed:Nui() --渲染
    self.usemouse = false
    if Nui:groupBegin(self.text,'border') then
        Nui:layoutRow('dynamic', self.layout.groupRowH, 2)
        Nui:label(i18n:get(self.text))
        if ui:imageButton(isImage.up) then
            self.speed = self.speed + 0.1
            self.useToSpeed.value = tostring(self.speed)
        end
        local active = ui:edit('field', self.useToSpeed)
        if active == 'active' then
            mouse.cursor = 'sizens'
            if iskeyboard['ctrl'] then
                self.usemouse = true
            end
        end
        if ui:imageButton(isImage.down) then
            self.speed = math.max(self.speed-0.1,0.1)
            self.useToSpeed.value = tostring(self.speed)
        end

        Nui:groupEnd()
    end
end

function speed:update(dt)
    if tonumber(self.useToSpeed.value) then
        self.speed = math.max(tonumber(self.useToSpeed.value),0.1)
    end
end

function speed:to(sp)
    self.speed = sp
    self.useToSpeed.value = tostring(sp)
end


return speed
