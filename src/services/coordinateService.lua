--[[
    模块名: CoordinateService
    描述: 坐标转换服务层，封装 beat↔屏幕坐标、track↔屏幕坐标的转换
    作者: qwwshs
    依赖: beat (全局), fTrack, fEvent, settings, play, denom, WINDOW

    提供统一的坐标转换接口，降低其他模块对 beat/fTrack/fEvent 的直接耦合。
    插件通过 ctx.coord 访问此服务。
]]

local CoordinateService = {}

-- 先减去屏幕留白，再缩放；鼠标事件与每帧位置使用相同的变换。
function CoordinateService:screenToGame(x, y, window)
    window = window or WINDOW
    return (x - (window.nowW - window.w * window.scale) / 2) / window.scale,
        (y - (window.nowH - window.h * window.scale) / 2) / window.scale
end

--- 将屏幕 Y 坐标转换为 beat 值
-- @tparam number pos 屏幕 Y 坐标
-- @treturn number beat 值
function CoordinateService:yToBeat(pos)
    return (pos - settings.judge_line_y) / (-denom.scale * 100) + beat.nowbeat
end

--- 将 beat 值转换为屏幕 Y 坐标
-- @tparam number|table isbeat beat 值（数字或 {整数, 分子, 分母} 表）
-- @treturn number 屏幕 Y 坐标
function CoordinateService:toY(isbeat)
    if type(isbeat) == "table" then
        return settings.judge_line_y + (beat.nowbeat - beat:get(isbeat)) * denom.scale * 100
    elseif type(isbeat) == "number" then
        return settings.judge_line_y + (beat.nowbeat - isbeat) * denom.scale * 100
    end
end

--- 将 beat 值转换为数值
-- @tparam table beatTable beat 表 {整数, 分子, 分母}
-- @treturn number 数值
function CoordinateService:beatToNumber(beatTable)
    return beat:get(beatTable)
end

--- 将两个 beat 表相加
-- @tparam table|number beat1 第一个 beat
-- @tparam table|number beat2 第二个 beat
-- @treturn table 结果 beat 表
function CoordinateService:addBeat(beat1, beat2)
    return beat:add(beat1, beat2)
end

--- 将两个 beat 表相减
-- @tparam table|number beat1 第一个 beat
-- @tparam table|number beat2 第二个 beat
-- @treturn table 结果 beat 表
function CoordinateService:subBeat(beat1, beat2)
    return beat:sub(beat1, beat2)
end

--- 取最近的 beat 对齐值
-- @tparam number isbeat beat 值
-- @treturn table 对齐后的 {整数, 分子, 分母} 表
function CoordinateService:snapToBeat(isbeat)
    return beat:toNearby(isbeat)
end

--- 将时间转换为 beat 值
-- @tparam table bpmList BPM 列表
-- @tparam number nowtime 时间（秒）
-- @treturn number beat 值
function CoordinateService:timeToBeat(bpmList, nowtime)
    return beat:toBeat(bpmList, nowtime)
end

--- 将 beat 值转换为时间
-- @tparam table bpmList BPM 列表
-- @tparam number|table isbeat beat 值
-- @treturn number 时间（秒）
function CoordinateService:beatToTime(bpmList, isbeat)
    return beat:toTime(bpmList, isbeat)
end

--- 获取指定轨道在指定 beat 处的 x 和 w 值
-- @tparam number trackId 轨道ID
-- @tparam number isbeat beat 值
-- @tparam bool original 是否获取原值（不进行 lrpos 转换）
-- @treturn number x 轨道 x 坐标
-- @treturn number w 轨道宽度
function CoordinateService:getEventValue(trackId, isbeat, original)
    local fEvent = require("src.utils.event")
    return fEvent:get(trackId, isbeat, original)
end

--- 获取事件的过渡值
-- @tparam table isevent 事件数据
-- @tparam number t 过渡进度 (0~1)
-- @treturn number 过渡后的值
function CoordinateService:getEventTrans(isevent, t)
    local fEvent = require("src.utils.event")
    return fEvent:getTrans(isevent, t)
end

--- 将谱面坐标转换为播放区域屏幕坐标
-- @tparam number x 谱面 x 坐标
-- @tparam number w 谱面宽度
-- @treturn number 屏幕 x 坐标
-- @treturn number 屏幕宽度
function CoordinateService:trackToScreen(x, w)
    local fTrack = require("src.utils.track")
    return fTrack:to_play_track(x, w)
end

--- 将谱面 x 坐标转换为播放区域屏幕 x 坐标
-- @tparam number x 谱面 x 坐标
-- @treturn number 屏幕 x 坐标
function CoordinateService:trackToScreenX(x)
    local fTrack = require("src.utils.track")
    return fTrack:to_play_track_x(x)
end

--- 将播放区域屏幕 x 坐标转换为谱面 x 坐标
-- @tparam number x 屏幕 x 坐标
-- @treturn number 谱面 x 坐标
function CoordinateService:screenToTrackX(x)
    local fTrack = require("src.utils.track")
    return fTrack:to_chart_track(x)
end

--- 获取所有轨道在当前 beat 的位置信息
-- @treturn table 轨道位置表 { [trackId] = {x, w, track_x, track_w} }
function CoordinateService:getAllTrackPos()
    return play.now_all_track_pos
end

--- 获取所有存在的轨道 ID 列表
-- @treturn table 轨道 ID 数组
function CoordinateService:getAllTrackIds()
    local fTrack = require("src.utils.track")
    return fTrack:track_get_all_track()
end

--- 获取附近的栅栏位置
-- @treturn number 栅栏索引
function CoordinateService:getNearFence()
    local fTrack = require("src.utils.track")
    return fTrack:track_get_near_fence()
end

return CoordinateService
