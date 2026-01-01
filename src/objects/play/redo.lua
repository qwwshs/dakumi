local redo = object:new('redo')
redo.revoke = {} -- 撤销
redo.redo = {} -- 重做
function redo:writeRevoke(type,tab)
    self.redo = {}
    self.revoke[#self.revoke + 1] = {type=type,tab = tab}
end
function redo:keypressed(key)
    if not iskeyboard.ctrl then
        return
    end
    if input('undo') and self.revoke[#self.revoke] ~= nil then --撤销上一步操作
        self.redo[#redo + 1] = self.revoke[#self.revoke]
        --type分类
            
        if  self.revoke[#self.revoke].type == "note place" then
            for i = 1, #chart.note do
                if table.eq(chart.note[i],self.revoke[#self.revoke].tab) then
                    table.remove(chart.note,i)
                end
            end
         elseif self.revoke[#self.revoke].type == "event place" then
            for i = 1, #chart.event do
                if table.eq(chart.event[i],self.revoke[#self.revoke].tab) then
                    table.remove(chart.event,i)
                end
            end
           sidebar:to("nil")
        elseif self.revoke[#self.revoke].type == "note delete" then
            chart.note[#chart.note + 1] = table.copy(self.revoke[#self.revoke].tab)
            fNote:sort()
        elseif self.revoke[#self.revoke].type == "event delete" then
            chart.event[#chart.event + 1] = table.copy(self.revoke[#self.revoke].tab)
            fEvent:sort()
        elseif self.revoke[#self.revoke].type == "copy delete" then

            for i = 1,#self.revoke[#self.revoke].tab.note do
                chart.note[#chart.note + 1] = table.copy(self.revoke[#self.revoke].tab.note[i])
            end
            fNote:sort()

            for i = 1,#self.revoke[#self.revoke].tab.event do
                chart.event[#chart.event + 1] = table.copy(self.revoke[#self.revoke].tab.event[i])
            end
            fEvent:sort()

            sidebar:to("nil")

        elseif self.revoke[#self.revoke].type == "copy" then

            local local_tab = {}
            for i = 1, #chart.note do
                local no_have_this_note = true --表里没有这个note
                    for k = 1,#self.revoke[#self.revoke].tab.note do
                    if table.eq(chart.note[i],self.revoke[#self.revoke].tab.note[k]) then
                        no_have_this_note = false
                    end
                end
                if no_have_this_note then
                    local_tab[#local_tab + 1] = chart.note[i]
                end
            end
            chart.note = table.copy(local_tab)
            fNote:sort()
               local_tab = {}
            for i = 1, #chart.event do
                local no_have_this_event = true --表里没有这个event
                for k = 1,#self.revoke[#self.revoke].tab.event do
                    if table.eq(chart.event[i],self.revoke[#self.revoke].tab.event[k]) then
                        no_have_this_event = false
                    end
                end
                if no_have_this_event then
                    local_tab[#local_tab + 1] = chart.event[i]
                end
            end
            chart.event = table.copy(local_tab)
            fEvent:sort()

            sidebar:to("nil")

        elseif self.revoke[#self.revoke].type == "cropping" then --裁剪
            --先恢复 再删除
            for i = 1,#self.revoke[#self.revoke].tab[1].note do
                chart.note[#chart.note + 1] = table.copy(self.revoke[#self.revoke].tab[1].note[i])
            end
            fNote:sort()
            for i = 1,#self.revoke[#self.revoke].tab[1].event do
                chart.event[#chart.event + 1] = table.copy(self.revoke[#self.revoke].tab[1].event[i])
            end
            fEvent:sort()

            local local_tab = {}
            for i = 1, #chart.note do
                local no_have_this_note = true --表里没有这个note
                for k = 1,#self.revoke[#self.revoke].tab[2].note do
                    if table.eq(chart.note[i],self.revoke[#self.revoke].tab[2].note[k]) then
                        no_have_this_note = false
                    end
                end
                if no_have_this_note then
                    local_tab[#local_tab + 1] = chart.note[i]
                end
            end
            chart.note = table.copy(local_tab)
            fNote:sort()
            local_tab = {}
            for i = 1, #chart.event do
                local no_have_this_event = true --表里没有这个event
                for k = 1,#self.revoke[#self.revoke].tab[2].event do
                    if table.eq(chart.event[i],self.revoke[#self.revoke].tab[2].event[k]) then
                        no_have_this_event = false
                    end
                end
               if no_have_this_event then
                    local_tab[#local_tab + 1] = chart.event[i]
                end
            end
            chart.event = table.copy(local_tab)
            fEvent:sort()

            sidebar:to("nil")
        end
        self.revoke[#self.revoke] = nil


    elseif input('redoing') and self.redo[#self.redo] ~= nil then
        self.revoke[#self.revoke] = self.redo[#self.redo]
        if  self.redo[#self.redo].type == "note delete" then --重做 所以全部反过来的
            for i = 1, #chart.note do
                    if table.eq(chart.note[i],self.redo[#self.redo].tab) then
                    table.remove(chart.note,i)
                end
            end
        elseif self.redo[#self.redo].type == "event delete" then
            for i = 1, #chart.event do
                if table.eq(chart.event[i],self.redo[#self.redo].tab) then
                    table.remove(chart.event,i)
                end
            end

            sidebar:to("nil")
        elseif self.redo[#self.redo].type == "note place" then
            chart.note[#chart.note + 1] = table.copy(self.redo[#self.redo].tab)
            fNote:sort()
        elseif self.redo[#self.redo].type == "event place" then
            chart.event[#chart.event + 1] = table.copy(self.redo[#self.redo].tab)
            fEvent:sort()

            sidebar:to("nil")
        elseif self.redo[#self.redo].type == "copy delete" then
            local local_tab = {}
            for i = 1,#chart.note do
                if not table.eq(self.redo[#self.redo].tab.note[1],chart.note[i]) then
                    local_tab[#local_tab + 1] = chart.note[i]
                else 
                    table.remove(self.redo[#self.redo].tab.note,1)
                end
            end
            chart.note = table.copy(local_tab)
                
                
            local_tab = {}
            for i = 1,#chart.event do
                if not table.eq(self.redo[#self.redo].tab.event[1],chart.event[i]) then
                    local_tab[#local_tab + 1] = chart.event[i]
                else 
                    table.remove(self.redo[#self.redo].tab.event,1)
                end
            end
            sidebar:to("nil")

        elseif self.redo[#self.redo].type == "copy" then

            for i = 1,#self.revoke[#self.revoke].tab.note do
                chart.note[#chart.note + 1] = table.copy(self.revoke[#self.revoke].tab.note[i])
            end
            fNote:sort()
            for i = 1,#self.revoke[#self.revoke].tab.event do
                chart.event[#chart.event + 1] = table.copy(self.revoke[#self.revoke].tab.event[i])
            end
            fEvent:sort()
            sidebar:to("nil")

        elseif self.redo[#self.redo].type == "cropping" then --裁剪
            --先恢复 再删除 --其实就是撤销的那个裁剪的两个表格反过来
            for i = 1,#self.revoke[#self.revoke].tab[2].note do
                chart.note[#chart.note + 1] = table.copy(self.revoke[#self.revoke].tab[2].note[i])
            end
            fNote:sort()
            for i = 1,#self.revoke[#self.revoke].tab[2].event do
                chart.event[#chart.event + 1] = table.copy(self.revoke[#self.revoke].tab[2].event[i])
            end
            fEvent:sort()

            local local_tab = {}
            for i = 1, #chart.note do
                local no_have_this_note = true --表里没有这个note
                for k = 1,#self.revoke[#self.revoke].tab[1].note do
                    if table.eq(chart.note[i],self.revoke[#self.revoke].tab[1].note[k]) then
                        no_have_this_note = false
                    end
                end
                if no_have_this_note then
                    local_tab[#local_tab + 1] = chart.note[i]
                end
            end
            chart.note = table.copy(local_tab)
            fNote:sort()
            local_tab = {}
            for i = 1, #chart.event do
                local no_have_this_event = true --表里没有这个event
                for k = 1,#self.revoke[#self.revoke].tab[1].event do
                    if table.eq(chart.event[i],self.revoke[#self.revoke].tab[1].event[k]) then
                       no_have_this_event = false
                    end
                end
                if no_have_this_event then
                    local_tab[#local_tab + 1] = chart.event[i]
                end
            end
            chart.event = table.copy(local_tab)
            fEvent:sort()

            sidebar:to("nil")
        end
        self.redo[#self.redo] = nil
    end
end

return redo