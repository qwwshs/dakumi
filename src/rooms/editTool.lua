local editTool =  group:new('editTool')
editTool.layout = require 'config.layouts.editTool'

editTool:addObject(require 'src.objects.editTool.save')
editTool:addObject(require 'src.objects.editTool.musicPlay')
denom = require 'src.objects.editTool.denom'
editTool:addObject(denom)
track = require 'src.objects.editTool.Track'
editTool:addObject(track) 
musicSpeed = require 'src.objects.editTool.musicSpeed'
editTool:addObject(musicSpeed)
noteFake = require 'src.objects.editTool.noteFake'
editTool:addObject(noteFake)
editTool:addObject(require 'src.objects.editTool.slider')
function editTool:load()
    self('load')

    object_note.load(info_to_load(info.edit_tool.note))
end

function editTool:update(dt)
    self('update',dt)


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
    if demo then
        return
    end

    self('draw')


end

function editTool:keypressed(key)
    if demo then
        return
    end
    self('keypressed',key)


end

function editTool:mousepressed( x, y, button, istouch, presses )
    if demo then
        return
    end
    self('mousepressed', x, y, button, istouch, presses )
end

function editTool:textinput(input)
    if demo then
        return
    end
    self('textinput',input)
end

function editTool:mousereleased( x, y, button, istouch, presses )
    if demo then
        return
    end
    self('mousereleased', x, y, button, istouch, presses )
end

function editTool:wheelmoved(x, y)
    if demo then
        return
    end
    self("wheelmoved",x, y)
end

function editTool:quit()
    self('quit')
end


return editTool