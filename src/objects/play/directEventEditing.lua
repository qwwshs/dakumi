--event直观编辑
local directEventEditing = object:new('directEventEditing')
directEventEditing.open = false
directEventEditing.catch_point = nil
function directEventEditing:keypressed(key)
    if input('directEventEditing') then
        self.open = not self.open
        if self.open then
            messageBox:add("direct event editing open")
        else
            messageBox:add("direct event editing close")
        end
    end
end

function directEventEditing:draw()
    if not self.open then
        return
    end
    if sidebar.displayed_content ~= 'event' then
        return
    end
    local radius = 20
    love.graphics.setColor(1, 1, 1, 1) --头和尾的两个可拖动的圆
    --得到event
    local isevent = chart.event[sidebar.incoming[1]]
    local c_y = beat:toY(isevent.beat)
    local c_y2 = beat:toY(isevent.beat2)
    local c_x = fTrack:to_play_track_x(isevent.from)
    local c_x2 = fTrack:to_play_track_x(isevent.to)
    love.graphics.circle('line', c_x, c_y, radius)
    love.graphics.circle('line', c_x2, c_y2, radius)

    love.graphics.setColor(1, 1, 1, 1)

    if isevent.trans.type == 'bezier' then
        local control_point = { c_x, c_y }
        for i = 1, #isevent.trans.trans, 2 do
            local nowx = isevent.trans.trans[i]
            local nowy = isevent.trans.trans[i + 1]
            if not (nowx and nowy) then break end
            --进行缩放
            nowx = c_x + (c_x2 - c_x) * nowx
            nowy = c_y + (c_y2 - c_y) * nowy
            table.insert(control_point, nowx)
            table.insert(control_point, nowy)
            love.graphics.circle('line', nowx, nowy, radius)
        end
        table.insert(control_point, c_x2)
        table.insert(control_point, c_y2)
        love.graphics.line(control_point)
    end
end

function directEventEditing:update(dt)
    if not self.open then
        return
    end
    if sidebar.displayed_content ~= 'event' then
        return
    end
    local isevent = chart.event[sidebar.incoming[1]]
    if not isevent then return end
    local c_y = beat:toY(isevent.beat)
    local c_y2 = beat:toY(isevent.beat2)
    local c_x = fTrack:to_play_track_x(isevent.from)
    local c_x2 = fTrack:to_play_track_x(isevent.to)
    local radius = 20
    if love.mouse.isDown(1) then
        if self.catch_point == 'head' then --拖动头
            local now_beat = beat:toNearby(beat:yToBeat(mouse.y))
            isevent.beat = now_beat

            --有fance就吸附
            local now_from = fTrack:track_get_near_fence_x()
            isevent.from = now_from
        elseif self.catch_point == 'tail' then --拖动尾
            local now_beat = beat:toNearby(beat:yToBeat(mouse.y))
            isevent.beat2 = now_beat
            --有fance就吸附
            local now_to = fTrack:track_get_near_fence_x()
            isevent.to = now_to
        end
        if isevent.trans.type == 'bezier' then
            local bezier_points = {}
            for i = 1, #isevent.trans.trans, 2 do
                local nowx = isevent.trans.trans[i]
                local nowy = isevent.trans.trans[i + 1]
                if not (nowx and nowy) then break end
                --进行缩放
                nowx = c_x + (c_x2 - c_x) * nowx
                nowy = c_y + (c_y2 - c_y) * nowy
                table.insert(bezier_points, { x = nowx, y = nowy })
            end
            for index, point in pairs(bezier_points) do
                if self.catch_point == 'control' .. index then --拖动控制点
                    local nowx = mouse.x
                    local nowy = mouse.y
                    --进行缩放
                    nowx = (nowx - c_x) / (c_x2 - c_x)
                    nowy = (nowy - c_y) / (c_y2 - c_y)
                    isevent.trans.trans[(index - 1) * 2 + 1] = nowx
                    isevent.trans.trans[(index - 1) * 2 + 2] = nowy
                end
            end
        end
        sidebar:to('event', sidebar.incoming[1]) --更新信息
    end
    Slab.BeginWindow('Left_Mouse_Context_Menu', { Title = "", X = mouse.x, Y = mouse.y, W = 0, H = 0 ,BgColor = {0,0,0,0}})
    if Slab.BeginContextMenuWindow() then
        if Slab.MenuItem(i18n:get('switch trans type')) then
            if isevent.trans.type == 'bezier' then isevent.trans.type = 'easings' else isevent.trans.type = 'bezier' end
        end

        if Slab.MenuItem(i18n:get('switch the curve to the next type')) then
            if isevent.trans.type == 'bezier' then
                if fEvent.bezier[transIndex.bezier + 1] then
                    transIndex.bezier = transIndex.bezier + 1
                    isevent.trans.trans = fEvent.bezier[transIndex.bezier]
                end
            else
                if easings[transIndex.easings + 1] then
                    transIndex.easings = transIndex.easings + 1
                    isevent.trans.easings = transIndex.easings
                end
            end
        end

        if Slab.MenuItem(i18n:get('switch the curve back to the previous type')) then
            if isevent.trans.type == 'bezier' then
                if fEvent.bezier[transIndex.bezier - 1] then
                    transIndex.bezier = transIndex.bezier - 1
                    isevent.trans.trans = fEvent.bezier[transIndex.bezier]
                end
            else
                if easings[transIndex.easings - 1] then
                    transIndex.easings = transIndex.easings - 1
                    isevent.trans.easings = transIndex.easings
                end
            end
        end

        if isevent.trans.type == 'bezier' then
            if Slab.MenuItem(i18n:get('add control point')) then
                local x = (mouse.x - c_x) / (c_x2 - c_x)
                local y = (mouse.y - c_y) / (c_y2 - c_y)
                table.insert(isevent.trans.trans,x)
                table.insert(isevent.trans.trans,y)
            end
            if Slab.MenuItem(i18n:get('delete control point')) then
                if #isevent.trans.trans > 2 then
                    table.remove(isevent.trans.trans,-1)
                    table.remove(isevent.trans.trans,-1)
                end
            end
        end

        Slab.EndContextMenu()
        sidebar:to('event', sidebar.incoming[1]) --更新信息
    end
    Slab.EndWindow()

    
    --松手清除
    if not love.mouse.isDown(1) and self.catch_point then
        self.catch_point = nil
    end

end

function directEventEditing:mousepressed(x, y, button, istouch, presses)
    if not self.open then
        return
    end
    if sidebar.displayed_content ~= 'event' then
        return
    end
    local isevent = chart.event[sidebar.incoming[1]]
    if not isevent then return end
    local c_y = beat:toY(isevent.beat)
    local c_y2 = beat:toY(isevent.beat2)
    local c_x = fTrack:to_play_track_x(isevent.from)
    local c_x2 = fTrack:to_play_track_x(isevent.to)
    local radius = 20
    if love.mouse.isDown(1) then
        if math.intersect(mouse.x, mouse.x, c_x - radius, c_x + radius) and math.intersect(mouse.y, mouse.y, c_y - radius, c_y + radius) then --拖动头
            self.catch_point = 'head'
            return
        elseif math.intersect(mouse.x, mouse.x, c_x2 - radius, c_x2 + radius) and math.intersect(mouse.y, mouse.y, c_y2 - radius, c_y2 + radius) then --拖动尾
            self.catch_point = 'tail'
            return
        end
        if isevent.trans.type == 'bezier' then
            local bezier_points = {}
            for i = 1, #isevent.trans.trans, 2 do
                local nowx = isevent.trans.trans[i]
                local nowy = isevent.trans.trans[i + 1]
                if not (nowx and nowy) then break end
                --进行缩放
                nowx = c_x + (c_x2 - c_x) * nowx
                nowy = c_y + (c_y2 - c_y) * nowy
                table.insert(bezier_points, { x = nowx, y = nowy })
            end
            for index, point in pairs(bezier_points) do
                if math.intersect(mouse.x, mouse.x, point.x - radius, point.x + radius) and math.intersect(mouse.y, mouse.y, point.y - radius, point.y + radius) then --拖动控制点
                    self.catch_point = 'control' .. index
                    return
                end
            end
        end
    end
end

return directEventEditing
