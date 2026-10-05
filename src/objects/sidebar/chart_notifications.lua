-- 界面响应谱面通知；服务层不读取侧栏状态。
return function(sidebar, Chart, bus)
    bus:on('chart:indices_changed', function(kind, mapping)
        local displayed = sidebar.displayed_content
        local expected = displayed == 'event' and Chart:isEditingEffect() and 'effect' or displayed
        if expected == kind and sidebar.incoming then
            local index = sidebar.incoming[1]
            if mapping[index] then sidebar.incoming[1] = mapping[index] end
        end
    end)
    bus:on('chart:group_edit_ending', function()
        if sidebar.displayed_content == 'event' then sidebar:to('event groups') end
    end)
    bus:on('chart:effect_edit_ending', function() sidebar:to('nil') end)
end
