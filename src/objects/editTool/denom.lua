local denom = object:new('denom')
denom.scale = 1
denom.denom = 4
denom.type = 'custom'
denom.text = 'denom'
denom.text2 = 'scale'
denom.layout = require 'config.layouts.editTool'
denom.useToDenom = {value = "4"}
denom.useToScale = {value = "1"}
function denom:keypressed(key)
    if key == "up" then
        denom.denom = denom.denom + 1
    elseif key == "down" then
        denom.denom = math.max(denom.denom-1,1)
    end
end

function denom:wheelmoved(x,y)
    if mouse.x > 1200 then  --限制范围
        return
    end
    --beat更改
        local temp = settings.contact_roller--临时数值

        if y > 0 then
            temp = temp/ denom.denom
        else
            temp = -temp/ denom.denom
        end

        beat.nowbeat = math.max(math.min(beat.nowbeat +temp,beat.allbeat),0)

        local min_denom = 0 --假设0最近
        for i = 1, denom.denom do --取分度 哪个近取哪个
            if math.abs(beat.nowbeat - (math.floor(beat.nowbeat) + i / denom.denom)) < math.abs(beat.nowbeat - (math.floor(beat.nowbeat) + min_denom / denom.denom)) then
                min_denom = i
            end
        end
        beat.nowbeat = math.floor(beat.nowbeat) + min_denom / denom.denom --更正位置

        time.nowtime = beat:toTime(chart.bpm_list,beat.nowbeat)
        music_play = false
end

function denom:Nui() --渲染
    if Nui:groupBegin(self.text,'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text))
        if Nui:button("",isImage.up) then
            denom.denom = denom.denom + 1
            self.useToDenom.value = tostring(denom.denom)
        end
        Nui:edit('field', self.useToDenom)

        if Nui:button("",isImage.down) then
            denom.denom = math.max(denom.denom-1,1)
            self.useToDenom.value = tostring(denom.denom)
        end

        Nui:groupEnd()
    end
    if Nui:groupBegin(self.text2,'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text2))
        if Nui:button("",isImage.up) then
            denom.scale = denom.scale + 0.1
            self.useToScale.value = tostring(denom.scale)
        end
        Nui:edit('field', self.useToScale)

        if Nui:button("",isImage.down) then
            denom.scale = math.max(denom.scale - 0.1,0.1)
            self.useToScale.value = tostring(denom.scale)
        end
        
        Nui:groupEnd()
    end
end

function denom:update(dt)
    if tonumber(self.useToDenom.value) then
        denom.denom = math.max(math.floor(tonumber(self.useToDenom.value)),1)
    end
    if tonumber(self.useToScale.value) then
        denom.scale = math.max(tonumber(self.useToScale.value),0.1)
    end
end

return denom
