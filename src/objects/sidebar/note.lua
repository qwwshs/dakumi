--event界面
local Gnote = group:new('note')
Gnote.type = "note"
Gnote.layout = require 'config.layouts.sidebar'.note
Gnote.fakev = {value = true}
local meta_default_bezier = {
    __index ={
        {1,1,1,1}
    
    }
}

function Gnote:to(index)
    local v = chart.note[index]
    if v.fake == 1 then --因为Nui的开关 开和关 是反的
        self.fakev.value = false
    else
        self.fakev.value = true
    end
end

function Gnote:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:checkbox(i18n:get("note fake"), self.fakev)
    if not self.fakev.value then
        Nui:label(i18n:get("false"))
    else
        Nui:label(i18n:get("true"))
    end
end

function Gnote:NuiNext() --更新信息
    local v = chart.note[sidebar.incoming[1]]
    if self.fakev.value then
        v.fake = 0
    else
        v.fake = 1
    end
end

return Gnote
