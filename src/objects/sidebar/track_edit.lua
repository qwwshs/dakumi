--编辑track属性
local GtrackEdit = group:new('track edit')
GtrackEdit.type = "track edit"
GtrackEdit.layout = require 'config.layouts.sidebar'.track_edit
GtrackEdit.track = 0
GtrackEdit.trackName = {value = ''}
GtrackEdit.trackType = {value = 1} --1:xw 2:lposrpos
GtrackEdit.w0thenShow = {value = false}
GtrackEdit.parentTrack = {value = 0} --为0时无父轨道
function GtrackEdit:to(istrack)
    self.track = istrack
    if not chart.track[tostring(istrack)] then
        chart.track[tostring(istrack)] = table.copy(meta_track.__index)
    end
    local track_obj = chart.track[tostring(istrack)]
    self.trackName.value = track_obj.name
    self.parentTrack.value = track_obj.parent
    if track_obj.type == 'xw' then
        self.trackType.value = 1
    elseif track_obj.type == 'lposrpos' then
        self.trackType.value = 2
    end

    if track_obj.w0thenShow == 0 then
        self.w0thenShow.value = true
    else
        self.w0thenShow.value = false
    end
end
function GtrackEdit:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label("track:"..self.track)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)

    Nui:label(i18n:get('track_name'))
    Nui:edit('field', self.trackName)

    Nui:label(i18n:get('note_type'))
    Nui:combobox(self.trackType, {'xw','lposrpos'})

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:checkbox(i18n:get('do_not_hide'), self.w0thenShow)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get('parent'))
    Nui:edit('field', self.parentTrack)
    
end
function GtrackEdit:NuiNext()
    local istrack = self.track
    chart.track[tostring(istrack)].name = self.trackName.value

    if self.trackType.value == 2 then
        chart.track[tostring(istrack)].type = 'lposrpos'
    elseif self.trackType.value == 1 then
        chart.track[tostring(istrack)].type = 'xw'
    end

    if self.w0thenShow.value then
        chart.track[tostring(istrack)].w0thenShow = 1
    else
        chart.track[tostring(istrack)].w0thenShow = 0
    end

    chart.track[tostring(istrack)].parent = tonumber(self.parentTrack.value) or 0
end

return GtrackEdit