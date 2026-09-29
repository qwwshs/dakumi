-- 读取设置文件
local SpectrogramConfig = require('src.services.spectrogramConfig')
local file = io.open(PATH.usersPath.settings .. 'settings.json', "r")
if file then
    settings = dkjson.decode(file:read("*a"))
    file:close()
end
if type(settings) ~= "table" then
    settings = {}
end
setmetatable(settings, meta_settings)

table.fill(settings, meta_settings.__index)
SpectrogramConfig.sanitize(settings)


--setting界面
local Gsettings = group:new('settings')
Gsettings.type = "settings"
Gsettings.layout = require('config.layouts.sidebar').settings

local default_trans_index = 1
if settings.default_trans_type == 'bezier' then
    default_trans_index = 2
end
--排版模式：属性，ui类型，后续内容combobox的选项，combobox的索引
Gsettings.setting_type = { --类型
    { 'hit',            "switch" },
    { 'hit_sound',      "switch" },
    { 'hit_volume',     "PercentageSlider" },
    { 'hit_time',       "edit" },
    { 'hit_light_time', "edit" },
    { '',               'separator' },
    { 'wavfrom',        "switch" },
    { 'spectrogram',    "switch" },
    { 'spectrogram_mode', 'combobox', {'transient', 'balanced', 'harmonics', 'bass'} },
    { 'spectrogram_window', 'combobox', {'hann', 'blackman_harris'} },
    { 'spectrogram_scale', 'combobox', {'pitch', 'log', 'linear'} },
    { 'spectrogram_min_hz', 'edit' },
    { 'spectrogram_max_hz', 'edit' },
    { 'spectrogram_floor_db', 'edit' },
    { 'spectrogram_ceiling_db', 'edit' },
    { 'spectrogram_gain_db', 'edit' },
    { 'spectrogram_opacity', 'PercentageSlider' },
    { 'spectrogram_ruler', 'switch' },
    { 'contact_roller', "edit" },
    { 'auto_save',      "switch" },
    { 'default_trans_type', "combobox", { 'easings', 'bezier' }, default_trans_index },
    {'beep_volume', "PercentageSlider"},
    { '',               'separator' },
    { 'bg_alpha',       "PercentageSlider" },
    { 'denom_alpha',    "PercentageSlider" },
    {'paste_preview_alpha', "PercentageSlider"},
    { '',               'separator' },
    { 'music_volume',   "PercentageSlider" },
    { 'track_w_scale',  "edit" },
    { 'note_height',    "edit" },
    { 'judge_line_y',   "edit" },
    { 'angle',          "edit" },
    { '',               'separator' },
    { 'window_width',   "edit" },
    { 'window_height',  "edit" },
    { '',               'separator' },
    { 'language',       "combobox",        i18n:get_languages_table(), i18n:get_now_language_in_table(settings.language) },
    { 'theme',           "combobox",        { 'dark', 'light' }, settings.theme == 'light' and 2 or 1 },
}
for i, v in ipairs(Gsettings.setting_type) do
    if v[2] == "edit" then
        v.value = tostring(settings[v[1]])
    elseif v[2] == "switch" then
        v.value = settings[v[1]]
    elseif v[2] == "combobox" then
        v.items = v[3]
        v.value = v[4] or 1
        if v[1]:match('^spectrogram_') then
            for index, item in ipairs(v.items) do if item == settings[v[1]] then v.value = index end end
        end
    elseif v[2] == "PercentageSlider" then --百分比滑块
        v.value = settings[v[1]]
    end
end

-- 声纹图即时预览；频率尺修改范围后，设置框也应同步，不能在保存时覆盖回旧值。
local function syncSpectrogramField(v)
    local value = settings[v[1]]
    if v.externalValue == value then return end
    if v[2] == 'edit' then
        v.value = type(value) == 'number' and string.format('%.8g', value) or tostring(value)
    elseif v[2] == 'combobox' then
        for index, item in ipairs(v.items) do if item == value then v.value = index end end
    else v.value = value end
    v.externalValue = value
end

function Gsettings:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    for i, v in ipairs(self.setting_type) do
        local spectral = v[1] == 'spectrogram' or v[1]:match('^spectrogram_')
        if spectral then syncSpectrogramField(v) end
        if not v[1]:match('^spectrogram_') or settings.spectrogram == 1 then
            if v[1] ~= "" then
                Nui:label(i18n:get(v[1]))
            end
            if v[2] == "edit" then
                ui:edit('field', v)

            elseif v[2] == "switch" then
                local temp = Nui:checkbox('',v.value == 1)
                if temp then
                    v.value = 1
                else
                    v.value = 0
                end
            elseif v[2] == "combobox" then
                if v[1] == 'theme' then
                    Nui:combobox(v, { i18n:get('dark'), i18n:get('light') })
                elseif spectral then
                    local labels = {}
                    for index, item in ipairs(v.items) do labels[index] = i18n:get('spectrogram_choice_' .. item) end
                    Nui:combobox(v, labels)
                else
                    Nui:combobox(v, v.items)
                end

            elseif v[2] == "PercentageSlider" then
                Nui:slider(0, v, 100, 1)

            elseif v[2] == "separator" then
                -- 获取当前widget的边界
                Nui:layoutRow('dynamic', 1, 1)
                local x, y, width, height = Nui:widgetBounds()
                -- 绘制水平线
                Nui:rectMultiColor(x, y, width, 2, '#333333', '#333333', '#333333', '#333333')
                Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
            end
            if spectral then
                local value = v.value
                if v[2] == 'edit' then value = tonumber(value)
                elseif v[2] == 'combobox' then value = v.items[value] end
                if value ~= nil then settings[v[1]] = value end
                v.externalValue = settings[v[1]]
            end
        end
    end

    if ui:tip(i18n:get('save')) then
        for i, v in ipairs(self.setting_type) do
            if v[2] == "switch" then
                settings[v[1]] = v.value
            elseif v[2] == "combobox" then
                settings[v[1]] = v.items[v.value]
            elseif v[2] == "PercentageSlider" then
                settings[v[1]] = v.value
            elseif v[2] == "edit" then
                settings[v[1]] = tonumber(v.value) or 0
            end
        end
        SpectrogramConfig.sanitize(settings)
        for _, v in ipairs(self.setting_type) do
            if v[1]:match('^spectrogram_') then syncSpectrogramField(v) end
        end
        if setUiTheme then setUiTheme(settings.theme) end
        save(dkjson.encode(settings, { indent = true }), PATH.usersPath.settings .. 'settings.json')
        room('settings')
    end
end

return Gsettings
