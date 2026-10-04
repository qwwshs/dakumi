local noteEdit = object:new('noteEdit') --避免重名
local ChartService = require('src.services.chartService')
noteEdit.layout = require 'config.layouts.play'
function noteEdit:keypressed(key)
    if ChartService:isEditingEventGroup() or ChartService:isEditingEffect() then return end
    if mouse.y < self.layout.y then
        return
    end
    local istrack = track.track
    if tabs and not tabs:isSingle() then
        local ti, lane = tabs:getLane(mouse.x, mouse.y)
        if lane ~= 'note' then return end
        local tab = tabs.list[ti]
        if not tab.edit.note then return end
        istrack = tabs:getTabTrack(tab)
    else
        if not (trackSequence:getType(mouse.x) == 'note' or
            math.intersect(mouse.x, mouse.x, self.layout.demo.x, self.layout.demo.x + self.layout.demo.w)) then
            return
        end
    end
    if input('placeNote') then -- note
        fNote:place("note", mouse.y, istrack)
        messageBox:add("note place")
        sidebar.displayed_content = 'nil'
    elseif input('placeWipe') then --wipe
        fNote:place("wipe", mouse.y, istrack)
        messageBox:add("wipe place")
        sidebar.displayed_content = 'nil'
    elseif input('placeHold') then --hold
        hold_place = not hold_place
        fNote:place("hold", mouse.y, istrack)
        messageBox:add("hold place")
        sidebar.displayed_content = 'nil'
    elseif input('delete') then --delete
        fNote:delete(mouse.y, istrack)
        messageBox:add("note delete")
        sidebar.displayed_content = 'nil'
    end
end

function noteEdit:mousepressed(x,y,button)
    if ChartService:isEditingEventGroup() or ChartService:isEditingEffect() then return end
    if tabs and not tabs:isSingle() then
        local ti, lane = tabs:getLane(mouse.x, mouse.y)
        if lane ~= 'note' then return end
        local tab = tabs.list[ti]
        if not tab.edit.note then return end
        if love.mouse.isDown(1) then -- 选择note 在edit区域
            local pos = fNote:click(mouse.y, tabs:getTabTrack(tab))
            if pos then
                sidebar:to('note',pos)
                messageBox:add("note click")
            else
                sidebar.displayed_content = 'nil'
            end
        end
        return
    end
    local track_l,track_r = trackSequence:getRange('note')
    if trackSequence:getType(mouse.x) == 'note' and love.mouse.isDown(1) then -- 选择note 在edit区域
        local pos = fNote:click(mouse.y)
        if pos then
            sidebar:to('note',pos)
            messageBox:add("note click")
        else
            sidebar.displayed_content = 'nil'
        end
    end
end

return noteEdit
