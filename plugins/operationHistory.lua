--[[
    插件名: operationHistory
    描述: 在侧边栏显示可跳转的撤销/重做历史
]]

local sidebarRoom, homeGroup, panel, nav

local function formatBeat(value)
    if value == nil then return '?' end
    return string.format('%.8f', value):gsub('0+$', ''):gsub('%.$', '')
end

return {
    name = 'operationHistory',
    version = '1.0.0',
    description = '侧边栏操作历史',
    target = 'edit/sidebar',

    init = function(ctx)
        sidebarRoom = ctx.root:findContainer('edit/sidebar')
        homeGroup = sidebarRoom:getGroup('nil')
        panel = group:new('operation history')
        nav = object:new('operation history navigation')

        function nav:Nui()
            if ctx.ui:button(ctx.i18n:get('operation history')) then
                sidebarRoom:to('operation history')
            end
        end

        function panel:Nui()
            local history, cursor = {}, 0
            if redo then history, cursor = redo:getHistory() end
            ctx.ui:layoutRow('dynamic', 25, 1)
            ctx.ui:label(ctx.i18n:get('history.click_to_jump'))
            if #history == 0 then
                ctx.ui:label(ctx.i18n:get('history.empty'))
                return
            end

            ctx.ui:layoutRow('dynamic', 32, 1)
            local initialStatus = cursor == 0 and 'history.current' or 'history.before_first'
            if ctx.ui:button(ctx.i18n:get('history.initial') .. ' (' ..
                ctx.i18n:get(initialStatus) .. ')') then
                redo:jumpTo(0)
                return
            end

            for i, operation in ipairs(history) do
                ctx.ui:layoutRow('dynamic', 32, 1)
                local status = i == cursor and 'history.current' or
                    (i < cursor and 'history.applied' or 'history.undone')
                local title = i .. '. ' .. ctx.i18n:get(operation.action_key or 'history.other') ..
                    ' (' .. ctx.i18n:get(status) .. ')'
                if ctx.ui:button(title) then
                    redo:jumpTo(i)
                    return
                end
                ctx.ui:layoutRow('dynamic', 20, 1)
                local range = formatBeat(operation.beat_start) .. '–' .. formatBeat(operation.beat_end)
                ctx.ui:label('    ' .. ctx.i18n:get('history.beat_range') .. ': ' .. range)
            end
        end

        sidebarRoom:addGroup(panel)
        homeGroup:addObject(nav)
    end,

    destroy = function(ctx)
        if homeGroup and nav then homeGroup:deleteObject(nav) end
        if sidebarRoom and panel then
            if sidebarRoom.displayed_content == 'operation history' then
                sidebarRoom:to('nil')
            end
            sidebarRoom:deleteGroup(panel)
        end
        sidebarRoom, homeGroup, panel, nav = nil, nil, nil, nil
    end,
}
