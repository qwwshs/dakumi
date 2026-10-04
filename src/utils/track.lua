--[[
    模块名: fTrack
    描述: 轨道坐标转换模块，处理谱面坐标 ↔ 屏幕坐标的映射
    作者: qwwshs
    依赖: room；谱面访问接口由 init 传入。
          settings/play/track/math 是遗留运行时状态。
]]

local fTrack = require('src.utils.room').object:new('fTrack')
local ChartService

function fTrack:init(dependencies)
    ChartService = assert(dependencies.chart, 'track requires a chart interface')
end

--- 获取轨道在 play 区域的水平偏移量
-- @treturn number 偏移量（像素）
function fTrack:get_track_offset()
    return (play.layout.demo.w - 100*settings.track_w_scale) / 2
end
--- 将谱面坐标转换为屏幕坐标
-- @tparam number x 谱面 x 坐标
-- @tparam number w 谱面宽度
-- @treturn number 屏幕 x 坐标
-- @treturn number 屏幕宽度
function fTrack:to_play_track(x,w)
    x = x or 0
    w = w  or 0
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    return (x + x_offset -w /2) / event_scale * 100 *settings.track_w_scale + fTrack:get_track_offset(),
    w*settings.track_w_scale / event_scale * 100
end
--- 将谱面坐标转换为屏幕坐标（不含 x_offset 偏移，已废弃）
-- @tparam number x 谱面 x 坐标
-- @tparam number w 谱面宽度
-- @treturn number 屏幕 x 坐标
-- @treturn number 屏幕宽度
function fTrack:to_play_original_track(x,w)
    x = x or 0
    w = w  or 0
    local event_scale = ChartService:getPreferenceField('event_scale')
    return (x-w /2) / event_scale * 100 *settings.track_w_scale + fTrack:get_track_offset(),
    w*settings.track_w_scale / event_scale * 100
end

--- 将谱面 x 坐标转换为屏幕 x 坐标（不含宽度）
-- @tparam number x 谱面 x 坐标
-- @treturn number 屏幕 x 坐标
function fTrack:to_play_track_x(x)
    x = x or 0
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    return (x+ x_offset)/ event_scale * 100 *settings.track_w_scale + fTrack:get_track_offset()
end
--- 将谱面宽度转换为屏幕宽度
-- @tparam number w 谱面宽度
-- @treturn number 屏幕宽度
function fTrack:to_play_track_w(w)
    w = w or 0
    local event_scale = ChartService:getPreferenceField('event_scale')
    return w*settings.track_w_scale / event_scale * 100
end
--- 将屏幕 x 坐标转换为谱面轨道 x 坐标
-- @tparam number x 屏幕 x 坐标
-- @treturn number 谱面轨道 x 坐标
function fTrack:to_chart_track(x)
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
            local track_start_x = fTrack:to_play_track(-x_offset, 0)  
        return (x - track_start_x) / settings.track_w_scale / 100 * event_scale  
end
--- 获取谱面中最大的轨道编号
-- @treturn number 最大轨道编号
function fTrack:track_get_max_track()
    local max_track = 0
    for i = 1, ChartService:getEventCount() do
        local t = ChartService:getEvent(i):getTrack()
        if t > max_track then
            max_track = t
        end
    end
    return max_track
end
--- 获取鼠标附近最近的栅栏位置
-- @treturn number 栅栏编号（从1开始）
function fTrack:track_get_near_fence()  
    local min = 1  
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    local track_start_x = fTrack:to_play_track(-x_offset, 0)  
    local track_end_x = fTrack:to_play_track(-x_offset + event_scale, 0)  
    local track_width = track_end_x - track_start_x  
      
    for i = 1, track.fence do  
        if math.abs((track_width / track.fence * min) - (mouse.x - track_start_x)) >   
           math.abs((track_width / track.fence * i) - (mouse.x - track_start_x)) then  
            min = i  
        end  
    end  
    return min  
end  
--- 获取鼠标附近最近的栅栏对应的谱面 x 坐标
-- @treturn number 谱面 x 坐标
function fTrack:track_get_near_fence_x()  
    local pos = 0  
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    if track.fence == 0 then  
        return self:to_chart_track(mouse.x)
    else  
        pos = (event_scale / track.fence * fTrack:track_get_near_fence()) - x_offset  
    end  
    return pos  
end
--- 获取谱面中所有使用的轨道编号
-- @treturn table 轨道编号数组（已排序）
function fTrack:track_get_all_track()
    local temp_track = {}
    for i = 1, ChartService:getEventCount() do
        temp_track[ChartService:getEvent(i):getTrack()] = 1
    end
    for i = 1, ChartService:getNoteCount() do
        temp_track[ChartService:getNote(i):getTrack()] = 1
    end
    local temp2_track = {} --整理temp_track
    for i,v in pairs(temp_track) do
        temp2_track[#temp2_track + 1] = i
    end
    table.sort(temp2_track)
    return temp2_track
end

return fTrack
