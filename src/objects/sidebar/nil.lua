--nil界面
local Gnil = group:new('nil')
Gnil.type = "nil"
function Gnil:Nui()
    if Nui:button(i18n:get("chart info")) then
        messageBox:add("chart info")
        sidebar:to("chart info")
    end
    if Nui:button(i18n:get("preference")) then
        messageBox:add("preference")
        sidebar:to("preference")
    end
    if Nui:button(i18n:get("settings")) then
        messageBox:add("settings")
        sidebar:to("settings")
    end
    if Nui:button(i18n:get("track")) then
        messageBox:add("track")
        sidebar:to("track")
    end
    if Nui:button(i18n:get("takana")) then
        messageBox:add("takana")
        sidebar:to("takana")
    end
    if Nui:button(i18n:get("dakumi")) then
        messageBox:add("dakumi")
        love.system.openURL(PATH.web.dakumi)
    end
    if Nui:button(i18n:get("github")) then
        messageBox:add("github")
        love.system.openURL(PATH.web.github)
    end
end

return Gnil