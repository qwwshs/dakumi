local eventEdit = object:new('eventEdit')
eventEdit.layout = require 'config.layouts.play'.edit
function eventEdit:keypressed(key)
    if not(mouse.y >= self.layout.y) then
        return
    end
    local isEdit = key == "e"
    local isDelete = key == "d"
    local isXEvent = math.intersect(mouse.x,mouse.x,self.layout.x + self.layout.interval,self.layout.x + self.layout.interval * 2)
    local isWEvent = math.intersect(mouse.x,mouse.x,self.layout.x + self.layout.interval * 2,self.layout.x + self.layout.interval * 3)
    if isEdit and isXEvent then
       fEvent:place("x",mouse.y)
        messageBox:add("event x place")
    elseif isEdit and isWEvent then -- w
        fEvent:place("w",mouse.y)
        messageBox:add("event w place")
    elseif isDelete and isXEvent then -- x delete
            fEvent:delete("x",mouse.y)
            messageBox:add("event x place")
    elseif isDelete and misWEvent then -- w delete
            fEvent:delete("w",mouse.y)
            messageBox:add("event w place")
    end
end

function eventEdit:mousepressed(x,y)
    if not(mouse.y >= self.layout.y) then
        return
    end
    local isXEvent = math.intersect(mouse.x,mouse.x,self.layout.x + self.layout.interval,self.layout.x + self.layout.interval * 2)
    local isWEvent = math.intersect(mouse.x,mouse.x,self.layout.x + self.layout.interval * 2,self.layout.x + self.layout.interval * 3)
    if isXEvent then
        fEvent:click("x",mouse.y)
        messageBox:add("event x click")
    elseif isWEvent then
        fEvent:click("w",mouse.y)
        messageBox:add("event w click")
    end
end

return eventEdit