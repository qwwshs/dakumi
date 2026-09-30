--note界面
local ChartService = require("src.services.chartService")
local Gnote = group:new('note')
Gnote.type = "note"
Gnote.layout = require 'config.layouts.sidebar'.note
Gnote.fakev = {value = false}
Gnote.noteHeadv = {value = false}
Gnote.wipeHeadv = {value = false}
function Gnote:to(index)
    local v = ChartService:getNote(index)
    if v:isFakeNote() then --因为Nui的开关 开和关 是反的
        self.fakev.value = true
    else
        self.fakev.value = false
    end
    if v:isHold() then
        if v:getNoteHead() == 1 then
            self.noteHeadv.value = true
        else
            self.noteHeadv.value = false
        end
        if v:getWipeHead() == 1 then
            self.wipeHeadv.value = true
        else
            self.wipeHeadv.value = false
        end
    end
end

function Gnote:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:checkbox(i18n:get("note fake"), self.fakev)
    if self.fakev.value then
        Nui:label(i18n:get("false"))
    else
        Nui:label(i18n:get("true"))
    end
    if ChartService:getNote(sidebar.incoming[1]):isHold() then
        Nui:checkbox(i18n:get("note head"), self.noteHeadv)
        if self.noteHeadv.value then
            Nui:label(i18n:get("apply"))
        else
            Nui:label(i18n:get("not apply"))
        end
        Nui:checkbox(i18n:get("wipe head"), self.wipeHeadv)
        if self.wipeHeadv.value then
            Nui:label(i18n:get("apply"))
        else
            Nui:label(i18n:get("not apply"))
        end
    end
end

function Gnote:NuiNext() --更新信息
    local v = ChartService:getNote(sidebar.incoming[1])
    if not v then return end
    -- 一次勾选更新的全部字段归入同一事务
    ChartService:change('history.edit_note', function()
        if self.fakev.value then
            v:setFake(1)
        else
            v:setFake(0)
        end
        if v:isHold() then
            if self.noteHeadv.value then
                v:setNoteHead(1)
            else
                v:setNoteHead(0)
            end
            if self.wipeHeadv.value then
                v:setWipeHead(1)
            else
                v:setWipeHead(0)
            end
        end
    end)
end

return Gnote
