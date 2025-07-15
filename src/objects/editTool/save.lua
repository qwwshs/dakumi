
local buttonSave = object:new('save')

buttonSave.time = 0 --保存时间
buttonSave.type = 'button'
buttonSave.text = 'save'
buttonSave.img = isImage.save

function buttonSave:click()
    save(chart,"chart.json")
    messageBox:add("save")
end

function buttonSave:keypressed(key)
    if key == "s" and isctrl then
        self:click()
    end
end

function buttonSave:update(dt)
    if elapsed_time - self.time >= 114 and (not demo) and settings.auto_save == 1 then --保存
        self.time = elapsed_time
        self:click()
        messageBox:add("auto_save")
    end
end

function buttonSave:quit()
    if love.window.showMessageBox( "save", i18n:get("save"),{'no','yes'} ) == 2 then
        self:click()
    end
end

return buttonSave