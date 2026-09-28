
local buttonSave = object:new('save')
local ChartService = require("src.services.chartService")
buttonSave.sound = love.audio.newSource('assets/sound/save.ogg', "stream")
buttonSave.time = 0 --保存时间
buttonSave.type = 'button'
buttonSave.text = ''
buttonSave.img = isImage.save
function buttonSave:click(isAutoSave)
    if isAutoSave then
        if not ChartService:save("chart.json.auto") then
            messageBox:add('event_group.invalid')
            return false
        end
        messageBox:add("auto save")

    else
        if not ChartService:save("chart.json") then
            messageBox:add('event_group.invalid')
            return false
        end
        messageBox:add("save")
    end
    self.sound:setVolume(settings.beep_volume / 100)
    self.sound:seek(0)
    self.sound:play()
end

function buttonSave:keypressed(key)
    if input('save') then
        self:click()
    end
end

function buttonSave:update(dt)
    if elapsed_time - self.time >= 60 and (not demo.open) and settings.auto_save == 1 and not table.find(arg,'--test') then --保存
        self.time = elapsed_time
        if self:click(true) ~= false then messageBox:add("auto_save") end
    end
    if elapsed_time - self.time >= 60 and (not demo.open) and settings.auto_save == 1 and table.find(arg,'--test') then
        print('in test')
        self.time = elapsed_time
    end
end

function buttonSave:quit()
    if love.window.showMessageBox( "save", i18n:get("save"),{'no','yes'} ) == 2 then
        self:click()
    end
end

return buttonSave
