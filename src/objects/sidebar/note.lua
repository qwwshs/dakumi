--note界面
local Gnote = group:new('note')
Gnote.type = "note"
Gnote.layout = require 'config.layouts.sidebar'.note
Gnote.fakev = {value = false}
Gnote.noteHeadv = {value = false}
Gnote.wipeHeadv = {value = false}
function Gnote:to(index)
    local v = chart.note[index]
    if v.fake == 1 then --因为Nui的开关 开和关 是反的
        self.fakev.value = true
    else
        self.fakev.value = false
    end
    if v.type == 'hold' then
        if v.note_head == 1 then
            self.noteHeadv.value = true
        else
            self.noteHeadv.value = false
        end
        if v.wipe_head == 1 then
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
        v.fake = 1
    else
        v.fake = 0
    end
    if v.type == 'hold' then
        if self.noteHeadv.value then
            v.note_head = 1
        else
            v.note_head = 0
        end
        if self.wipeHeadv.value then
            v.wipe_head = 1
        else
            v.wipe_head = 0
        end
    end
end

return Gnote
