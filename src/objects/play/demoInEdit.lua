--edit区域渲染
local demoInEdit = object:new('demoInEdit')

function demoInEdit:load()
    self.ui_note = isImage.note
    self.ui_wipe = isImage.wipe
    self.ui_hold = isImage.hold_head
    self.ui_hold_body = isImage.hold_body
    self.ui_hold_tail = isImage.hold_tail
    self.note_w = 75

    self._width, self._height = self.ui_note:getDimensions() -- 得到宽高
    self._scale_w = 1 / self._width * self.note_w
    self.layout = play.layout.edit
end

function demoInEdit:draw(pos, istrack)
    local one_track_w = self.layout.oneTrackW
    local interval = self.layout.interval
    local track_x, track_y, track_w, track_h = self.layout.x, self.layout.y, self.layout.w, self.layout.h

    local all_track_pos = play:get_all_track_pos()
    local all_track = fTrack:track_get_all_track()
    local note_h = settings.note_height --25 * denom.scale
    local _scale_h = 1 / self._height * note_h
    pos = pos or track_x
    istrack = istrack or track.track
    love.graphics.setColor(1,1,1) --轨道
    love.graphics.rectangle("line", pos, 0, one_track_w, track_h)

    -- 侧线左
    love.graphics.rectangle("fill", pos, 0, 3, track_h)

    -- x轨道
    love.graphics.rectangle("line", pos + interval, track_y, one_track_w, track_h)

     -- w轨道
    love.graphics.rectangle("line", pos + interval * 2, track_y, one_track_w, track_h)

    -- 侧线右
    love.graphics.rectangle("fill", pos + one_track_w + interval * 2, track_y, 3, track_h)

    --判定线
    love.graphics.rectangle("fill", pos, settings.judge_line_y, one_track_w + interval * 2, 10)


    love.graphics.setColor(1,1,1)
    --note(edit区域渲染)
    for i = 1, #chart.note do
        if chart.note[i].track == istrack then
            local y = beat:toY(chart.note[i].beat)
            local y2 = y
            if chart.note[i].type == "hold" then
                y2 = beat:toY(chart.note[i].beat2)
            end
            if math.intersect(y,y2,WINDOW.h + note_h,-note_h) then
                if chart.note[i].type == "note" then
                    love.graphics.draw(self.ui_note, pos, y - note_h, 0, self._scale_w, _scale_h)
                elseif chart.note[i].type == "wipe" then
                    love.graphics.draw(self.ui_wipe, pos, y - note_h, 0, self._scale_w, _scale_h)
                else                                                                              --hold
                    love.graphics.draw(self.ui_hold, pos, y - note_h, 0, self._scale_w, _scale_h) -- 头
                    local note_h2 = y - y2 - note_h * 2
                    local _scale_h2 = 1 / self._height * note_h2
                    love.graphics.draw(self.ui_hold_tail, pos, y2, 0, self._scale_w, _scale_h)           -- 尾
                    love.graphics.draw(self.ui_hold_body, pos, y2 + note_h, 0, self._scale_w, _scale_h2) --身
                    if chart.note[i].note_head == 1 then
                        love.graphics.draw(self.ui_note, pos, y - note_h, 0, self._scale_w/2, _scale_h)
                    end 
                    if chart.note[i].wipe_head == 1 then
                        love.graphics.draw(self.ui_wipe, pos+self.note_w/2, y - note_h, 0, self._scale_w/2, _scale_h)
                    end
                end
                if chart.note[i].fake and chart.note[i].fake == 1 then                                   --假note
                    love.graphics.setColor(play.colors.isFakeNote)
                    love.graphics.rectangle('line', pos, y - note_h, self.note_w, note_h)
                    love.graphics.printf('false', pos, y - note_h, one_track_w, 'center')
                    love.graphics.setColor(1,1,1)
                end
            elseif y < -note_h then
                break
            end
        end
    end
    --放置一半的长条渲染
    local thelocal_hold = fNote:getHoldTable()
    if thelocal_hold.beat and thelocal_hold.track == istrack then -- 存在
        love.graphics.setColor(1,1,1)
        local y = beat:toY(thelocal_hold.beat)
        local y2 = beat:toY(beat:toNearby(beat:yToBeat(mouse.y)))
        local note_h2 = y - y2 - note_h * 2
        local _scale_h2 = 1 / self._height * note_h2
        if math.intersect(y,y2,track_y + track_h + note_h,-note_h) then
            love.graphics.draw(self.ui_hold, pos, y - note_h, 0, self._scale_w, _scale_h)        --头
            love.graphics.draw(self.ui_hold_body, pos, y2 + note_h, 0, self._scale_w, _scale_h2) --身
            love.graphics.draw(self.ui_hold_tail, pos, y2, 0, self._scale_w, _scale_h)           --尾
        end
    end

    local note_index = sidebar.incoming[1]               --选中的note
    if sidebar.displayed_content == "note" and           --选中note框绘制
        chart.note[note_index] and
        chart.note[note_index].track == track.track then --框出现在编辑的note
        local y = beat:toY(chart.note[note_index].beat)
        local y2 = y - note_h
        if chart.note[note_index].type == 'hold' then
            y2 = beat:toY(chart.note[note_index].beat2)
        end
        love.graphics.setColor(play.colors.selectingNote)
        love.graphics.rectangle("fill", pos, y2, one_track_w, y - y2)
    end

    --event渲染
    local event_h = settings.note_height
    local event_w = 75
    for i = 1, #chart.event do
        if chart.event[i].track == istrack then
            love.graphics.setColor(1,1,1)
            local y = beat:toY(chart.event[i].beat)
            local y2 = beat:toY(chart.event[i].beat2)
            local event_h2 = y - y2 - event_h * 2
            local _scale_h2 = 1 / self._height * event_h2
            local x_pos = pos + interval
            if chart.event[i].type == "w" then
                x_pos = pos + interval * 2
            end
            if not (y2 > WINDOW.h + note_h or y < -note_h) then
                love.graphics.draw(self.ui_hold, x_pos, y - event_h, 0, self._scale_w, _scale_h)        -- 头
                love.graphics.printf(chart.event[i].from, x_pos, y - event_h, one_track_w, 'center')
                love.graphics.draw(self.ui_hold_body, x_pos, y2 + event_h, 0, self._scale_w, _scale_h2) --身

                love.graphics.draw(self.ui_hold_tail, x_pos, y2, 0, self._scale_w, _scale_h)            --尾
                love.graphics.printf(chart.event[i].to, x_pos, y2, one_track_w, 'center')
                -- beizer曲线
                for k = 1, 10 do
                    local nowx = (chart.event[i].from - chart.preference.event_scale) / chart.preference.event_scale * one_track_w + x_pos + one_track_w / 2 +
                    fEvent:getTrans(chart.event[i], k / 10) *
                    ((chart.event[i].to - chart.event[i].from) / chart.preference.event_scale * one_track_w)                                         --减去50是为了使50居中
                    local nowy = y + (y2 - y) * k / 10
                    love.graphics.rectangle("fill", nowx, nowy - (y2 - y) / 10, 5, (y2 - y) / 10)          --减去一个 (y2 - y)/10是为了与头对齐
                end
            elseif y < -note_h then
                break
            end
        end
    end
    --放置一半的event渲染
    local thelocal_event = fEvent:getHoldTable()
    if thelocal_event.beat and thelocal_event.track == istrack then -- 存在
        love.graphics.setColor(1,1,1)
        local y = beat:toY(thelocal_event.beat)
        local y2 = beat:toY(beat:toNearby(beat:yToBeat(mouse.y)))
        local event_h2 = y - y2 - event_h * 2
        local _scale_h2 = 1 / self._height * event_h2
        local x_pos = pos + interval

        if thelocal_event.type == "w" then
            x_pos = pos + interval * 2
        end
        if not (y2 > WINDOW.h + note_h or y < -note_h) then
            love.graphics.draw(self.ui_hold, x_pos, y - note_h, 0, self._scale_w, _scale_h)         --头
            love.graphics.draw(self.ui_hold_body, x_pos, y2 + event_h, 0, self._scale_w, _scale_h2) --身
            love.graphics.draw(self.ui_hold_tail, x_pos, y2, 0, self._scale_w, _scale_h)            --尾
        end
    end

    local event_index = sidebar.incoming[1]                                  --选中的event
    if sidebar.displayed_content == "event" and chart.event[event_index] and --选中event框绘制
        chart.event[event_index].track == track.track then                   --框出现在编辑的event
        local y = beat:toY(chart.event[event_index].beat)
        local y2 = beat:toY(chart.event[event_index].beat2)
        love.graphics.setColor(play.colors.selectingEvent)
        if chart.event[event_index].type == "x" then
            love.graphics.rectangle("fill", pos + interval, y2, one_track_w, y - y2)
        else
            love.graphics.rectangle("fill", pos + interval * 2, y2, one_track_w, y - y2)
        end
    end

    love.graphics.setColor(play.colors.editInJudgheLineDownBg)
    love.graphics.rectangle("fill", pos, settings.judge_line_y + 10, track_w, WINDOW.h - settings.judge_line_y) --遮罩
    love.graphics.setColor(1,1,1)                                                                          --现在节拍
    love.graphics.print(i18n:get('beat') .. ":" .. math.roundToPrecision(beat.nowbeat, 100), pos, settings.judge_line_y + 20)
    love.graphics.print(i18n:get('time') .. ":" .. math.roundToPrecision(time.nowtime, 100), pos, settings.judge_line_y + 40)
    local now_x, now_w = fEvent:get(istrack, beat.nowbeat, true)
    local track_info = fTrack:get_track_info(istrack)
    if track_info.type == 'xw' then
        love.graphics.print(i18n:get('x') .. ":" .. math.roundToPrecision(now_x, 100), pos + 100, settings.judge_line_y + 20)
        love.graphics.print(i18n:get('w') .. ":" .. math.roundToPrecision(now_w, 100), pos + 200, settings.judge_line_y + 20)
    elseif track_info.type == 'lposrpos' then
        love.graphics.print(i18n:get('lpos') .. ":" .. math.roundToPrecision(now_x, 100), pos + 100, settings.judge_line_y + 20)
        love.graphics.print(i18n:get('rpos') .. ":" .. math.roundToPrecision(now_w, 100), pos + 200, settings.judge_line_y + 20)
    end
    if track_info.w0thenShow == 0 then
        love.graphics.print(i18n:get('hide'), pos + 200, settings.judge_line_y + 40)
    else
        love.graphics.print(i18n:get('do_not_hide'), pos + 200, settings.judge_line_y + 40)
    end
    love.graphics.print(i18n:get('track') .. ":" .. istrack, pos, settings.judge_line_y + 60)
    love.graphics.print(i18n:get('track_name') .. ":" .. track_info.name, pos, settings.judge_line_y + 80)
end

return demoInEdit
