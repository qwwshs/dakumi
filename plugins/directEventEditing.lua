local ctx
--[[
    插件名: directEventEditing
    描述: Event 直观编辑插件，提供可视化的拖拽控制点编辑 event
    作者: qwwshs
    版本: 1.0.0
    依赖: object, input, messageBox, sidebar, chart, beat, fTrack, fEvent, mouse, transIndex, easings, ctx.ui, ctx.i18n

    功能：
    - 拖拽 event 的头/尾控制点
    - 拖拽 bezier 控制点
    - 右键菜单切换过渡类型
    - 添加/删除 bezier 控制点
]]

local ChartService = require("src.services.chartService")
local CoordinateService = require("src.services.coordinateService")
local eventBus = require("src.utils.eventBus")
local editState = require("src.utils.editState") -- 交互状态写入核心，内部模块不反向引用本插件
local directEventEditing = object:new('directEventEditing')

--- 是否开启直观编辑模式
directEventEditing.open = false

--- 当前被拖拽的控制点（nil, 'head', 'tail', 'control1', 'control2', ...）
directEventEditing.catch_point = nil

--- 控制点半径（用于点击检测）
local CONTROL_RADIUS = 20

--- 右键菜单尺寸（px，宽度需容纳 i18n 文本，高度容纳全部菜单项）
local MENU_W = 240
local MENU_H = 160
local MENU_ITEM_H = 25

-- ============================================================
-- 辅助函数
-- ============================================================

--- 获取当前正在编辑的 event
-- @return table|nil event 数据
local function getCurrentEvent()
    if sidebar.displayed_content ~= 'event' then return nil end
    local idx = sidebar.incoming[1]
    if not idx then return nil end
    return ChartService:getEvent(idx)
end

--- 获取 event 的屏幕坐标
-- @tparam Event isevent 事件对象
-- @treturn number c_x 头部 x 坐标
-- @treturn number c_y 头部 y 坐标
-- @treturn number c_x2 尾部 x 坐标
-- @treturn number c_y2 尾部 y 坐标
local function getEventScreenPos(isevent)
    local c_y = CoordinateService:toY(isevent:getBeat())
    local c_y2 = CoordinateService:toY(isevent:getBeat2())
    local c_x = fTrack:to_play_track_x(isevent:getFrom())
    local c_x2 = fTrack:to_play_track_x(isevent:getTo())
    return c_x, c_y, c_x2, c_y2
end

--- 获取 bezier 控制点的屏幕坐标列表
-- @tparam Event isevent 事件对象
-- @tparam number c_x 头部 x 坐标
-- @tparam number c_y 头部 y 坐标
-- @tparam number c_x2 尾部 x 坐标
-- @tparam number c_y2 尾部 y 坐标
-- @treturn table 控制点列表 {{x, y}, ...}
local function getBezierControlPoints(isevent, c_x, c_y, c_x2, c_y2)
    local points = {}
    if isevent:getTransType() ~= 'bezier' then return points end
    local transData = isevent:getTransData()
    for i = 1, #transData, 2 do
        local nowx = transData[i]
        local nowy = transData[i + 1]
        if not (nowx and nowy) then break end
        nowx = c_x + (c_x2 - c_x) * nowx
        nowy = c_y + (c_y2 - c_y) * nowy
        table.insert(points, { x = nowx, y = nowy })
    end
    return points
end

--- 检测鼠标是否在指定点的范围内
-- @tparam number px 点的 x 坐标
-- @tparam number py 点的 y 坐标
-- @tparam number radius 检测半径
-- @treturn boolean 是否在范围内
local function isMouseOnPoint(px, py, radius)
    return math.intersect(mouse.x, mouse.x, px - radius, px + radius) and
           math.intersect(mouse.y, mouse.y, py - radius, py + radius)
end

-- ============================================================
-- 生命周期方法
-- ============================================================

--- 键盘事件：切换直观编辑模式
function directEventEditing:keypressed(key)
    if input('directEventEditing') then
        self.open = not self.open
        editState.demoCaptured = self.open
        if self.open then
            messageBox:add("direct event editing open")
        else
            messageBox:add("direct event editing close")
        end
    end
end

--- 绘制控制点和 bezier 曲线
function directEventEditing:draw()
    if not self.open then return end
    if tabs and not tabs:isSingle() then return end --多标签页时 demo 区域不可交互
    local isevent = getCurrentEvent()
    if not isevent then return end

    local c_x, c_y, c_x2, c_y2 = getEventScreenPos(isevent)

    -- 绘制头/尾控制点
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle('line', c_x, c_y, CONTROL_RADIUS)
    love.graphics.circle('line', c_x2, c_y2, CONTROL_RADIUS)

    -- 绘制 bezier 曲线和控制点
    if isevent:getTransType() == 'bezier' then
        local control_points = { c_x, c_y }
        local bezier_points = getBezierControlPoints(isevent, c_x, c_y, c_x2, c_y2)
        for _, point in ipairs(bezier_points) do
            table.insert(control_points, point.x)
            table.insert(control_points, point.y)
            love.graphics.circle('line', point.x, point.y, CONTROL_RADIUS, 4)
        end
        table.insert(control_points, c_x2)
        table.insert(control_points, c_y2)
        love.graphics.line(control_points)
    end
end

--- 每帧更新：处理拖拽和右键菜单
function directEventEditing:update(dt)
    -- 交互状态同步给核心 editState（sidebar/play 读它判断让位，不直接引用本插件）
    editState.demoCaptured = self.open
    editState.draggingEvent = self.catch_point ~= nil
    -- 松手清除：拖动完成时写入一次撤销记录（还原到拖动前的快照）
    if not love.mouse.isDown(1) and self.catch_point then
        local cur_event = getCurrentEvent() or self.drag_event
        -- 拖拽修改经 setter 进入页面事务，离开事件页时统一产生记录；
        -- drag_before 仅保留用于对比，判断是否有必要刷新页面
        -- 仍处于 catch_point 状态时调用 sidebar:to：leave() 会忽略刷新（不产生记录），
        -- 但 Gevent:to 会把进入基线同步为当前值，之后离开页面时不会重复记录
        if sidebar.displayed_content == 'event' then
            sidebar:to('event', sidebar.incoming[1])
        end
        self.catch_point = nil
        self.drag_before = nil
        self.drag_event = nil
        return
    end

    if not self.open or (tabs and not tabs:isSingle()) then
        self._menuOpen = false
        return
    end
    local isevent = getCurrentEvent()
    if not isevent then
        self._menuOpen = false
        return
    end

    local c_x, c_y, c_x2, c_y2 = getEventScreenPos(isevent)

    -- 处理拖拽
    if love.mouse.isDown(1) then
        if self.catch_point == 'head' then
            -- 拖动头
            local now_beat = beat:toNearby(CoordinateService:yToBeat(mouse.y))
            if beat:get(now_beat) < isevent:getBeat2Value() then
                local oldBeat = isevent:getBeat()
                isevent:setBeat(now_beat)
                if not ChartService:canPlaceEvent(isevent, isevent) then isevent:setBeat(oldBeat) end
            end
            local now_from = fTrack:track_get_near_fence_x()
            isevent:setFrom(math.roundToPrecision(now_from, 1000))

        elseif self.catch_point == 'tail' then
            -- 拖动尾
            local now_beat = beat:toNearby(CoordinateService:yToBeat(mouse.y))
            if beat:get(now_beat) > isevent:getBeatValue() then
                local oldBeat = isevent:getBeat2()
                isevent:setBeat2(now_beat)
                if not ChartService:canPlaceEvent(isevent, isevent) then isevent:setBeat2(oldBeat) end
            end
            local now_to = fTrack:track_get_near_fence_x()
            isevent:setTo(math.roundToPrecision(now_to, 1000))
        end

        -- 拖拽 bezier 控制点
        if isevent:getTransType() == 'bezier' then
            local bezier_points = getBezierControlPoints(isevent, c_x, c_y, c_x2, c_y2)
            local transData = isevent:getTransData()
            for index, point in ipairs(bezier_points) do
                if self.catch_point == 'control' .. index then
                    local nowx = math.roundToPrecision((mouse.x - c_x) / (c_x2 - c_x), 1000)
                    local nowy = math.roundToPrecision((mouse.y - c_y) / (c_y2 - c_y), 1000)
                    transData[(index - 1) * 2 + 1] = nowx
                    transData[(index - 1) * 2 + 2] = nowy
                end
            end
        end

        sidebar:to('event', sidebar.incoming[1])
    end

    -- 上下文菜单只需要激活宿主；把空宿主放到屏幕外，避免透明窗口吞掉谱面输入。
    -- 菜单触发区仍是 demo，弹出的菜单仍由 Nuklear 处理。
    local demo = play.layout.demo
    local region = tabs.layout.region
    self._menuOpen = false
    ctx.ui:stylePush({
        ['window'] = {
            ['background'] = '#00000000',
            ['fixed background'] = '#00000000',
            ['border color'] = '#00000000',
            ['padding'] = { x = 0, y = 0 },
        },
    })
    local menu_host = ctx.ui:windowBegin('directEventEditing', -1000, -1000, 1, 1)
    ctx.ui:stylePop()
    if menu_host then
        -- 保证壳窗口是当前激活窗口（nk_contextual_begin 的 ctx->current == ctx->active 条件）
        ctx.ui:windowSetFocus('directEventEditing')
        if ctx.ui:contextualBegin(MENU_W, MENU_H, demo.x, region.y, demo.w, region.h) then
            self._menuOpen = true
            -- 必须显式设置行布局：nk_contextual_item_text 依赖 row.columns/row.height 分配空间，
            -- 未设置时布局 columns=0，所有 item 宽度为 NaN 而完全不可见（菜单只剩黑色背景）
            ctx.ui:layoutRow('dynamic', MENU_ITEM_H, 1)
            -- 切换过渡类型
            if ctx.ui:contextualItem(ctx.i18n:get('switch trans type')) then
                ChartService:change('history.edit_event', function()
                    if isevent:getTransType() == 'bezier' then
                        isevent:setTransType('easings')
                    else
                        isevent:setTransType('bezier')
                    end
                end)
            end

            -- 切换到下一个曲线类型
            if ctx.ui:contextualItem(ctx.i18n:get('switch the curve to the next type')) then
                ChartService:change('history.edit_event', function()
                    if isevent:getTransType() == 'bezier' then
                        if fEvent.bezier[transIndex.bezier + 1] then
                            transIndex.bezier = transIndex.bezier + 1
                            isevent:setTransData(table.copy(fEvent.bezier[transIndex.bezier]))
                        end
                    else
                        if easings[transIndex.easings + 1] then
                            transIndex.easings = transIndex.easings + 1
                            isevent:setEasings(transIndex.easings)
                        end
                    end
                end)
            end

            -- 切换到上一个曲线类型
            if ctx.ui:contextualItem(ctx.i18n:get('switch the curve back to the previous type')) then
                ChartService:change('history.edit_event', function()
                    if isevent:getTransType() == 'bezier' then
                        if fEvent.bezier[transIndex.bezier - 1] then
                            transIndex.bezier = transIndex.bezier - 1
                            isevent:setTransData(table.copy(fEvent.bezier[transIndex.bezier]))
                        end
                    else
                        if easings[transIndex.easings - 1] then
                            transIndex.easings = transIndex.easings - 1
                            isevent:setEasings(transIndex.easings)
                        end
                    end
                end)
            end

            -- bezier 控制点操作
            if isevent:getTransType() == 'bezier' then
                -- 控制点直接改 trans 数组（未经 setter），需先显式快照再入事务
                if ctx.ui:contextualItem(ctx.i18n:get('add control point')) then
                    ChartService:change('history.edit_event', function()
                        ChartService:snapshotEntity(isevent)
                        local x = (mouse.x - c_x) / (c_x2 - c_x)
                        local y = (mouse.y - c_y) / (c_y2 - c_y)
                        local td = isevent:getTransData()
                        table.insert(td, x)
                        table.insert(td, y)
                    end)
                end
                if ctx.ui:contextualItem(ctx.i18n:get('delete control point')) then
                    ChartService:change('history.edit_event', function()
                        ChartService:snapshotEntity(isevent)
                        local td = isevent:getTransData()
                        if #td > 2 then
                            table.remove(td, #td)
                            table.remove(td, #td)
                        end
                    end)
                end
            end

            ctx.ui:contextualEnd()
            sidebar:to('event', sidebar.incoming[1])
        end
    end
    ctx.ui:windowEnd()
end

--- 鼠标按下：检测控制点点击
function directEventEditing:mousepressed(x, y, button, istouch, presses)
    if not self.open then return end
    if tabs and not tabs:isSingle() then return end --多标签页时 demo 区域不可交互
    local isevent = getCurrentEvent()
    if not isevent then return end

    local c_x, c_y, c_x2, c_y2 = getEventScreenPos(isevent)

    if love.mouse.isDown(1) then
        -- 检测头控制点
        if isMouseOnPoint(c_x, c_y, CONTROL_RADIUS) then
            self.catch_point = 'head'
            self.drag_before = isevent:copy()
            self.drag_event = isevent
            return
        end

        -- 检测尾控制点
        if isMouseOnPoint(c_x2, c_y2, CONTROL_RADIUS) then
            self.catch_point = 'tail'
            self.drag_before = isevent:copy()
            self.drag_event = isevent
            return
        end

        -- 检测 bezier 控制点
        if isevent:getTransType() == 'bezier' then
            local bezier_points = getBezierControlPoints(isevent, c_x, c_y, c_x2, c_y2)
            for index, point in ipairs(bezier_points) do
                if isMouseOnPoint(point.x, point.y, CONTROL_RADIUS) then
                    self.catch_point = 'control' .. index
                    self.drag_before = isevent:copy()
                    self.drag_event = isevent
                    return
                end
            end
        end
    end
end

-- 注册信息由 plugins/init.lua 读取；生命周期仍使用对象的冒号方法。
directEventEditing.plugin = {
    name = 'directEventEditing',
    version = '1.0.0',
    target = 'edit/play',
    layer = 130,
    init = function(context) ctx = context end,
    destroy = function() ctx = nil end,
    export = 'directEventEditing', -- 保留编辑器现有对象引用
}

return directEventEditing
