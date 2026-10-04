-- 事件组管理。组内事件使用编辑区的普通事件操作，侧边栏只负责进出编辑模式。
local ChartService = require('src.services.chartService')
local demoInEdit = require('src.objects.play.demoInEdit')
local clipboard = require('src.utils.clipboard') -- 剪贴板数据（核心），不引用 ctrl 插件
local Ggroups = group:new('event groups')
Ggroups.type = 'event groups'
Ggroups.layout = require('config.layouts.sidebar').event_groups
Ggroups.selectedName = nil
Ggroups.nameInput = {value = ''}
Ggroups.previousTrack = nil
Ggroups.previousClipboard = nil
Ggroups.previousEffect = nil

local function showError()
    messageBox:add('event_group.invalid')
end

local function resetPreview()
    demoInEdit:resetTraversal()
    local preview = play and play.getObject and play:getObject('demoPlay')
    if preview then preview:resetTraversal() end
end

function Ggroups:selectGroup(name)
    if ChartService:isEditingEventGroup() then return false end
    if not ChartService:getEventGroup(name) then return false end
    self.selectedName = name
    self.nameInput.value = name
    fEvent.selectedGroupName = name
    if fEvent then fEvent:cleanUp() end
    if fNote then fNote:holdCleanUp() end
    self.previousTrack = track and track.track or 1
    self.previousClipboard = clipboard.tab
    if track then track:to('track', 1) end
    if not ChartService:beginEventGroupEdit(name) then
        if track then track:to('track', self.previousTrack) end
        showError()
        return false
    end
    clipboard.tab = table.copy(clipboard.meta)
    clipboard.mouse_start_pos.down = false
    if play then
        self.previousEffect = play.effect
        play.effect = {}
        play.now_all_track_pos = {}
    end
    resetPreview()
    return true
end

function Ggroups:exitGroup(restoreTrack)
    if not ChartService:isEditingEventGroup() then return true end
    -- 离开事件属性页会提交尚未写入撤销表的改动。
    if sidebar and sidebar.displayed_content == 'event' then
        sidebar:to('event groups')
    end
    local ok = ChartService:finishEventGroupEdit()
    if not ok then showError(); return false end
    if fEvent then fEvent:cleanUp() end
    if self.previousClipboard then
        clipboard.tab = self.previousClipboard
        clipboard.mouse_start_pos.down = false
    end
    self.previousClipboard = nil
    if restoreTrack and track and self.previousTrack then
        track:to('track', self.previousTrack)
    end
    self.previousTrack = nil
    if play then
        play.effect = self.previousEffect or {}
        play.now_all_track_pos = {}
    end
    resetPreview()
    self.previousEffect = nil
    return true
end

function Ggroups:nowBreak()
    return self:exitGroup(true)
end

function Ggroups:load()
    self.selectedName = nil
    self.nameInput.value = ''
end

function Ggroups:update()
    -- 兼容插件直接改 track.track 的情况；常规切换由 track:to 即时退出。
    if ChartService:isEditingEventGroup() and track and track.track ~= 1 then
        if not self:exitGroup(false) then track.track = 1 end
        track.useToTrack.value = tostring(track.track)
    end
end

function Ggroups:Nui()
    local height = self.layout.uiH
    Nui:layoutRow('dynamic', height, 1)
    local editing = ChartService:isEditingEventGroup()
    if editing then
        Nui:label(i18n:get('event_group.selected') .. ': ' .. editing)
        if Nui:button(i18n:get('event_group.exit')) then
            self:exitGroup(true)
        end
        return
    end

    Nui:label(i18n:get('event_group.list'))
    for _, name in ipairs(ChartService:getEventGroupNames()) do
        if Nui:button(name) then
            self:selectGroup(name)
            return
        end
    end
    Nui:label(i18n:get('event_group.name'))
    ui:edit('field', self.nameInput)
    Nui:layoutRow('dynamic', height, 2)
    if Nui:button(i18n:get('event_group.create')) then
        local name = self.nameInput.value
        if ChartService:getEventGroup(name) then
            showError()
        else
            local ok = ChartService:putEventGroup(name, {event = {}}, nil, 'history.add_event_group')
            if ok then self:selectGroup(name) else showError() end
        end
        return
    end
    if Nui:button(i18n:get('event_group.rename')) and self.selectedName then
        local name = self.nameInput.value
        local data = ChartService:getEventGroup(self.selectedName)
        local ok = data and ChartService:putEventGroup(name, data, self.selectedName,
            'history.rename_event_group')
        if ok then
            self.selectedName = name
            fEvent.selectedGroupName = name
        else showError() end
    end
    if self.selectedName and ChartService:getEventGroup(self.selectedName) then
        Nui:layoutRow('dynamic', height, 1)
        if Nui:button(i18n:get('event_group.delete')) then
            ChartService:deleteEventGroup(self.selectedName)
            self.selectedName = nil
            self.nameInput.value = ''
            fEvent.selectedGroupName = ''
        end
    end
end

return Ggroups
