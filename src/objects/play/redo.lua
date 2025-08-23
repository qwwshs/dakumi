local redo = {} -- 重做
local revoke = {} -- 撤销
object_redo = { --用于实现撤销和重做
    write_revoke = function(type,tab)
        redo = {}
        revoke[#revoke + 1] = {type=type,tab = tab}
    end,
    keyboard = function(key)
        if isctrl ~= true then
            return
        end
        if key == "z" and revoke[#revoke] ~= nil then --撤销上一步操作
            redo[#redo + 1] = revoke[#revoke]
            --type分类
            
            if  revoke[#revoke].type == "note place" then
                for i = 1, #chart.note do
                    if table.eq(chart.note[i],revoke[#revoke].tab) then
                        table.remove(chart.note,i)
                    end
                end
            elseif revoke[#revoke].type == "event place" then
                for i = 1, #chart.event do
                    if table.eq(chart.event[i],revoke[#revoke].tab) then
                        table.remove(chart.event,i)
                    end
                end
                sidebar.displayed_content = "nil"
            elseif revoke[#revoke].type == "note delete" then
                chart.note[#chart.note + 1] = table.copy(revoke[#revoke].tab)
                note:sort()
            elseif revoke[#revoke].type == "event delete" then
                chart.event[#chart.event + 1] = table.copy(revoke[#revoke].tab)
                event:sort()
            elseif revoke[#revoke].type == "copy delete" then

                for i = 1,#revoke[#revoke].tab.note do
                    chart.note[#chart.note + 1] = table.copy(revoke[#revoke].tab.note[i])
                end
                note:sort()

                for i = 1,#revoke[#revoke].tab.event do
                    chart.event[#chart.event + 1] = table.copy(revoke[#revoke].tab.event[i])
                end
                event:sort()

                sidebar.displayed_content = "nil"

            elseif revoke[#revoke].type == "copy" then

                local local_tab = {}
                for i = 1, #chart.note do
                    local no_have_this_note = true --表里没有这个note
                    for k = 1,#revoke[#revoke].tab.note do
                        if table.eq(chart.note[i],revoke[#revoke].tab.note[k]) then
                            no_have_this_note = false
                        end
                    end
                    if no_have_this_note == true then
                        local_tab[#local_tab + 1] = chart.note[i]
                    end
                end
                chart.note = table.copy(local_tab)
                note:sort()
                local_tab = {}
                for i = 1, #chart.event do
                    local no_have_this_event = true --表里没有这个event
                    for k = 1,#revoke[#revoke].tab.event do
                        if table.eq(chart.event[i],revoke[#revoke].tab.event[k]) then
                            no_have_this_event = false
                        end
                    end
                    if no_have_this_event == true then
                        local_tab[#local_tab + 1] = chart.event[i]
                    end
                end
                chart.event = table.copy(local_tab)
                event:sort()

                sidebar.displayed_content = "nil"

            elseif revoke[#revoke].type == "cropping" then --裁剪
                --先恢复 再删除
                for i = 1,#revoke[#revoke].tab[1].note do
                    chart.note[#chart.note + 1] = table.copy(revoke[#revoke].tab[1].note[i])
                end
                note:sort()
                for i = 1,#revoke[#revoke].tab[1].event do
                    chart.event[#chart.event + 1] = table.copy(revoke[#revoke].tab[1].event[i])
                end
                event:sort()

                local local_tab = {}
                for i = 1, #chart.note do
                    local no_have_this_note = true --表里没有这个note
                    for k = 1,#revoke[#revoke].tab[2].note do
                        if table.eq(chart.note[i],revoke[#revoke].tab[2].note[k]) then
                            no_have_this_note = false
                        end
                    end
                    if no_have_this_note == true then
                        local_tab[#local_tab + 1] = chart.note[i]
                    end
                end
                chart.note = table.copy(local_tab)
                note:sort()
                local_tab = {}
                for i = 1, #chart.event do
                    local no_have_this_event = true --表里没有这个event
                    for k = 1,#revoke[#revoke].tab[2].event do
                        if table.eq(chart.event[i],revoke[#revoke].tab[2].event[k]) then
                            no_have_this_event = false
                        end
                    end
                    if no_have_this_event == true then
                        local_tab[#local_tab + 1] = chart.event[i]
                    end
                end
                chart.event = table.copy(local_tab)
                event:sort()

                sidebar.displayed_content = "nil"
            end
            revoke[#revoke] = nil


        elseif key == "y" and redo[#redo] ~= nil then
            revoke[#revoke] = redo[#redo]
            if  redo[#redo].type == "note delete" then --重做 所以全部反过来的
                for i = 1, #chart.note do
                    if table.eq(chart.note[i],redo[#redo].tab) then
                        table.remove(chart.note,i)
                    end
                end
            elseif redo[#redo].type == "event delete" then
                for i = 1, #chart.event do
                    if table.eq(chart.event[i],redo[#redo].tab) then
                        table.remove(chart.event,i)
                    end
                end

                sidebar.displayed_content = "nil"
            elseif redo[#redo].type == "note place" then
                chart.note[#chart.note + 1] = table.copy(redo[#redo].tab)
                note:sort()
            elseif redo[#redo].type == "event place" then
                chart.event[#chart.event + 1] = table.copy(redo[#redo].tab)
                event:sort()

                sidebar.displayed_content = "nil"
            elseif redo[#redo].type == "copy delete" then
                local local_tab = {}
                for i = 1,#chart.note do
                    if not table.eq(redo[#redo].tab.note[1],chart.note[i]) then
                        local_tab[#local_tab + 1] = chart.note[i]
                    else 
                        table.remove(redo[#redo].tab.note,1)
                    end
                end
                chart.note = table.copy(local_tab)
                
                
                local_tab = {}
                for i = 1,#chart.event do
                    if not table.eq(redo[#redo].tab.event[1],chart.event[i]) then
                        local_tab[#local_tab + 1] = chart.event[i]
                    else 
                        table.remove(redo[#redo].tab.event,1)
                    end
                end
                sidebar.displayed_content = "nil"

            elseif redo[#redo].type == "copy" then

                for i = 1,#revoke[#revoke].tab.note do
                    chart.note[#chart.note + 1] = table.copy(revoke[#revoke].tab.note[i])
                end
                note:sort()
                for i = 1,#revoke[#revoke].tab.event do
                    chart.event[#chart.event + 1] = table.copy(revoke[#revoke].tab.event[i])
                end
                event:sort()
                sidebar.displayed_content = "nil"

            elseif redo[#redo].type == "cropping" then --裁剪
                --先恢复 再删除 --其实就是撤销的那个裁剪的两个表格反过来
                for i = 1,#revoke[#revoke].tab[2].note do
                    chart.note[#chart.note + 1] = table.copy(revoke[#revoke].tab[2].note[i])
                end
                note:sort()
                for i = 1,#revoke[#revoke].tab[2].event do
                    chart.event[#chart.event + 1] = table.copy(revoke[#revoke].tab[2].event[i])
                end
                event:sort()

                local local_tab = {}
                for i = 1, #chart.note do
                    local no_have_this_note = true --表里没有这个note
                    for k = 1,#revoke[#revoke].tab[1].note do
                        if table.eq(chart.note[i],revoke[#revoke].tab[1].note[k]) then
                            no_have_this_note = false
                        end
                    end
                    if no_have_this_note == true then
                        local_tab[#local_tab + 1] = chart.note[i]
                    end
                end
                chart.note = table.copy(local_tab)
                note:sort()
                local_tab = {}
                for i = 1, #chart.event do
                    local no_have_this_event = true --表里没有这个event
                    for k = 1,#revoke[#revoke].tab[1].event do
                        if table.eq(chart.event[i],revoke[#revoke].tab[1].event[k]) then
                            no_have_this_event = false
                        end
                    end
                    if no_have_this_event == true then
                        local_tab[#local_tab + 1] = chart.event[i]
                    end
                end
                chart.event = table.copy(local_tab)
                event:sort()

                sidebar.displayed_content = "nil"
            end
            redo[#redo] = nil
        end
    end
}