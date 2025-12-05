--note和event的复制粘贴
local ctrl = object:new('ctrl')
ctrl.mouse_start_pos = { x = 0, y = 0 } --鼠标按下的时候的x和y
ctrl.meta_copy_tab = {}
ctrl.copy_tab = {
    note = {},
    event = {},
    type = "", --类型是复制 还是裁剪
    pos = "",  --位置是游玩区域还是编辑区域
}
function ctrl:copy_sub(new_table, type)
    for i, v in ipairs(self.copy_tab[type]) do
        if table.eq(self.copy_tab[type][i], new_table) then
            table.remove(self.copy_tab[type], i)
        end
    end
end

function ctrl:copy_add(new_table, type)
    for i = 1, #self.copy_tab[type] do
        if table.eq(self.copy_tab[type][i], new_table) then --去重
            return
        end
    end
    self.copy_tab[type][#self.copy_tab[type] + 1] = new_table
    table.sort(self.copy_tab[type], function(a, b) return beat:get(a.beat) < beat:get(b.beat) end)
end

function ctrl:copy_exist(new_table, type)
    for i = 1, #self.copy_tab[type] do
        if table.eq(self.copy_tab[type][i], new_table) then --去重
            return true
        end
    end
    return false
end

function ctrl:get_copy()
    return self.copy_tab
end

function ctrl:draw()
    local note_h = settings.note_height --25 * denom.scale
    local note_w = play.layout.edit.noteW
    if love.mouse.isDown(1) then        --复制框
        love.graphics.setColor(0, 1, 1, 0.4)
        love.graphics.rectangle("fill", self.mouse_start_pos.x, self.mouse_start_pos.y,
            mouse.x - self.mouse_start_pos.x, mouse.y - self.mouse_start_pos.y)
        love.graphics.setColor(0, 1, 1, 1)
        love.graphics.rectangle("line", self.mouse_start_pos.x, self.mouse_start_pos.y,
            mouse.x - self.mouse_start_pos.x, mouse.y - self.mouse_start_pos.y)
    end
    if self.copy_tab.type ~= "x" then
        love.graphics.setColor(0, 1, 1, 0.5)
    else
        love.graphics.setColor(1, 1, 1, 0.5)
    end
    --对所选标记
    for i = 1, #self.copy_tab.note do
        local y = beat:toY(self.copy_tab.note[i].beat)
        local y2 = y - note_h
        if self.copy_tab.note[i].type == "hold" then
            y2 = beat:toY(self.copy_tab.note[i].beat2)
        end

        if self.copy_tab.note[i].track == track.track then
            if y > 0 - note_h and y2 < WINDOW.h + note_h then
                love.graphics.rectangle("fill", play.layout.edit.x, y2, note_w, y - y2)
            end
        end
    end
    if self.copy_tab.pos == "play" then
        local all_track_pos = play:get_all_track_pos()
        for i = 1, #self.copy_tab.note do
            local x, w = fTrack:to_play_track(all_track_pos[self.copy_tab.note[i].track].x,
                all_track_pos[self.copy_tab.note[i].track].w)

            local y = beat:toY(self.copy_tab.note[i].beat)
            local y2 = y
            if self.copy_tab.note[i].type == "hold" then
                y2 = beat:toY(self.copy_tab.note[i].beat2)
            end
            if y < 0 - note_h then break end                                                --超出范围
            if (not (y2 > settings.judge_line_y + note_h or y < 0 - note_h)) and (not (y > settings.judge_line_y and chart.note[i].fake == 1)) then
                if y ~= y2 and y > settings.judge_line_y then y = settings.judge_line_y end --hold头保持在线上

                if self.copy_tab.note[i].type ~= "hold" then
                    love.graphics.rectangle("fill", x, y - note_h, w, note_h)
                else --hold
                    love.graphics.rectangle("fill", x, y, w, y2 - y)
                end
            end
        end
    end
    for i = 1, #self.copy_tab.event do
        local y = beat:toY(self.copy_tab.event[i].beat)
        local y2 = beat:toY(self.copy_tab.event[i].beat2)
        local x_pos = play.layout.edit.x + play.layout.edit.interval
        if self.copy_tab.event[i].type == "w" then
            x_pos = play.layout.edit.x + play.layout.edit.interval * 2
        end

        if self.copy_tab.event[i].track == track.track then
            if math.intersect(y,y2,0 - note_h,WINDOW.h + note_h) then
                love.graphics.rectangle("fill", x_pos, y2, note_w, y - y2)
            end
        end
    end
end

function ctrl:mousepressed(x, y, button)
    if love.mouse.isDown(2) then                                                     --单选
        if math.intersect(x,x,play.layout.edit.x + play.layout.edit.interval,play.layout.edit.x + play.layout.edit.interval *2) then --event x
            if self:copy_exist(chart.event[fEvent:click("x", mouse.y)], "event") then --存在就取消勾选
                self:copy_sub(chart.event[fEvent:click("x", mouse.y)], "event")
            else
                self:copy_add(chart.event[fEvent:click("x", mouse.y)], "event")
            end
        elseif math.intersect(x,x,play.layout.edit.x + play.layout.edit.interval * 2,play.layout.edit.x + play.layout.edit.interval *3) then --event w
            if self:copy_exist(chart.event[fEvent:click("w", mouse.y)], "event") then --存在就取消勾选
                self:copy_sub(chart.event[fEvent:click("w", mouse.y)], "event")
            else
                self:copy_add(chart.event[fEvent:click("w", mouse.y)], "event")
            end
        elseif math.intersect(x,x,play.layout.edit.x,play.layout.edit.x + play.layout.edit.interval) then --note
            if self:copy_exist(chart.note[fNote:click(mouse.y)], "note") then --存在就取消勾选
                self:copy_sub(chart.note[fNote:click(mouse.y)], "note")
            else
                self:copy_add(chart.note[fNote:click(mouse.y)], "note")
            end
        end
        messageBox:add("add copy")

        if #self.copy_tab.event > 0 then
            sidebar:to('events')
        end
    end

    if love.mouse.isDown(1) then
        self.mouse_start_pos = { x = mouse.x, y = mouse.y }
    end
end

function ctrl:mousereleased(x, y)
    --松手＋shift确认选中
    if not ((iskeyboard.lshift or iskeyboard.rshift) and love.mouse.isDown(1)) then
        return
    end
    self.copy_tab = { note = {}, event = {} }
    local min_x = fTrack:to_play_track(fTrack:to_chart_track(math.min(x, self.mouse_start_pos.x)), 1)
    local max_x = fTrack:to_play_track(fTrack:to_chart_track(math.max(x, self.mouse_start_pos.x)), 1)
    local min_y_beat = beat:yToBeat(math.max(y, self.mouse_start_pos.y))
    local max_y_beat = beat:yToBeat(math.min(y, self.mouse_start_pos.y)) --这引擎y是向下增长的 服了 beat是向上增长的 所以要取反

    if not math.intersect(x,self.mouse_start_pos.x,play.layout.edit.x,play.layout.edit.x + play.layout.edit.interval*3) then                      --在play区域
        self.copy_tab.pos = 'play'
        --先for循环记录此刻在游玩区域的轨道
        local local_track = {}     --记录表
        for i = 1, #chart.event do --点击轨道进入轨道的编辑事件
            local track_x, track_w = fTrack:to_play_track(fEvent:get(chart.event[i].track, beat.nowbeat))
            if math.intersect(min_x,max_x,track_x,track_x + track_w) then
                local_track[chart.event[i].track] = true
            end
            if beat:get(chart.event[i].beat) > max_y_beat then
                break
            end
        end

        for i = 1, #chart.note do
            local isbeat = beat:get(chart.note[i].beat)
            local isbeat2 = isbeat
            if chart.note[i].type == 'hold' then
                isbeat2 = beat:get(chart.note[i].beat2)
            end

            if math.intersect(min_y_beat,max_y_beat,isbeat,isbeat2) and local_track[chart.note[i].track] then --这引擎y是向下增长的 服了
                self.copy_tab.note[#self.copy_tab.note + 1] = table.copy(chart.note[i])
            end
            if isbeat > max_y_beat then
                break
            end
        end

        for i = 1, #chart.event do --用于完全复制
            local isbeat = beat:get(chart.event[i].beat)
            local isbeat2 = beat:get(chart.event[i].beat2)
            if math.intersect(min_y_beat,max_y_beat,isbeat,isbeat2) and local_track[chart.event[i].track] then
                self.copy_tab.event[#self.copy_tab.event + 1] = table.copy(chart.event[i])
            end
            if beat:get(chart.event[i].beat) > max_y_beat then
                break
            end
        end

        return
    end
    
    if math.intersect(min_x,max_x,play.layout.edit.x,play.layout.edit.x + play.layout.edit.interval) then --在note轨道
        for i = 1, #chart.note do
            local isbeat = beat:get(chart.note[i].beat)
            local isbeat2 = isbeat
            if chart.note[i].type == 'hold' then
                isbeat2 = beat:get(chart.note[i].beat2)
            end

            if math.intersect(min_y_beat,max_y_beat,isbeat,isbeat2) and track.track == chart.note[i].track then --这引擎y是向下增长的 服了
                self.copy_tab.note[#self.copy_tab.note + 1] = table.copy(chart.note[i])
            end
            if isbeat > max_y_beat then
                break
            end
        end
    end

    if math.intersect(min_x,max_x,play.layout.edit.x + play.layout.edit.interval,play.layout.edit.x + play.layout.edit.interval * 3) then --在event轨道
        for i = 1, #chart.event do
            local event_x_min = play.layout.edit.x + play.layout.edit.interval
            local event_x_max = play.layout.edit.x + play.layout.edit.interval * 2
            if chart.event[i].type == "w" then
                event_x_min = play.layout.edit.x + play.layout.edit.interval * 2
                event_x_max = play.layout.edit.x + play.layout.edit.interval * 3
            end
            if math.intersect(min_x,max_x,event_x_min,event_x_max) then
                local isbeat = beat:get(chart.event[i].beat)
                local isbeat2 = beat:get(chart.event[i].beat2)
                if math.intersect(min_y_beat,max_y_beat,isbeat,isbeat2) and track.track == chart.event[i].track then
                    self.copy_tab.event[#self.copy_tab.event + 1] = table.copy(chart.event[i])
                end
            end
            if beat:get(chart.event[i].beat) > max_y_beat then
                break
            end
        end
    end
    if #self.copy_tab.event > 0 then
        sidebar:to('events')
    end
end

function ctrl:wheelmoved(x, y)
    --beat更改
    local temp = settings.contact_roller --临时数值

    music_play = false
    if y > 0 then
        temp = temp / denom.denom
    else
        temp = -temp / denom.denom
    end
    local y_beat = temp

    self.mouse_start_pos.y = self.mouse_start_pos.y + beat:toY(0) - beat:toY(y_beat)
end

function ctrl:keypressed(key)
    if (iskeyboard.lshift or iskeyboard.rshift) and mouse.down then
        self:mousereleased(mouse.x, mouse.y)
    end

    if not isctrl then
        return
    end
    if key == "c" then
        self.copy_tab.type = "c"
    elseif key == "x" then
        self.copy_tab.type = "x"
    elseif key == "d" then
        sidebar:to("nil")
        local local_tab = {}
        if self.copy_tab.pos ~= 'play' or (self.copy_tab.pos == 'play' and iskeyboard.a) then
            redo:writeRevoke("copy delete", table.copy(self.copy_tab))
        else
            redo:writeRevoke("copy delete", { note = table.copy(self.copy_tab.note), event = {} })
        end

        for i = 1, #chart.note do
            if not table.eq(self.copy_tab.note[1], chart.note[i]) then
                local_tab[#local_tab + 1] = chart.note[i]
            else
                table.remove(self.copy_tab.note, 1)
            end
        end
        chart.note = table.copy(local_tab)

        local_tab = {}
        if self.copy_tab.pos ~= 'play' or (self.copy_tab.pos == 'play' and iskeyboard.a) then     -- a完全复制
            for i = 1, #chart.event do
                if not table.eq(self.copy_tab.event[1], chart.event[i]) then
                    local_tab[#local_tab + 1] = chart.event[i]
                else
                    table.remove(self.copy_tab.event, 1)
                end
            end
            chart.event = table.copy(local_tab)
        end


        self.copy_tab = {
            note = {},
            event = {},
            type = "",     --类型是复制 还是裁剪
            pos = "",      --位置是游玩区域还是编辑区域
        }
    elseif key == "v" or key == "b" or key == "n" or key == "m" then
        local copy_tab2 = table.copy(self.copy_tab)
        --先对表进行处理
        local min_track
        if copy_tab2.note[1] then
            min_track = copy_tab2.note[1].track
        end
        if copy_tab2.event[1] then
            min_track = copy_tab2.event[1].track
        end
        for i = 1, #copy_tab2.note do
            if min_track > copy_tab2.note[i].track then
                min_track = copy_tab2.note[i].track
            end
        end
        for i = 1, #copy_tab2.event do
            if min_track > copy_tab2.event[i].track then
                min_track = copy_tab2.event[i].track
            end
        end

        sidebar:to("nil")
        local to_beat = beat:toNearby(beat:yToBeat(mouse.y))

        local frist_beat = { 0, 0, 4 }     --作为基准
        if self.copy_tab.note[1] and self.copy_tab.event[1] and beat:get(self.copy_tab.note[1].beat) <= beat:get(self.copy_tab.event[1].beat) then
            frist_beat = self.copy_tab.note[1].beat
        elseif self.copy_tab.note[1] and self.copy_tab.event[1] and beat:get(self.copy_tab.note[1].beat) > beat:get(self.copy_tab.event[1].beat) then
            frist_beat = self.copy_tab.event[1].beat
        elseif (not self.copy_tab.note[1]) and self.copy_tab.event[1] then
            frist_beat = self.copy_tab.event[1].beat
        elseif self.copy_tab.note[1] and (not self.copy_tab.event[1]) then
            frist_beat = self.copy_tab.note[1].beat
        end

        if self.copy_tab.note[1] and self.copy_tab.pos == 'play' and not iskeyboard.a then     --不完全复制
            frist_beat = self.copy_tab.note[1].beat
        end
        for i = 1, #copy_tab2.note do     --轨道修改
            if self.copy_tab.pos ~= 'play' then
                copy_tab2.note[i].track = track.track
            end
            copy_tab2.note[i].beat = beat:add(beat:sub(copy_tab2.note[i].beat, frist_beat), to_beat)
            if copy_tab2.note[i].type == "hold" then
                copy_tab2.note[i].beat2 = beat:add(beat:sub(copy_tab2.note[i].beat2, frist_beat), to_beat)
            end
            if key == "n" then     --对所有轨道增加
                local max_track = fTrack:track_get_max_track() + 1
                copy_tab2.note[i].track = max_track + copy_tab2.note[i].track - min_track
            end
        end
        for i = 1, #copy_tab2.event do
            if self.copy_tab.pos ~= 'play' then
                copy_tab2.event[i].track = track.track
            end
            copy_tab2.event[i].beat = beat:add(beat:sub(copy_tab2.event[i].beat, frist_beat), to_beat)
            copy_tab2.event[i].beat2 = beat:add(beat:sub(copy_tab2.event[i].beat2, frist_beat), to_beat)
            if key == "b" and copy_tab2.event[i].type == "x" then     --取反
                copy_tab2.event[i].from = 2*(chart.preference.x_offset + chart.preference.event_scale/2) - copy_tab2.event[i].from
                copy_tab2.event[i].to = 2*(chart.preference.x_offset + chart.preference.event_scale/2) - copy_tab2.event[i].to
            end
            if key == "n" then     --对所有轨道增加
                local max_track = fTrack:track_get_max_track() + 1
                copy_tab2.event[i].track = max_track + copy_tab2.event[i].track - min_track
            end
        end
        if key == "n" or key == "m" then
            local pos = 0     --鼠标所在位置
            pos = fTrack:track_get_near_fence_x()

            for i = 1, #copy_tab2.event do
                --处理一下位置
                if copy_tab2.event[i].type == "x" then
                    copy_tab2.event[i].to = copy_tab2.event[i].to - copy_tab2.event[i].from + pos
                    copy_tab2.event[i].from = pos
                end
            end
        end
        --写入谱面内
        for i = 1, #copy_tab2.note do
            chart.note[#chart.note + 1] = table.copy(copy_tab2.note[i])
        end
        if self.copy_tab.pos ~= 'play' or (self.copy_tab.pos == 'play' and iskeyboard.a) then     -- a完全复制
            for i = 1, #copy_tab2.event do
                chart.event[#chart.event + 1] = table.copy(copy_tab2.event[i])
            end
        end
        fEvent:sort()
        fNote:sort()

        if self.copy_tab.type == "c" then
            if self.copy_tab.pos ~= 'play' or (self.copy_tab.pos == 'play' and iskeyboard.a) then     -- a完全复制
                redo:writeRevoke("copy", table.copy(copy_tab2))
            else
                redo:writeRevoke("copy", { note = table.copy(copy_tab2.note), event = {} })
            end
            return
        end

        --x
        if self.copy_tab.pos ~= 'play' or (self.copy_tab.pos == 'play' and iskeyboard.a) then     --x
            redo:writeRevoke("cropping", { table.copy(self.copy_tab), table.copy(copy_tab2) })
        else
            redo:writeRevoke("cropping",
                { { note = table.copy(self.copy_tab.note), event = {} }, { note = table.copy(copy_tab2.note), event = {} } })
        end
        --x 删除原来的
        local local_tab = {}
        for i = 1, #chart.note do
            if not table.eq(self.copy_tab.note[1], chart.note[i]) then
                local_tab[#local_tab + 1] = chart.note[i]
            else
                table.remove(self.copy_tab.note, 1)
            end
        end
        chart.note = table.copy(local_tab)
        local_tab = {}
        if self.copy_tab.pos ~= 'play' or (self.copy_tab.pos == 'play' and iskeyboard.a) then     -- a完全复制
            for i = 1, #chart.event do
                if not table.eq(self.copy_tab.event[1], chart.event[i]) then
                    local_tab[#local_tab + 1] = chart.event[i]
                else
                    table.remove(self.copy_tab.event, 1)
                end
            end
            chart.event = table.copy(local_tab)
        end
    end
end

return ctrl