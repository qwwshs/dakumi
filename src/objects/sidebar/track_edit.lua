--编辑track属性
local ChartService = require("src.services.chartService")
local GtrackEdit = group:new('track edit')
GtrackEdit.breakroom = 'track'
GtrackEdit.type = "track edit"
GtrackEdit.layout = require 'config.layouts.sidebar'.track_edit
GtrackEdit.track = 0
GtrackEdit.trackName = {value = ''}
GtrackEdit.w0thenShow = {value = false}
GtrackEdit.parentTrack = {value = 0} --为0时无父轨道
GtrackEdit.scale_with_parent = {value = false}
GtrackEdit.zindex = {value = 0}
GtrackEdit.left_boundary = {value = 0} -- track 模式填轨道号（0 即轨道 0）；pos 模式填边界线坐标（0 是合法坐标）
GtrackEdit.right_boundary = {value = 0} -- 是否启用只看 boundary_type（'nil' 才不启用）
GtrackEdit.boundary_type = {
    value = 1,
    items = { 'nil', 'track', 'pos' }
} --边界类型: "nil", “track”,'pos'
GtrackEdit.right_reference = {
    value = 1,
    items = { 'x', 'w', 'lpos','rpos' }
} --边界类型: "nil", “track”,'pos'
GtrackEdit.left_reference = {
    value = 1,
    items = { 'x', 'w', 'lpos','rpos' }
} --边界类型: "nil", “track”,'pos'

function GtrackEdit:to(istrack)
    self.track = istrack
    ChartService:ensureTrack(istrack)
    self.trackName.value = ChartService:getTrackField(istrack, 'name')
    self.parentTrack.value = ChartService:getTrackField(istrack, 'parent')
    self.left_boundary.value = ChartService:getTrackField(istrack, 'left_boundary')
    self.right_boundary.value = ChartService:getTrackField(istrack, 'right_boundary')
    self.boundary_type.value = table.find(self.boundary_type.items, ChartService:getTrackField(istrack, 'boundary_type')) or 1
    self.left_reference.value = table.find(self.left_reference.items, ChartService:getTrackField(istrack, 'left_reference')) or 1
    self.right_reference.value = table.find(self.right_reference.items, ChartService:getTrackField(istrack, 'right_reference')) or 1
    if ChartService:getTrackField(istrack, 'w0thenShow') == 0 then
        self.w0thenShow.value = false
    else
        self.w0thenShow.value = true
    end

    if ChartService:getTrackField(istrack, 'scale_with_parent') == 0 then
        self.scale_with_parent.value = false
    else
        self.scale_with_parent.value = true
    end
end
function GtrackEdit:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label("track:"..self.track)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)

    Nui:label(i18n:get('track_name'))
    ui:edit('field', self.trackName)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:checkbox(i18n:get('do_not_hide'), self.w0thenShow)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get('parent'))
    ui:edit('field', self.parentTrack)
    
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:checkbox(i18n:get('Scale with parent'), self.scale_with_parent)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get('zindex'))
    ui:edit('field', self.zindex)
    
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get('boundary_type'))
    Nui:combobox(self.boundary_type, self.boundary_type.items)

    if self.boundary_type.items[self.boundary_type.value] == 'track' then
        Nui:layoutRow('dynamic', self.layout.uiH, 4)
    else
        Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    end

    Nui:label(i18n:get('left_boundary'))
    ui:edit('field', self.left_boundary)

    if self.boundary_type.items[self.boundary_type.value] == 'track' then
        Nui:label(i18n:get('reference'))
        Nui:combobox(self.left_reference, self.left_reference.items)
    end

    if self.boundary_type.items[self.boundary_type.value] == 'track' then
        Nui:layoutRow('dynamic', self.layout.uiH, 4)
    else
        Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    end
    Nui:label(i18n:get('right_boundary'))
    ui:edit('field', self.right_boundary)

    if self.boundary_type.items[self.boundary_type.value] == 'track' then
        Nui:label(i18n:get('reference'))
        Nui:combobox(self.right_reference, self.right_reference.items)
    end


end
function GtrackEdit:NuiNext()
    local istrack = self.track
    ChartService:setTrackField(istrack, 'name', self.trackName.value)
    
    if self.w0thenShow.value then
        ChartService:setTrackField(istrack, 'w0thenShow', 1)
    else
        ChartService:setTrackField(istrack, 'w0thenShow', 0)
    end
 
    if self.scale_with_parent.value then
        ChartService:setTrackField(istrack, 'scale_with_parent', 1)
    else
        ChartService:setTrackField(istrack, 'scale_with_parent', 0)
    end

    ChartService:setTrackField(istrack, 'parent', tonumber(self.parentTrack.value) or 0)
    ChartService:setTrackField(istrack, 'zindex', tonumber(self.zindex.value) or 0)
    ChartService:setTrackField(istrack, 'left_boundary', tonumber(self.left_boundary.value) or 0)
    ChartService:setTrackField(istrack, 'right_boundary', tonumber(self.right_boundary.value) or 0)
    ChartService:setTrackField(istrack, 'boundary_type', self.boundary_type.items[self.boundary_type.value] or 'nil')
    ChartService:setTrackField(istrack, 'left_reference', self.left_reference.items[self.left_reference.value] or 'nil')
    ChartService:setTrackField(istrack, 'right_reference', self.right_reference.items[self.right_reference.value] or 'nil')
end

return GtrackEdit