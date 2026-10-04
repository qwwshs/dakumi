local eventEdit = object:new('eventEdit')
local ChartService = require('src.services.chartService')
eventEdit.layout = require 'config.layouts.play'.edit
function eventEdit:keypressed(key)
    if mouse.y < self.layout.y then
        return
    end
    local isEdit = input('placeEvent')
    local isGroup = not ChartService:isEditingEventGroup() and not ChartService:isEditingEffect() and input('placeEventGroup')
    local isDelete = input('delete')

    if tabs and not tabs:isSingle() then
        local ti, lane = tabs:getLane(mouse.x, mouse.y)
        if not lane or lane == 'note' then return end
        local tab = tabs.list[ti]
        if not tab.edit[lane] then return end
        local istrack = tabs:getTabTrack(tab)
        if isEdit or isGroup then
            fEvent:place(isGroup and 'event_group' or lane, mouse.y, istrack)
            messageBox:add("event " .. lane .. " place")
        elseif isDelete then
            fEvent:delete(lane, mouse.y, istrack)
            messageBox:add("event " .. lane .. " delete")
        end
        return
    end

    if (isEdit or isGroup) and trackSequence:getType(mouse.x) ~= 'note' and table.find(trackSequence,trackSequence:getType(mouse.x)) then
       fEvent:place(isGroup and 'event_group' or trackSequence:getType(mouse.x),mouse.y)
        messageBox:add("event " .. trackSequence:getType(mouse.x) .. " place")
    elseif isDelete and trackSequence:getType(mouse.x) then -- x delete
            fEvent:delete(trackSequence:getType(mouse.x),mouse.y)
            messageBox:add("event " .. trackSequence:getType(mouse.x) .. " delete")
    end
end

function eventEdit:mousepressed(x,y)
    if mouse.y < self.layout.y then
        return
    end
    if tabs and not tabs:isSingle() then
        local ti, lane = tabs:getLane(mouse.x, mouse.y)
        if not lane or lane == 'note' then return end
        local tab = tabs.list[ti]
        if not tab.edit[lane] then return end
        fEvent:click(lane, mouse.y, tabs:getTabTrack(tab))
        messageBox:add("event " .. lane .. " click")
        return
    end
    if trackSequence:getType(mouse.x) ~= 'note' and table.find(trackSequence,trackSequence:getType(mouse.x)) then
        fEvent:click(trackSequence:getType(mouse.x),mouse.y)
        messageBox:add("event " .. trackSequence:getType(mouse.x) .. " click")
    end
end

return eventEdit
