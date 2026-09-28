--track界面
local ChartService = require("src.services.chartService")
local Gtrack = group:new('track')
Gtrack.type = "track"
Gtrack.range = {x = {from = {value = '0'},to = {value = '0'}},w = {from = {value = '0'},to = {value = '0'}}} --轨道搜索范围
Gtrack.layout = require 'config.layouts.sidebar'.track
Gtrack.turnOnFilter = {}
Gtrack.turnOnFilter.value = false --筛选

-- 主窗口通常自行处理滚轮；若 Nuklear 没有移动滚动条，下帧补一次。
function Gtrack:wheelmoved(x, y)
    if sidebar.displayed_content ~= 'track' or demo.open or y == 0 then return end
    local bounds = sidebar.layout
    if mouse.x < bounds.x or mouse.x > bounds.x + bounds.w or
        mouse.y < bounds.y or mouse.y > bounds.y + bounds.h then return end

    -- 筛选浮窗覆盖在列表上方，不把它的滚轮输入转给后面的列表。
    local range = self.rangeBounds or self.layout.range
    if mouse.x >= range.x and mouse.x <= range.x + range.w and
        mouse.y >= range.y and mouse.y <= range.y + range.h then return end

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
            -- 每格约为一条轨道的两行按钮，向下滚动时增加纵向滚动值。
            scrollY = math.max(0, scrollY - self.pendingWheel * self.layout.uiH * 2)
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
    local allTrackPos = play:get_all_track_pos()
    local xf = tonumber(self.range.x.from.value)
    local xt = tonumber(self.range.x.to.value)
    local wf = tonumber(self.range.w.from.value)
    local wt = tonumber(self.range.w.to.value)
    Nui:layoutRow('dynamic', layout.uiH, layout.cols)
    for i,v in ipairs(allTrack) do
        local track_name = ChartService:getTrackField(v, 'name')
        local track_type = ChartService:getTrackField(v, 'type')
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

        if Nui:button(v.." x:"..x..' w:'..w..'name:'..track_name..' type:'..track_type) then
            track:to(v)
        end
        if Nui:button(i18n:get('edit')) then
            sidebar:to('track edit',v)
        end
        ::next::
    end
    self:applyPendingWheel()
end

function Gtrack:NuiNext() --用于书写筛选条件
    local layout = self.layout.range
    local opened = Nui:windowBegin(i18n:get('range'), layout.x, layout.y, layout.w, layout.h,'border','movable','title')
    if opened then
        local x, y, w, h = Nui:windowGetBounds()
        self.rangeBounds = {x = x, y = y, w = w, h = h}

        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:checkbox(i18n:get('Filter'), self.turnOnFilter)

        Nui:layoutRow('dynamic', layout.uiH, layout.cols)
        Nui:label('x')
        ui:edit('field', self.range.x.from)
        ui:edit('field', self.range.x.to)

        Nui:label('w')
        ui:edit('field', self.range.w.from)
        ui:edit('field', self.range.w.to)
    end
    Nui:windowEnd()
end

return Gtrack
