--track界面
local Gtrack = group:new('track')
Gtrack.type = "track"
Gtrack.range = {x = {from = {value = '0'},to = {value = '0'}},w = {from = {value = '0'},to = {value = '0'}}} --轨道搜索范围
Gtrack.layout = require 'config.layouts.sidebar'.track
Gtrack.turnOnFilter = {}
Gtrack.turnOnFilter.value = false --筛选
function Gtrack:Nui()
    local layout = self.layout
    local allTrack = fTrack:track_get_all_track()
    local allTrackPos = play:get_all_track_pos()
    local xf = tonumber(self.range.x.from.value)
    local xt = tonumber(self.range.x.to.value)
    local wf = tonumber(self.range.w.from.value)
    local wt = tonumber(self.range.w.to.value)
    Nui:layoutRow('dynamic', layout.uiH, layout.cols)
    for i,v in ipairs(allTrack) do
        local track_info = fTrack:get_track_info(v)
        local x = allTrackPos[v].x
        local w = allTrackPos[v].w

        if ((xf and xt) or (wf and wt)) and self.turnOnFilter.value then
            if xf and xt and not (math.intersect(xf,xt,x,x)) and not (wf and wt)  then
                goto next
            elseif wf and wt and not (math.intersect(wf,wt,w,w)) and not (xf and xt) then
                goto next
            elseif not (math.intersect(xf,xt,x,x) and math.intersect(wf,wt,w,w)) then
                goto next
            end
        end

        if Nui:button(v.." x:"..x..' w:'..w..'name:'..track_info.name..' type:'..track_info.type) then
            track:to(v)
        end
        if Nui:button(i18n:get('edit')) then
            sidebar:to('track edit',v)
        end
        ::next::
    end
end

function Gtrack:NuiNext() --用于书写筛选条件
    local layout = self.layout.range
    if Nui:windowBegin(i18n:get('range'), layout.x, layout.y, layout.w, layout.h,'border','movable','title') then

        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:checkbox(i18n:get('Filter'), self.turnOnFilter)

        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:label('x')
        Nui:edit('field', self.range.x.from)
        Nui:edit('field', self.range.x.to)

        Nui:label('w')
        Nui:edit('field', self.range.w.from)
        Nui:edit('field', self.range.w.to)
        Nui:windowEnd()
    end
end

return Gtrack