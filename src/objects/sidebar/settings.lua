-- 读取设置文件
local file = io.open(PATH.usersPath.settings..'settings.json', "r")
if file then
    settings = dkjson.decode(file:read("*a"))
    file:close()
end
if type(settings) ~= "table" then
    settings = {}
end
setmetatable(settings,meta_settings)

table.fill(settings,meta_settings.__index)


--setting界面
local Gsettings = group:new('settings')
Gsettings.type = "settings"
Gsettings.layout = require('config.layouts.sidebar').settings

Gsettings.setting_type = { --输入类型
    {'judge_line_y',"edit"},
    {'music_volume',"edit"},
    {'hit_volume',"edit"},
    {'hit',"switch",1},
    {'hit_sound',"switch",1},
    {'track_w_scale',"edit"},
    {'language',"combobox",i18n:get_languages_table(),i18n:get_now_language_in_table(settings.language)},
    {'contact_roller',"edit"},
    {'note_height',"edit"},
    {'bg_alpha',"edit"},
    {'denom_alpha',"edit"},
    {'auto_save',"switch",1},
    {'window_width',"edit"},
    {'window_height',"edit"},
}
for i,v in ipairs(Gsettings.setting_type) do
    if v[2] == "edit" then
        v.value = tostring(settings[v[1]])
    elseif v[2] == "switch" then
        v.value = settings[v[1]]
    elseif v[2] == "combobox" then
        v.items = v[3]
        v.value = v[4]
    end
end

function Gsettings:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    for i,v in ipairs(self.setting_type) do
        Nui:label(i18n:get(v[1]))
        if v[2] == "edit" then
            Nui:edit('field',v)
        elseif v[2] == "switch" then
            Nui:slider(0,v, v[3], 1)
        elseif v[2] == "combobox" then
            Nui:combobox(v,v.items)
        end
    end

    if Nui:button(i18n:get('save')) then
        for i,v in ipairs(self.setting_type) do
            settings[v[1]] = tonumber(v.value) or 0
            --特殊处理
            if v[1] == "language" then
                settings[v[1]] = v.items[v.value]
            end
        end
        save(dkjson.encode(settings, { indent = true }),PATH.usersPath.settings..'settings.json')
    end
end

return Gsettings