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
    if Nui:button(i18n:get("track")) then
        messageBox:add("track")
        sidebar:to("track")
    end
    if Nui:button(i18n:get("settings")) then
        messageBox:add("settings")
        sidebar:to("settings")
    end
    if Nui:button(i18n:get('event_group.title')) then
        sidebar:to('event groups')
    end
    -- 操作历史、均衡器、Takana 等入口由插件在此处按层号绘制。
    self('Nui')
end

-- 独立小窗口固定在侧边栏右下角，不受上方列表滚动位置影响。
function Gnil:NuiNext()
    if sidebar.displayed_content ~= 'nil' then return end
    local layout = sidebar.layout
    local links = layout.links
    local width = links.button * 2 + links.gap + links.padding * 2
    local height = links.button + links.padding * 2
    local x = layout.x + layout.w - width - links.margin
    local y = layout.y + layout.h - height - links.margin

    Nui:stylePush({['window'] = {
        ['background'] = '#00000000',
        ['fixed background'] = '#00000000',
        ['border color'] = '#00000000',
        ['padding'] = {x = links.padding, y = links.padding},
    }})
    local opened = Nui:windowBegin('sidebar-quick-links', x, y, width, height)
    if opened then
        Nui:layoutRow('dynamic', links.button, 2)
        if ui:imageButton(isImage.dakumi) then
            messageBox:add('dakumi')
            love.system.openURL(PATH.web.dakumi)
        end
        if Nui:widgetIsHovered() then Nui:tooltip(i18n:get('dakumi')) end
        if ui:imageButton(isImage.github) then
            messageBox:add('github')
            love.system.openURL(PATH.web.github)
        end
        if Nui:widgetIsHovered() then Nui:tooltip(i18n:get('github')) end
    end
    Nui:windowEnd()
    Nui:stylePop()
end

return Gnil
