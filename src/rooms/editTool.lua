local editTool =  group:new('editTool')
editTool.layout = require 'config.layouts.editTool'

editTool:addObject(require 'src.objects.editTool.save')
musicPlay = require 'src.objects.editTool.musicPlay'
editTool:addObject(musicPlay)
denom = require 'src.objects.editTool.denom'
editTool:addObject(denom)
track = require 'src.objects.editTool.Track'
editTool:addObject(track) 
musicSpeed = require 'src.objects.editTool.musicSpeed'
editTool:addObject(musicSpeed)
noteFake = require 'src.objects.editTool.noteFake'
editTool:addObject(noteFake)
holdNoteHead = require 'src.objects.editTool.holdNoteHead'
editTool:addObject(holdNoteHead)
holdWipeHead = require 'src.objects.editTool.holdWipeHead'
editTool:addObject(holdWipeHead)
editTool:addObject(require 'src.objects.editTool.slider')

function editTool:load()
    self('load')
    local editToolDataFile = io.open('editToolData.json')
    if editToolDataFile then
        local editToolData = dkjson.decode(editToolDataFile:read('*a')) or {}
        editToolDataFile:close()
        editToolData.denom = editToolData.denom or denom.denom
        editToolData.scale = editToolData.scale or denom.scale
        editToolData.track = editToolData.track or track.track
        editToolData.fence = editToolData.fence or track.fence
        editToolData.musicSpeed = editToolData.musicSpeed or musicSpeed.speed
        if editToolData.noteFake == nil then
            editToolData.noteFake = noteFake.value
        end
        if editToolData.holdNoteHead == nil then
            editToolData.holdNoteHead = holdNoteHead.value
        end
        if editToolData.holdWipeHead == nil then
            editToolData.holdWipeHead = holdWipeHead.value
        end

        denom:to('denom',editToolData.denom)
        denom:to('scale',editToolData.scale)
        track:to('track',editToolData.track)
        track:to('fence',editToolData.fence)
        musicSpeed:to(editToolData.musicSpeed)
        noteFake:to(editToolData.noteFake)
        holdNoteHead:to(editToolData.holdNoteHead)
        holdWipeHead:to(editToolData.holdWipeHead)
    end
end

function editTool:update(dt)
    self('update',dt)
    
    if demo.open then return end
    if Nui:windowBegin('editTool', self.layout.x, self.layout.y, self.layout.w, self.layout.h,'border') then
        Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
        local isbutton = editTool:getAllTypeObject('button')
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
            if Nui:button(i18n:get(obj.text),obj.img) then
                obj:click()
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
    if mouse.x >= self.layout.x + self.layout.w then return end
    self("wheelmoved",x, y)
end

function editTool:quit()
    local editToolData = {
        denom = denom.denom,
        scale = denom.scale,
        track = track.track,
        fence = track.fence,
        musicSpeed = musicSpeed.speed,
        noteFake = noteFake.value,
        holdNoteHead = holdNoteHead.value,
        holdWipeHead = holdWipeHead.value,
    }
    save(dkjson.encode(editToolData),'editToolData.json')
    self('quit')
end


return editTool