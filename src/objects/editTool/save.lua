
local buttonSave = object:new('save')
buttonSave.sound = love.audio.newSource('assets/sound/save.ogg', "stream")
buttonSave.time = 0 --保存时间
buttonSave.type = 'button'
buttonSave.text = 'save'
buttonSave.img = isImage.save

function buttonSave:click(isAutoSave)
    if isAutoSave then
        messageBox:add("auto save")
        save(chart,"chart.json.auto")

    else
        save(chart,"chart.json")
        messageBox:add("save")
    end
    self.sound:seek(0)
    self.sound:play()
end

function buttonSave:keypressed(key)
    if input('save') then
        self:click()
    end
end

function buttonSave:update(dt)
    if elapsed_time - self.time >= 60 and (not demo.open) and settings.auto_save == 1 then --保存
        self.time = elapsed_time
        self:click(true)
        messageBox:add("auto_save")
    end
end

function buttonSave:quit()
    if love.window.showMessageBox( "save", i18n:get("save"),{'no','yes'} ) == 2 then
        self:click()
    end
end

return buttonSave