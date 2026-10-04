local AudioService = require('src.services.audioService')
--edit区域渲染
local ChartService = require("src.services.chartService")
local CoordinateService = require("src.services.coordinateService")
local NoteSkin = require("src.services.noteSkin")
local ThemeService = require("src.services.themeService")
local Spectrogram = require("src.services.spectrogramService")
local demoInEdit = object:new('demoInEdit')
demoInEdit.__index = demoInEdit   -- 原型：标签页实例共享方法与图像

--- 创建编辑窗口实例（多标签页：每个标签页一个）
-- @tparam table opts 字段：tabbed=是否标签页窗口、tab=对应标签页数据表
function demoInEdit:new(opts)
    local inst = setmetatable({}, demoInEdit)
    for k, v in pairs(opts or {}) do inst[k] = v end
    return inst
end

--[[
    波形图缓存（模块级，多个标签页窗口共享同一份）
    wav:  采样峰值单元缓存。音频按 WAVE_CELL 个采样切一个单元，按声道记录 min/max，
          由 wavFill 逐帧增量构建（受时间预算限制），音频服务的数据更换即 wavReset。
    rows: 行条缓存。编辑窗内每 1px y 一条"峰值带"（min/max），只依赖播放与显示参数
          （music/nowbeat/scale/judge/offset/bpmCount），不依赖窗口 x，
          因此多个标签页同帧只重建一次。
]]
local WAVE_CELL = 64        -- 峰值单元大小（采样数，约 1.45ms@44.1kHz）
local WAVE_PREFETCH_S = 4   -- 预取：超过当前视窗需求多少秒的音频（提前构建）
local WAVE_BUILD_MS = 1.2   -- 已覆盖区域的构建时间预算（毫秒 CPU）
local WAVE_BUILD_MS_GAP = 8 -- 首帧/跳转后的构建时间预算（毫秒 CPU）
local WAVE_ALPHA = 0.45     -- 波形透明度（所有 y 位置一致）

local wav = { cells = {}, built = -1, music = nil }
local rows = { bands = {}, valid = false, pending = 0, needCell = 0 }

-- 更换音频：清空峰值单元缓存，之后从 0 重新增量构建
local function wavReset()
    wav.cells = {}
    wav.built = -1
    wav.music = AudioService:getSoundData()
end

-- 增量构建 [built+1, targetCell] 的峰值单元，超过时间预算即停，下一帧继续
local function wavFill(targetCell, budgetMs)
    local data = AudioService:getSoundData()
    if targetCell <= wav.built then return end
    local sr = data:getSampleRate()
    local ch = data:getChannelCount()
    local count = data:getSampleCount()
    local cells = wav.cells
    local start = os.clock()
    for c = wav.built + 1, targetCell do
        local s0 = c * WAVE_CELL
        local s1 = math.min(s0 + WAVE_CELL - 1, count - 1)
        local cell = cells[c] or {}
        cells[c] = cell
        local mn1, mx1 = 1, -1
        local mn2, mx2 = 1, -1
        for s = s0, s1 do
            local v = data:getSample(s, 1)
            if v < mn1 then mn1 = v end
            if v > mx1 then mx1 = v end
            if ch >= 2 then
                local v2 = data:getSample(s, 2)
                if v2 < mn2 then mn2 = v2 end
                if v2 > mx2 then mx2 = v2 end
            end
        end
        cell.mn1, cell.mx1 = mn1, mx1
        cell.mn2, cell.mx2 = mn2, mx2
        wav.built = c
        if (os.clock() - start) * 1000 >= budgetMs then break end
    end
end

-- 重建行条缓存：逐行计算该 1px 行对应的音频峰值区间；
-- 行引用的采样单元还没建完则本行留空并累计 pending（之后每帧重建，底部先补全）
local function rowsRebuild()
    local data = AudioService:getSoundData()
    local sr = data:getSampleRate()
    local ch = data:getChannelCount()
    local count = data:getSampleCount()
    local y0 = math.floor(play.layout.edit.y)
    local y1 = math.floor(settings.judge_line_y)
    local n = y1 - y0
    local bands = rows.bands
    local pending = 0
    local needCell = 0
    for i = 1, n do
        local band = bands[i] or {}
        bands[i] = band
        band.lo, band.hi, band.lo2, band.hi2 = 1, -1, 1, -1 -- 先置空（lo > hi 表示空）
        local yTop = y0 + i - 1
        local t1 = ChartService:toTime(CoordinateService:yToBeat(yTop)) - ChartService:getOffset() / 1000
        local t0 = ChartService:toTime(CoordinateService:yToBeat(yTop + 1)) - ChartService:getOffset() / 1000
        local s1 = math.floor(t1 * sr)
        local s0 = math.ceil(t0 * sr)
        if s1 - s0 < WAVE_CELL then
            -- 放大视图（每行采样数 < 单元大小）：直接读原始采样
            local as = math.max(s0, 0)
            local ae = math.min(s1, count - 1)
            local lo, hi, lo2, hi2 = 1, -1, 1, -1
            for s = as, ae do
                local v = data:getSample(s, 1)
                if v < lo then lo = v end
                if v > hi then hi = v end
                if ch >= 2 then
                    local v2 = data:getSample(s, 2)
                    if v2 < lo2 then lo2 = v2 end
                    if v2 > hi2 then hi2 = v2 end
                end
            end
            band.lo, band.hi, band.lo2, band.hi2 = lo, hi, lo2, hi2
        else
            -- 常规/缩小视图：走采样峰值单元缓存，单元没建完则该行留空
            local c0 = math.max(0, math.floor(s0 / WAVE_CELL))
            local c1 = math.min(math.floor(s1 / WAVE_CELL), math.floor((count - 1) / WAVE_CELL))
            local cells = wav.cells
            local ok = true
            local lo, hi, lo2, hi2 = 1, -1, 1, -1
            for c = c0, c1 do
                if c > needCell then needCell = c end
                local cell = cells[c]
                if cell then
                    if cell.mn1 < lo then lo = cell.mn1 end
                    if cell.mx1 > hi then hi = cell.mx1 end
                    if ch >= 2 and cell.mn2 then
                        if cell.mn2 < lo2 then lo2 = cell.mn2 end
                        if cell.mx2 > hi2 then hi2 = cell.mx2 end
                    end
                else
                    ok = false
                end
            end
            if ok and c0 <= c1 then
                band.lo, band.hi, band.lo2, band.hi2 = lo, hi, lo2, hi2
            elseif c0 <= c1 then
                pending = pending + 1
            end
        end
    end
    rows.pending = pending
    rows.needCell = needCell
    rows.valid = true
    rows.music = data
    rows.nowbeat = AudioService:getCurrentBeat()
    rows.scale = denom.scale
    rows.judge = settings.judge_line_y
    rows.offset = ChartService:getOffset()
    rows.bpmCount = ChartService:getBpmCount()
    rows.y0 = y0
end


function demoInEdit:load()
    if self.layout then return end -- 幂等：默认实例加载后，标签页实例经原型共享图像/布局
    self.ui_note = isImage.note
    self.ui_wipe = isImage.wipe
    self.ui_hold = isImage.hold_head
    self.ui_hold_body = isImage.hold_body
    self.ui_hold_tail = isImage.hold_tail
    self.note_w = play.layout.edit.interval

    self.layout = play.layout.edit
end

-- 绘制波形图：行条缓存 + 立体声分色（左蓝右橙）+ 亮度分档（顶部暗 → 底部亮）
function demoInEdit:drawSample(pos, istrack)
    local data = AudioService:getSoundData()
    if not data then return end
    if wav.music ~= data then wavReset() end
    local layout = self.layout or play.layout.edit
    local x = pos or self.x or layout.x
    local y0 = math.floor(play.layout.edit.y)
    local y1 = math.floor(settings.judge_line_y)
    local n = y1 - y0
    if n <= 0 then return end

    -- 失效检测：全局参数任一变化，或上轮有行未建成（pending > 0）→ 重建
    if not (rows.valid and rows.pending == 0 and rows.music == data and
        rows.nowbeat == AudioService:getCurrentBeat() and rows.scale == denom.scale and
        rows.judge == settings.judge_line_y and rows.offset == ChartService:getOffset() and
        rows.bpmCount == ChartService:getBpmCount() and rows.y0 == y0) then
        rowsRebuild()
    end

    -- 增量构建峰值单元到"视窗需求 + 预取"；需求远超已建（首帧/跳转）用更大的时间预算
    local sr = data:getSampleRate()
    local prefetchCells = math.floor(WAVE_PREFETCH_S * sr / WAVE_CELL)
    wavFill(rows.needCell + prefetchCells, (rows.needCell > wav.built) and WAVE_BUILD_MS_GAP or WAVE_BUILD_MS)

    -- 逐行绘制（行内按峰值幅度向外生长，夹在窗口内）
    local ch = data:getChannelCount()
    local window_w = layout.w
    local cx = x + window_w / 2
    local half = window_w / 2 - 2       -- 单侧幅度上限
    local bands = rows.bands
    local cr, cg, cb = 0.42, 0.72, 1     -- 左声道蓝
    local cr2, cg2, cb2 = 1, 0.6, 0.32   -- 右声道橙
    if ch < 2 then cr, cg, cb = 0.45, 0.75, 1 end -- 单声道居中蓝
    for i = 1, n do
        local band = bands[i]
        if band and band.lo <= band.hi then
            local a = WAVE_ALPHA
            local y = y0 + i - 1
            local w = math.max(-band.lo, band.hi) * half
            if w > 0 then
                if ch >= 2 then
                    -- 左声道（蓝）向左画、右声道（橙）向右画，中间留 2px 深色缝
                    local lx = math.max(x + 3, cx - w)
                    local lw = (cx - 1) - lx
                    if lw > 0 then
                        love.graphics.setColor(cr, cg, cb, a)
                        love.graphics.rectangle("fill", lx, y, lw, 1)
                    end
                    local w2 = math.max(-band.lo2, band.hi2) * half
                    if w2 > 0 then
                        local rw = math.min(x + window_w - 3, cx + 2 + w2) - (cx + 1)
                        if rw > 0 then
                            love.graphics.setColor(cr2, cg2, cb2, a)
                            love.graphics.rectangle("fill", cx + 1, y, rw, 1)
                        end
                    end
                else
                    love.graphics.setColor(cr, cg, cb, a)
                    local lx = math.max(x + 3, cx - w)
                    local rx = math.min(x + window_w - 3, cx + w)
                    if rx - lx > 0 then love.graphics.rectangle("fill", lx, y, rx - lx, 1) end
                end
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

-- 谱面重排后旧数组下标失效；每个编辑窗口独立保存遍历状态。
local traversalRevision = 0
local traversalEvents = require('src.utils.eventBus')
local function invalidateTraversal()
    traversalRevision = traversalRevision + 1
end
traversalEvents:on('chart:mutated', invalidateTraversal)
traversalEvents:on('chart:changed', invalidateTraversal)

function demoInEdit:resetTraversal()
    self._traversal = nil
    -- 默认实例的重置也要使所有标签页的缓存失效。
    invalidateTraversal()
end

function demoInEdit:draw(pos, istrack)
    if self.tabbed then
        -- 标签页窗口：内容、裁剪与不可编辑遮罩由实例绘制；顶部数值条由 tabs 用 Nuklear 绘制。
        local ly = tabs.layout
        local wx = self.x
        if wx >= play.layout.x + play.layout.w or wx + ly.tabW <= play.layout.x then
            return -- 完全在 play 区域外（滚动/拖出）则不绘制
        end
        local w = math.min(ly.tabW, play.layout.x + play.layout.w - wx)
        love.graphics.setScissor(wx, ly.region.y, w, ly.region.h)
        self:drawEditContent(wx, tabs:getTabTrack(self.tab))
        -- 不可编辑轨道覆盖 0.5 透明黑遮罩
        for k = 1, 5 do
            if not self.tab.edit[ly.lane[k]] then
                love.graphics.setColor(0, 0, 0, 0.5)
                love.graphics.rectangle('fill', wx + play.layout.edit.interval * (k - 1), ly.region.y,
                    play.layout.edit.interval, ly.region.h)
            end
        end
        love.graphics.setScissor()
        return
    end
    -- 默认实例：多标签页时窗口由各标签页实例绘制，自身只在单标签页时绘制
    if pos == nil and tabs and not tabs:isSingle() then
        return
    end
    self:drawEditContent(pos or play.layout.edit.x, istrack or track.track)
end

-- 绘制单个 edit 窗口内容：波形/轨道/note/event（不含 Nuklear 信息板）
function demoInEdit:drawEditContent(pos, istrack)
    -- edit 画布可由主题覆盖，日间未配置时保持较深底色。
    local canvasColor = ThemeService:editorColor(settings.theme, 'canvas')
    if canvasColor or settings.theme == 'light' then
        love.graphics.setColor(canvasColor or {0.38, 0.40, 0.44, 1})
        love.graphics.rectangle('fill', pos, self.layout.y, self.layout.w, self.layout.h)
    end
    local one_track_w = self.layout.oneTrackW
    local interval = self.layout.interval
    local track_x, track_y, track_w, track_h = self.layout.x, self.layout.y, self.layout.w, self.layout.h

    local all_track_pos = play:get_all_track_pos()
    local all_track = fTrack:track_get_all_track()
    local note_h = settings.note_height --25 * denom.scale

    local trackleft = {} --每个轨道的左边距（随窗口位置变化）
    for i = 1, #trackSequence do
        trackleft[trackSequence[i]] = pos + interval * (i - 1)
    end

    if settings.spectrogram == 1 then
        Spectrogram:draw(AudioService:getSoundData(), pos, self.layout.w, self.layout.y,
            math.min(settings.judge_line_y, self.layout.y + self.layout.h))
    end
    if settings.wavfrom == 1 then
        self:drawSample(pos, istrack)
    end

    love.graphics.setColor(1, 1, 1, 0.4) -- 轨道分界线透明度
    for i = 1, #trackSequence do
        love.graphics.rectangle("line", pos + interval * (i-1), track_y,interval , track_h)
    end

    love.graphics.setColor(1, 1, 1)
    -- 侧线左
    love.graphics.rectangle("fill", pos, track_y, 3, track_h)

    -- 侧线右
    love.graphics.rectangle("fill", pos + interval * #trackSequence, track_y, 3, track_h)

    --判定线
    love.graphics.setColor(ThemeService:judgeColor(settings.theme, 'edit') or {1, 1, 1, 1})
    love.graphics.rectangle("line", pos, settings.judge_line_y, track_w, 10)

    love.graphics.setColor(1, 1, 1)
    --note(edit区域渲染)
    -- 只有谱面、轨道和可见范围均未改变且时间向前时才能复用下标。
    local currentBeat = AudioService:getCurrentBeat()
    local previous = rawget(self, '_traversal')
    local index_start, index_start_event = 1, 1
    if previous and previous.revision == traversalRevision and previous.track == istrack
        and previous.scale == denom.scale and previous.judge == settings.judge_line_y
        and previous.height == WINDOW.h and previous.noteHeight == note_h
        and currentBeat > previous.beat then
        index_start = math.max(1, previous.note)
        index_start_event = math.max(1, previous.event)
    end
    local traversal = {revision = traversalRevision, track = istrack, scale = denom.scale,
        judge = settings.judge_line_y, height = WINDOW.h, noteHeight = note_h,
        beat = currentBeat, note = 0, event = 0}
    self._traversal = traversal

    local y = 0
    local y2 = 0
    for i = index_start, (ChartService:isEditingEffect() and 0 or ChartService:getNoteCount()) do
        local n = ChartService:getNote(i)
        if n:getTrack() == istrack then
            local y = CoordinateService:toY(n:getBeatValue())
            local y2 = y
            if n:isHold() then
                y2 = CoordinateService:toY(n:getBeat2Value())
            end
            if math.intersect(y, y2, WINDOW.h + note_h, -note_h) then
                if traversal.note == 0 then traversal.note = i end
                if n:isNote() then
                    NoteSkin.draw('note', self.ui_note, trackleft.note, y - note_h, self.note_w, note_h)
                elseif n:isWipe() then
                    NoteSkin.draw('wipe', self.ui_wipe, trackleft.note, y - note_h, self.note_w, note_h)
                else --hold
                    local note_h2 = y - y2 - note_h * 2
                    NoteSkin.draw('hold_head', self.ui_hold, trackleft.note, y - note_h, self.note_w, note_h)
                    NoteSkin.draw('hold_tail', self.ui_hold_tail, trackleft.note, y2, self.note_w, note_h)
                    NoteSkin.draw('hold_body', self.ui_hold_body, trackleft.note, y2 + note_h, self.note_w, note_h2)
                    if n:getNoteHead() == 1 then
                        NoteSkin.draw('note', self.ui_note, trackleft.note, y - note_h, self.note_w / 2, note_h)
                    end
                    if n:getWipeHead() == 1 then
                        NoteSkin.draw('wipe', self.ui_wipe, trackleft.note + self.note_w / 2, y - note_h,
                            self.note_w / 2, note_h)
                    end
                end
                if n:isFakeNote() then --假note
                    love.graphics.setColor(play.colors.red)
                    love.graphics.rectangle('line', trackleft.note, y - note_h, self.note_w, note_h)
                    love.graphics.printf('false', trackleft.note, y - note_h, interval, 'center')
                    love.graphics.setColor(1, 1, 1)
                end
            elseif y < -note_h then
                break
            end
        end
    end
    --放置一半的长条渲染
    local thelocal_hold = fNote:getHoldTable()
    if thelocal_hold._data and thelocal_hold:getTrack() == istrack then -- 存在
        love.graphics.setColor(1, 1, 1)
        local y = CoordinateService:toY(thelocal_hold:getBeatValue())
        local y2 = CoordinateService:toY(beat:toNearby(CoordinateService:yToBeat(mouse.y)))
        local note_h2 = y - y2 - note_h * 2
        if math.intersect(y, y2, track_y + track_h + note_h, -note_h) then
            NoteSkin.draw('hold_head', self.ui_hold, trackleft.note, y - note_h, self.note_w, note_h)
            NoteSkin.draw('hold_body', self.ui_hold_body, trackleft.note, y2 + note_h, self.note_w, note_h2)
            NoteSkin.draw('hold_tail', self.ui_hold_tail, trackleft.note, y2, self.note_w, note_h)
        end
    end

    local note_index = sidebar.incoming[1]               --选中的note
    if sidebar.displayed_content == "note" and           --选中note框绘制
        ChartService:getNote(note_index) and
        ChartService:getNote(note_index):getTrack() == istrack then --框出现在编辑的note
        local sn = ChartService:getNote(note_index)
        local y = CoordinateService:toY(sn:getBeatValue())
        local y2 = y - note_h
        if sn:isHold() then
            y2 = CoordinateService:toY(sn:getBeat2Value())
        end
        love.graphics.setColor(play.colors.white_half)
        love.graphics.rectangle("fill", trackleft.note, y2, interval, y - y2)
    end

    --event渲染
    local event_h = settings.note_height
    local event_w = self.note_w
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')

    for i = index_start_event, ChartService:getEventCount() do
        local e = ChartService:getEvent(i)
        if e:getTrack() == istrack and (trackleft[e:getType()] or e:getType()=='event_group') then
            love.graphics.setColor(1, 1, 1)
            local y = CoordinateService:toY(e:getBeatValue())
            local y2 = CoordinateService:toY(e:getBeat2Value())
            local event_h2 = y - y2 - event_h * 2
            local x_pos = trackleft[e:getType()]
            if math.intersect(y, y2, WINDOW.h + note_h, -note_h) then
                if traversal.event == 0 then traversal.event = i end
                if e:getType() == 'event_group' then
                    love.graphics.setColor(play.colors.cyan_fade)
                    love.graphics.rectangle('fill', trackleft.x, y2, interval * 4, y - y2)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.rectangle('line', trackleft.x, y2, interval * 4, y - y2)
                    love.graphics.printf(e:getEventGroup() ~= '' and e:getEventGroup() or
                        i18n:get('event_group.none'), trackleft.x, y2, interval * 4, 'center')
                else
                    NoteSkin.draw('hold_head', self.ui_hold, x_pos, y - event_h, event_w, event_h) -- 头
                    love.graphics.printf(e:getFrom(), x_pos, y - event_h, interval, 'center')
                    NoteSkin.draw('hold_body', self.ui_hold_body, x_pos, y2 + event_h, event_w, event_h2) -- 身
                    NoteSkin.draw('hold_tail', self.ui_hold_tail, x_pos, y2, event_w, event_h) -- 尾
                    love.graphics.printf(e:getTo(), x_pos, y2, interval, 'center')
                    for k = 1, 10 do
                        local nowx = (e:getFrom() - x_offset) / event_scale * interval + x_pos +
                            fEvent:getTrans(e, k / 10) *
                            ((e:getTo() - e:getFrom()) / event_scale * interval)
                        local nowy = y + (y2 - y) * k / 10
                        love.graphics.rectangle('fill', nowx, nowy - (y2 - y) / 10, 5, (y2 - y) / 10)
                    end
                end
            elseif y < -note_h then
                break
            end
        end
    end
    --放置一半的event渲染
    local thelocal_event = fEvent:getHoldTable()
    if thelocal_event._data and thelocal_event:getTrack() == istrack then -- 存在
        love.graphics.setColor(1, 1, 1)
        local y = CoordinateService:toY(thelocal_event:getBeatValue())
        local y2 = CoordinateService:toY(beat:toNearby(CoordinateService:yToBeat(mouse.y)))
        local event_h2 = y - y2 - event_h * 2
        local x_pos = trackleft[thelocal_event:getType()]

        if math.intersect(y, y2, WINDOW.h + note_h, -note_h) then
            if thelocal_event:getType() == 'event_group' then
                love.graphics.setColor(play.colors.cyan_fade)
                love.graphics.rectangle('fill', trackleft.x, y2, interval * 4, y - y2)
            else
                NoteSkin.draw('hold_head', self.ui_hold, x_pos, y - event_h, event_w, event_h) -- 头
                NoteSkin.draw('hold_body', self.ui_hold_body, x_pos, y2 + event_h, event_w, event_h2) -- 身
                NoteSkin.draw('hold_tail', self.ui_hold_tail, x_pos, y2, event_w, event_h) -- 尾
            end
        end
    end

    local event_index = sidebar.incoming[1]                                  --选中的event
    if sidebar.displayed_content == "event" and ChartService:getEvent(event_index) and --选中event框绘制
        ChartService:getEvent(event_index):getTrack() == istrack then             --框出现在编辑的event
        local se = ChartService:getEvent(event_index)
        local y = CoordinateService:toY(se:getBeatValue())
        local y2 = CoordinateService:toY(se:getBeat2Value())
        love.graphics.setColor(play.colors.white_half)
        local selectedX = se:getType() == 'event_group' and trackleft.x or trackleft[se:getType()]
        local selectedW = se:getType() == 'event_group' and interval * 4 or interval
        love.graphics.rectangle('fill', selectedX, y2, selectedW, y - y2)
    end

end

return demoInEdit
