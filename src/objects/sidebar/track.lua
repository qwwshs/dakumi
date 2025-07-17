--track界面
local Gtrack = group:new('track')
Gtrack.type = "track"
Gtrack.range = {x = {from = {value = '0'},to = {value = '0'}},w = {from = {value = '0'},to = {value = '0'}}} --轨道搜索范围
Gtrack.layout = require 'config.layouts.sidebar'.track

function Gtrack:Nui()
    local allTrack = track_get_all_track()
    local allTrackPos = play:get_all_track_pos()
    local xf = tonumber(self.range.x.from.value)
    local xt = tonumber(self.range.x.to.value)
    local wf = tonumber(self.range.w.from.value)
    local wt = tonumber(self.range.w.to.value)

    for i,v in ipairs(allTrack) do
        local x = allTrackPos[v].x
        local w = allTrackPos[v].w

        if xf and xt and wf and wt then
            if not (math.intersect(xf,xt,x,x) and math.intersect(wf,wt,w,w)) then
                goto next
            end
        end

        if Nui:button('track:'..v.." x:"..x..' w:'..w) then
            track:to(v)
        end
        ::next::
    end
end

function Gtrack:NuiNext() --用于书写筛选条件
    local layout = self.layout
    if Nui:windowBegin(i18n:get('range'), layout.x, layout.y, layout.w, layout.h,'border','movable','title') then

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