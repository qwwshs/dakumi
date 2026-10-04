local editTool =  group:new('editTool')
editTool.layout = require 'config.layouts.editTool'
editTool.colors = require 'config.colors.editTool'

-- 每张谱面的编辑选项单独保存在同目录；专用扩展名避免被当成谱面导入。
local defaults = {
    denom = 4, scale = 1, track = 4, fence = 10, musicSpeed = 1,
    noteFake = false, holdNoteHead = false, holdWipeHead = false,
}

local function dataPath()
    local charts = menu and menu.chartInfo and menu.chartInfo.chart_name
    local chart = charts and charts[menu.selectChartPos]
    return chart and chart.path and (chart.path .. '.editToolData') or nil
end

local function currentData()
    return {
        denom = denom.denom, scale = denom.scale,
        track = track.track, fence = track.fence,
        musicSpeed = musicSpeed.speed,
        noteFake = noteFake.value,
        holdNoteHead = holdNoteHead.value,
        holdWipeHead = holdWipeHead.value,
    }
end

function editTool:saveData()
    if not self.dataPath then return end
    local ok, err = nativefs.write(self.dataPath, dkjson.encode(currentData(), {indent = true}))
    if not ok then log('editToolData save error: ' .. tostring(err)) end
end


function editTool:load()
    local nextPath = dataPath()
    if self.dataPath and self.dataPath ~= nextPath then self:saveData() end
    self('load')
    self.dataPath = nextPath
    if not self.dataPath then return end

    local content = nativefs.read(self.dataPath)
    local saved = content and dkjson.decode(content) or nil
    if content and type(saved) ~= 'table' then
        log('editToolData read error: ' .. self.dataPath)
    end
    saved = type(saved) == 'table' and saved or {}
    local data = {}
    for key, default in pairs(defaults) do
        if saved[key] == nil then
            data[key] = default
        else
            data[key] = saved[key]
        end
    end

    denom:to('denom', data.denom)
    denom:to('scale', data.scale)
    track:to('track', data.track)
    track:to('fence', data.fence)
    musicSpeed:to(data.musicSpeed)
    noteFake:to(data.noteFake)
    holdNoteHead:to(data.holdNoteHead)
    holdWipeHead:to(data.holdWipeHead)

    if not content then self:saveData() end
end

function editTool:update(dt)
    self('update',dt)
    
    if demo.open then return end
    if Nui:windowBegin('editTool', self.layout.x, self.layout.y, self.layout.w, self.layout.h,'border') then
        Nui:stylePush({ ['window'] = { ['group padding'] = { x = 4, y = 10 } } })
        Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
        for _,obj in ipairs(editTool.objects) do
            if obj.type == 'button' then
                goto button
            elseif obj.type == 'switch' then
                goto switch
            elseif obj.type == 'custom' then
                goto custom
            else
                goto ed
            end

            ::button::
            do
                local pressed
                if obj.img and obj.text == '' then
                    pressed = ui:imageButton(obj.img)
                else
                    pressed = Nui:button(i18n:get(obj.text), obj.img)
                end
                if pressed then obj:click() end
            end
            goto ed

            ::switch::
            Nui:checkbox(i18n:get(obj.text), obj)
            goto ed
            ::custom::
            obj:Nui(dt)
            goto ed
            ::ed::
        end

        Nui:stylePop()
        Nui:windowEnd()
    end

end

function editTool:draw()
    if demo.open then
        return
    end

    self('draw')


end

function editTool:keypressed(key)
    if demo.open then
        return
    end
    if tabs and tabs:isRenaming() then return end --标签页重命名时屏蔽快捷键
    if mouse.x >= self.layout.x + self.layout.w then return end
    self('keypressed',key)


end

function editTool:mousepressed( x, y, button, istouch, presses )
    if demo.open then
        return
    end
    self('mousepressed', x, y, button, istouch, presses )
end

function editTool:textinput(input)
    if demo.open then
        return
    end
    if tabs and tabs:isRenaming() then return end --标签页重命名时文本只交给输入框
    self('textinput',input)
end

function editTool:mousereleased( x, y, button, istouch, presses )
    if demo.open then
        return
    end
    
    self('mousereleased', x, y, button, istouch, presses )
end

function editTool:wheelmoved(x, y)
    if demo.open then
        return
    end
    if math.intersect(mouse.x,mouse.x,self.layout.x,self.layout.x + self.layout.w) and math.intersect(mouse.y,mouse.y,self.layout.y,self.layout.y + self.layout.h) then
        self("wheelmovedInEditTool",x, y)
    end
    if math.intersect(mouse.x,mouse.x,play.layout.x,play.layout.x + play.layout.w) and math.intersect(mouse.y,mouse.y,play.layout.y,play.layout.y + play.layout.h) then 
        self("wheelmovedInPlay",x, y) --有些控件需要更新play的属性
     end

end

function editTool:quit()
    self:saveData()
    self('quit')
end

editTool:addObject(require 'src.objects.editTool.save')
musicPlay = require 'src.objects.editTool.musicPlay'
editTool:addObject(musicPlay)
denom = require 'src.objects.editTool.denom'
editTool:addObject(denom)
track = require 'src.objects.editTool.track'
editTool:addObject(track) 
musicSpeed = require 'src.objects.editTool.musicSpeed'
editTool:addObject(musicSpeed)
noteFake = require 'src.objects.editTool.noteFake'
holdNoteHead = require 'src.objects.editTool.holdNoteHead'
holdWipeHead = require 'src.objects.editTool.holdWipeHead'
editTool:addObject(require 'src.objects.editTool.noteOptions')
editTool:addObject(require 'src.objects.editTool.effectMode')

return editTool
