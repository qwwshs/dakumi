local noteEdit = object:new('noteEdit') --避免重名
noteEdit.layout = require 'config.layouts.play'
function noteEdit:keypressed(key)
    local track_l,track_r = trackSequence:getRange('note')
    if not ((math.intersect(mouse.x,mouse.x,track_l,track_r) or
         math.intersect(mouse.x,mouse.x,self.layout.demo.x,self.layout.demo.x + self.layout.demo.w)) and mouse.y >= self.layout.y) then 
        return
    end
    if input('placeNote') then -- note
        fNote:place("note",mouse.y)
        messageBox:add("note place")
        sidebar.displayed_content = 'nil'
    elseif input('placeWipe') then --wipe
        fNote:place("wipe",mouse.y)
        messageBox:add("wipe place")
        sidebar.displayed_content = 'nil'
    elseif input('placeHold') then --hold
        hold_place = not hold_place
        fNote:place("hold",mouse.y)
        messageBox:add("hold place")
        sidebar.displayed_content = 'nil'
    elseif input('delete') then --delete
        fNote:delete(mouse.y)
        messageBox:add("note delete")
        sidebar.displayed_content = 'nil'
    end
end

function noteEdit:mousepressed(x,y,button)
    local track_l,track_r = trackSequence:getRange('note')
    if math.intersect(mouse.x,mouse.x,track_l,track_r) and love.mouse.isDown(1) then -- 选择note 在edit区域
        local pos = fNote:click(mouse.y)
        if pos then
            sidebar:to('note',pos)
        else
            sidebar.displayed_content = 'nil'
        end
        messageBox:add("note click")
    end
end

return noteEdit