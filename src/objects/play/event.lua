local eventEdit = object:new('eventEdit')
eventEdit.layout = require 'config.layouts.play'.edit
function eventEdit:keypressed(key)
    if not(mouse.y >= self.layout.y) then
        return
    end
    local isEdit = input('placeEvent')
    local isDelete = input('delete')

    if isEdit and trackSequence:getType(mouse.x) ~= 'note' and table.find(trackSequence,trackSequence:getType(mouse.x)) then
       fEvent:place(trackSequence:getType(mouse.x),mouse.y)
        messageBox:add("event " .. trackSequence:getType(mouse.x) .. " place")
    elseif isDelete and trackSequence:getType(mouse.x) then -- x delete
            fEvent:delete(trackSequence:getType(mouse.x),mouse.y)
            messageBox:add("event " .. trackSequence:getType(mouse.x) .. " delete")
    end
end

function eventEdit:mousepressed(x,y)
    if not(mouse.y >= self.layout.y) then
        return
    end
    if trackSequence:getType(mouse.x) ~= 'note' and table.find(trackSequence,trackSequence:getType(mouse.x)) then
        fEvent:click(trackSequence:getType(mouse.x),mouse.y)
        messageBox:add("event " .. trackSequence:getType(mouse.x) .. " click")
    end
end

return eventEdit