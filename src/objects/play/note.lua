local Onote = object:new('Onote') --避免重名
Onote.layout = require 'config.layouts.play'.edit
function Onote:keypressed(key)
    if not (math.intersect(mouse.x,mouse.x,self.layout.x,self.layout.x + self.layout.interval) and mouse.y >= self.layout.y) then 
        return
    end
    if key == "q" then -- note
        note:place("note",mouse.y)
        messageBox:add("note place")
        sidebar.displayed_content = 'nil'
    elseif key == "w" then --wipe
        note:place("wipe",mouse.y)
        messageBox:add("wipe place")
        sidebar.displayed_content = 'nil'
    elseif key == "e" then --hold
        hold_place = not hold_place
        note:place("hold",mouse.y)
        messageBox:add("hold place")
        sidebar.displayed_content = 'nil'
    elseif key == "d" then --delete
        note:delete(mouse.y)
        messageBox:add("note delete")
        sidebar.displayed_content = 'nil'
    end
end

function Onote:mousepressed(x,y,button)
    if  math.intersect(mouse.x,mouse.x,self.layout.x,self.layout.x + self.layout.interval) then -- 选择note
        local pos = note:click(mouse.y)
        if pos then
            sidebar:to('note',pos)
        else
            sidebar.displayed_content = 'nil'
        end
        messageBox:add("note click")
    end
end

return Onote