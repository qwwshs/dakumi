--nil界面
local Gnil = group:new('nil')
Gnil.type = "nil"
function Gnil:Nui()
    if Nui:button(i18n:get("info")) then
        messageBox:add("info")
        sidebar.displayed_content = "info"
        object_chart_info.load(1250,100,0,150,50)
    end
    if Nui:button(i18n:get("preference")) then
        messageBox:add("preference")
        sidebar.displayed_content = "preference"
        object_preference.load(1250,100,0,150,50)
    end
    if Nui:button(i18n:get("settings")) then
        messageBox:add("settings")
        sidebar.displayed_content = "settings"
    end
    if Nui:button(i18n:get("track")) then
        messageBox:add("track")
        sidebar.displayed_content = "track"
    end
    if Nui:button(i18n:get("tracks_edit")) then
        messageBox:add("tracks_edit")
        sidebar.displayed_content = "tracks_edit"
        room_pos = "tracks_edit"
        object_tracks_edit.load(1250,0,0,400,WINDOW.h)
    end
    if Nui:button(i18n:get("dakumi")) then
        messageBox:add("dakumi")
        love.system.openURL("https://dakumi.qwwshs.top")
    end
    if Nui:button(i18n:get("github")) then
        messageBox:add("github")
        love.system.openURL("https://github.com/qwwshs/daikumi/")
    end
end

return Gnil