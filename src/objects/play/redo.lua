local redo = object:new('redo')
redo.revoke = {} -- 撤销
redo.redo = {} -- 重做
function redo:writeRevoke(tab,istype)
    local revoke_tab = table.copy(tab)
    if tab.type then --为单个note或event
        revoke_tab = {
            add = {
                event = {},
                note = {}
            },
            del = {
                event = {},
                note = {}
            }
        }
        if tab.type == 'x' or tab.type == 'w' then
            if istype == 'add' then
                table.insert(revoke_tab.add.event, table.copy(tab))
            elseif istype == 'del' then
                table.insert(revoke_tab.del.event, table.copy(tab))
            end
        elseif tab.type == 'note' or tab.type == 'hold' or tab.type == 'wipe' then
            if istype == 'add' then
                table.insert(revoke_tab.add.note, table.copy(tab))
            elseif istype == 'del' then
                table.insert(revoke_tab.del.note, table.copy(tab))
            end
        end
    end
    self.redo = {}
    table.insert(self.revoke, revoke_tab)
end
--所有写入的tab类型有
--copy与 copydelete写法为 {note={...},event={...}}
function redo:keypressed(key)

    if input('undo') and self.revoke[#self.revoke] then --撤销上一步操作
        self.redo[#self.redo + 1] = self.revoke[#self.revoke]
        
        for _,note in ipairs(self.revoke[#self.revoke].del.note) do
            table.insert(chart.note, table.copy(note))
        end
        for _,event in ipairs(self.revoke[#self.revoke].del.event) do
            table.insert(chart.event, table.copy(event))
        end
        for _,note in ipairs(self.revoke[#self.revoke].add.note) do
            for i = 1, #chart.note do
                if table.eq(chart.note[i], note) then
                    table.remove(chart.note, i)
                    break
                end
            end
        end
        for _,event in ipairs(self.revoke[#self.revoke].add.event) do
            for i = 1, #chart.event do
                if table.eq(chart.event[i], event) then
                    table.remove(chart.event, i)
                    break
                end
            end
        end
        fNote:sort()
        fEvent:sort()
            
        sidebar:to("nil")

        table.remove(self.revoke)

    elseif input('redoing') and self.redo[#self.redo] then --重做上一步操作
        self.revoke[#self.revoke] = self.redo[#self.redo]
        
        for _,note in ipairs(self.revoke[#self.revoke].add.note) do
            table.insert(chart.note, table.copy(note))
        end
        for _,event in ipairs(self.revoke[#self.revoke].add.event) do
            table.insert(chart.event, table.copy(event))
        end
        for _,note in ipairs(self.revoke[#self.revoke].del.note) do
            for i = 1, #chart.note do
                if table.eq(chart.note[i], note) then
                    table.remove(chart.note, i)
                    break
                end
            end
        end
        for _,event in ipairs(self.revoke[#self.revoke].del.event) do
            for i = 1, #chart.event do
                if table.eq(chart.event[i], event) then
                    table.remove(chart.event, i)
                    break
                end
            end
        end
        fNote:sort()
        fEvent:sort()
            
        sidebar:to("nil")

        table.remove(self.redo)
    end
end

return redo