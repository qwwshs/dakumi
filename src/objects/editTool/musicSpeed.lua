local AudioService = require('src.services.audioService')
local speed = object:new('speed')
speed.speed = 1 -- 上次确认的界面值；实际播放速度由服务持有。
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
            self:to(self.speed + 0.1)
        end
        local active = ui:edit('field', self.useToSpeed)
        if active == 'active' then
            mouse.cursor = 'sizens'
            if iskeyboard['ctrl'] then
                self.usemouse = true
            end
        end
        if ui:imageButton(isImage.down) then
            self:to(math.max(self.speed - 0.1, 0.1))
        end

        Nui:groupEnd()
    end
end

function speed:update(dt)
    local value = tonumber(self.useToSpeed.value)
    if value and value ~= self.speed then
        self:to(value)
    elseif value and self.speed ~= AudioService:getRate() then
        -- 插件改变速度后同步显示，不用旧的输入值每帧覆盖服务。
        self:to(AudioService:getRate())
    end
end

function speed:to(sp)
    sp = math.max(tonumber(sp) or 1, 0.1)
    if not AudioService:setRate(sp) then return end
    self.speed = sp
    self.useToSpeed.value = tostring(sp)
end


return speed
