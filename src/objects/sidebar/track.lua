-- 轨道列表与筛选界面
local ChartService = require('src.services.chartService')
local Gtrack = group:new('track')
Gtrack.type = 'track'
Gtrack.layout = require('config.layouts.sidebar').track
Gtrack.turnOnFilter = {value = false}
Gtrack.filterExpanded = true
Gtrack.filterMode = {value = 1}
Gtrack.range = {
    x = {from = {value = ''}, to = {value = ''}},
    w = {from = {value = ''}, to = {value = ''}},
}
Gtrack.nameQuery = {value = ''}
Gtrack.settingIndex = {value = 1}
Gtrack.settingQuery = {value = ''}
Gtrack.switchValue = {value = 1}

local settingFields = {
    {key = 'type'},
    {key = 'w0thenShow', switch = true},
    {key = 'parent'},
    {key = 'scale_with_parent', switch = true},
    {key = 'zindex'},
    {key = 'boundary_type'},
    {key = 'left_boundary'},
    {key = 'right_boundary'},
    {key = 'left_reference'},
    {key = 'right_reference'},
    {key = 'start_x'},
    {key = 'start_w'},
    {key = 'start_lpos'},
    {key = 'start_rpos'},
}

local function trim(value)
    return tostring(value or ''):match('^%s*(.-)%s*$')
end

local function contains(bounds, x, y)
    return bounds and x >= bounds.x and x <= bounds.x + bounds.w and
        y >= bounds.y and y <= bounds.y + bounds.h
end

-- 记录下拉框及弹出列表的实际范围，避免同一次滚轮又滚动轨道列表。
function Gtrack:drawCombobox(id, state, items)
    local x, y, w, h = Nui:widgetBounds()
    self.comboHeaders[id] = {x = x, y = y, w = w, h = h}
    if Nui:comboboxBegin(items[state.value] or items[1]) then
        local px, py, pw, ph = Nui:windowGetBounds()
        self.comboPopup = {x = px, y = py, w = pw, h = ph}
        Nui:layoutRow('dynamic', h, 1)
        for index, label in ipairs(items) do
            if Nui:comboboxItem(label) then
                state.value = index
                Nui:comboboxClose()
                break
            end
        end
        Nui:comboboxEnd()
    end
end

-- 空白端点表示不限；数字填写错误时不显示匹配结果。
local function inRange(value, bounds)
    local fromText, toText = trim(bounds.from.value), trim(bounds.to.value)
    if fromText == '' and toText == '' then return true end
    local from = fromText ~= '' and tonumber(fromText) or nil
    local to = toText ~= '' and tonumber(toText) or nil
    if (fromText ~= '' and not from) or (toText ~= '' and not to) then return false end
    if type(value) ~= 'number' then return false end
    if from and to and from > to then from, to = to, from end
    return (not from or value >= from) and (not to or value <= to)
end

function Gtrack:matches(trackId, position, name)
    if not self.turnOnFilter.value then return true end
    local mode = self.filterMode.value
    if mode == 1 then
        return inRange(position.x, self.range.x) and inRange(position.w, self.range.w)
    elseif mode == 2 then
        local query = trim(self.nameQuery.value):lower()
        return query == '' or tostring(name or ''):lower():find(query, 1, true) ~= nil
    elseif mode == 3 then
        local field = settingFields[self.settingIndex.value] or settingFields[1]
        local actual = ChartService:getTrackField(trackId, field.key)
        if field.switch then return tonumber(actual) == self.switchValue.value - 1 end
        local query = trim(self.settingQuery.value)
        if query == '' then return true end
        if type(actual) == 'number' then return tonumber(query) == actual end
        return tostring(actual or ''):lower():find(query:lower(), 1, true) ~= nil
    end
    return true
end

-- 主窗口通常自行处理滚轮；若 Nuklear 没有移动滚动条，下帧补一次。
function Gtrack:wheelmoved(x, y)
    if sidebar.displayed_content ~= 'track' or demo.open or y == 0 then return end
    local bounds = sidebar.layout
    if mouse.x < bounds.x or mouse.x > bounds.x + bounds.w or
        mouse.y < bounds.y or mouse.y > bounds.y + bounds.h then return end
    if contains(self.comboPopup, mouse.x, mouse.y) then return end
    for _, combo in pairs(self.comboHeaders or {}) do
        if contains(combo, mouse.x, mouse.y) then return end
    end

    if not self.pendingWheel or self.pendingWheel == 0 then
        self.wheelStartScroll = self.lastScrollY
    end
    self.pendingWheel = (self.pendingWheel or 0) + y
end

function Gtrack:applyPendingWheel()
    local scrollX, scrollY = Nui:windowGetScroll()
    if self.pendingWheel ~= nil then
        if self.pendingWheel ~= 0 and
            (self.wheelStartScroll == nil or math.abs(scrollY - self.wheelStartScroll) < 0.01) then
            -- 每格约为一条轨道的高度，向下滚动时增加纵向滚动值。
            scrollY = math.max(0, scrollY - self.pendingWheel * self.layout.uiH)
            Nui:windowSetScroll(scrollX, scrollY)
        end
        self.pendingWheel = nil
        self.wheelStartScroll = nil
    end
    local _, actualY = Nui:windowGetScroll()
    self.lastScrollY = actualY
end

function Gtrack:Nui()
    local layout = self.layout
    local allTrack = fTrack:track_get_all_track()
    local allTrackPos = play:get_all_track_pos() or {}

    Nui:layoutRow('dynamic', 32, {0.45, 0.55})
    Nui:label(i18n:get('track_filter.current') .. ': ' .. tostring(track.track))
    if Nui:button(i18n:get('track_filter.edit_current')) then
        sidebar:to('track edit', track.track)
        return
    end

    self:drawFilter()

    Nui:layoutRow('dynamic', layout.uiH, {0.78, 0.22})
    for _, trackId in ipairs(allTrack) do
        local name = ChartService:getTrackField(trackId, 'name')
        local trackType = ChartService:getTrackField(trackId, 'type')
        local position = allTrackPos[trackId] or {x = 0, w = 0}
        if self:matches(trackId, position, name) then
            if Nui:button(trackId .. ' x:' .. tostring(position.x) .. ' w:' ..
                tostring(position.w) .. ' name:' .. tostring(name or '') ..
                ' type:' .. tostring(trackType or '')) then
                track:to(trackId)
            end
            if Nui:button(i18n:get('edit')) then
                sidebar:to('track edit', trackId)
                break
            end
        end
    end
    self:applyPendingWheel()
end

function Gtrack:drawFilter()
    local layout = self.layout.range
    self.comboHeaders = {}
    self.comboPopup = nil
    Nui:layoutRow('dynamic', layout.uiH, 1)
    if Nui:button(i18n:get('track_filter.title')) then
        self.filterExpanded = not self.filterExpanded
    end
    if self.filterExpanded then
        Nui:layoutRow('dynamic', layout.uiH, 1)
        Nui:checkbox(i18n:get('Filter'), self.turnOnFilter)
        self:drawCombobox('mode', self.filterMode, {
            i18n:get('track_filter.position'),
            i18n:get('track_filter.name'),
            i18n:get('track_filter.setting'),
        })

        if self.filterMode.value == 1 then
            Nui:layoutRow('dynamic', layout.uiH, {0.2, 0.4, 0.4})
            Nui:label('')
            Nui:label(i18n:get('track_filter.from'))
            Nui:label(i18n:get('track_filter.to'))
            Nui:label('x')
            ui:edit('field', self.range.x.from)
            ui:edit('field', self.range.x.to)
            Nui:label('w')
            ui:edit('field', self.range.w.from)
            ui:edit('field', self.range.w.to)
        elseif self.filterMode.value == 2 then
            Nui:layoutRow('dynamic', layout.uiH, {0.27, 0.73})
            Nui:label(i18n:get('track_filter.name'))
            ui:edit('field', self.nameQuery)
        else
            local names = {}
            for i, field in ipairs(settingFields) do
                names[i] = i18n:get('track_filter.field.' .. field.key)
            end
            Nui:layoutRow('dynamic', layout.uiH, 1)
            self:drawCombobox('setting', self.settingIndex, names)
            local field = settingFields[self.settingIndex.value] or settingFields[1]
            Nui:layoutRow('dynamic', layout.uiH, {0.27, 0.73})
            Nui:label(i18n:get('track_filter.value'))
            if field.switch then
                self:drawCombobox('switch', self.switchValue, {
                    i18n:get('track_filter.off'), i18n:get('track_filter.on'),
                })
            else
                ui:edit('field', self.settingQuery)
            end
        end
    end
end

return Gtrack
