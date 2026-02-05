--note界面
local Gnote = group:new('note')
Gnote.type = "note"
Gnote.layout = require 'config.layouts.sidebar'.note
Gnote.fakev = {value = true}
Gnote.noteHeadv = {value = true}
Gnote.wipeHeadv = {value = true}
function Gnote:to(index)
    local v = chart.note[index]
    if v.fake == 1 then --因为Nui的开关 开和关 是反的
        self.fakev.value = false
    else
        self.fakev.value = true
    end
    if v.type == 'hold' then
        if v.note_head == 1 then
            self.noteHeadv.value = false
        else
            self.noteHeadv.value = true
        end
        if v.wipe_head == 1 then
            self.wipeHeadv.value = false
        else
            self.wipeHeadv.value = true
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
    if chart.note[sidebar.incoming[1]].type == 'hold' then
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
    local v = chart.note[sidebar.incoming[1]]
    if self.fakev.value then
        v.fake = 0
    else
        v.fake = 1
    end
    if v.type == 'hold' then
        if self.noteHeadv.value then
            v.note_head = 0
        else
            v.note_head = 1
        end
        if self.wipeHeadv.value then
            v.wipe_head = 0
        else
            v.wipe_head = 1
        end
    end
end

return Gnote
