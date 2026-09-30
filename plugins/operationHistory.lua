--[[
    插件名: operationHistory
    描述: 在侧边栏显示可跳转的操作历史（历史树）；可在"当前分支"与"所有分支"之间切换

    历史树把每次被撤销后放弃的内容保留成分支：当前分支视图与线性撤销栈一致；
    所有分支视图把整棵树画成树杈图——每个历史节点是一个圆，圆下方写操作名，
    被撤销后放弃的分支留在树上（颜色更暗），点击任意节点即可切换过去
    （见 plugins/redo.lua 的 getTreeView / jumpToNode）。
]]

local sidebarRoom, homeGroup, panel, nav

local VIEW_CURRENT, VIEW_ALL = 1, 2

-- 树杈图几何参数（单位：像素，Nuklear 坐标）
local NODE_R = 6     -- 节点圆半径
local LEVEL_H = 56   -- 相邻层间距：圆 + 下方文字 + 连线留白
local LEGEND_H = 20  -- 顶部图例高度
local TOP_PAD = 4
local SIDE_PAD = 10
local LABEL_GAP = 3  -- 文字与圆底的间距
local MIN_SLOT = 34  -- 单个叶子槽位的最小宽度（决定文字最多能写多长）

local measureFont -- 量文字宽度用的字体（惰性获取，避免插件注册时访问图形模块）

local function formatBeat(value)
    if value == nil then return '?' end
    return string.format('%.8f', value):gsub('0+$', ''):gsub('%.$', '')
end

local function operationName(i18n, operation)
    return i18n:get(operation.action_key or 'history.other')
end

local function beatRange(i18n, operation)
    return i18n:get('history.beat_range') .. ': ' ..
        formatBeat(operation.beat_start) .. '–' .. formatBeat(operation.beat_end)
end

-- 按 UTF-8 字符切分（不依赖 utf8 库，LuaJIT 下同样可用）
local function utf8Chars(s)
    local chars, i, len = {}, 1, #s
    while i <= len do
        local b = s:byte(i)
        local n = 1
        if b >= 0xF0 then n = 4
        elseif b >= 0xE0 then n = 3
        elseif b >= 0xC0 then n = 2 end
        chars[#chars + 1] = s:sub(i, i + n - 1)
        i = i + n
    end
    return chars
end

local function measure()
    if measureFont == nil then
        if type(FONT) == 'table' and FONT.normal then
            measureFont = FONT.normal
        else
            local ok, font = pcall(love.graphics.newFont, 13)
            measureFont = ok and font or false
        end
    end
    return measureFont
end

local function textWidth(s)
    local font = measure()
    if font then return font:getWidth(s) end
    return #s * 7
end

local function textHeight()
    local font = measure()
    if font then return font:getHeight() end
    return 16
end

--- 超出宽度时截断并加省略号（按字符裁剪，中文不会被切成半个字）
local function elide(s, maxW)
    if maxW <= 0 then return '' end
    if textWidth(s) <= maxW then return s end
    local chars = utf8Chars(s)
    local out = ''
    for i = 1, #chars do
        if textWidth(out .. chars[i] .. '…') > maxW then break end
        out = out .. chars[i]
    end
    return out .. '…'
end

return {
    name = 'operationHistory',
    version = '1.2.0',
    description = '侧边栏操作历史',
    target = 'edit/sidebar',

    init = function(ctx)
        sidebarRoom = ctx.root:findContainer('edit/sidebar')
        homeGroup = sidebarRoom:getGroup('nil')
        panel = group:new('operation history')
        nav = object:new('operation history navigation')
        panel.view = VIEW_CURRENT -- 会话级视图选择，不写入用户设置

        function nav:Nui()
            if ctx.ui:button(ctx.i18n:get('operation history')) then
                sidebarRoom:to('operation history')
            end
        end

        -- 当前分支：与撤销栈一致的时间线（已完成 → 当前位置 → 可重做的记录）
        function panel:NuiBranch(history, cursor, forks)
            ctx.ui:layoutRow('dynamic', 25, 1)
            ctx.ui:label(ctx.i18n:get('history.click_to_jump'))
            if #history == 0 then
                ctx.ui:label(ctx.i18n:get('history.empty'))
                return
            end

            ctx.ui:layoutRow('dynamic', 32, 1)
            local initialStatus = cursor == 0 and 'history.current' or 'history.before_first'
            if ctx.ui:button(ctx.i18n:get('history.initial') .. ' (' ..
                ctx.i18n:get(initialStatus) .. ')') then
                redo:jumpTo(0)
                return
            end

            for i, operation in ipairs(history) do
                ctx.ui:layoutRow('dynamic', 32, 1)
                local status = i == cursor and 'history.current' or
                    (i < cursor and 'history.applied' or 'history.undone')
                local title = i .. '. ' .. operationName(ctx.i18n, operation) ..
                    ' (' .. ctx.i18n:get(status) .. ')'
                if forks[operation] then title = title .. '  ' .. ctx.i18n:get('history.fork') end
                if ctx.ui:button(title) then
                    redo:jumpTo(i)
                    return
                end
                ctx.ui:layoutRow('dynamic', 20, 1)
                ctx.ui:label('    ' .. beatRange(ctx.i18n, operation))
            end
        end

        -- 树杈图数据缓存：树没变（redo.rev 相同）就不重复算布局
        local graphCache = {rev = -1}

        --- 后序分配叶子槽位：叶子依次占位，父节点居中于子树。
        -- 这样单链历史是一列竖直的圆，分叉处两个兄弟并排，连线不会互相穿插太乱。
        local function layoutGraph(root)
            local slots, depth = {}, {}
            local nextSlot, maxDepth = 0, 0
            local stack = {{node = root, depth = 0, ready = false}}
            while #stack > 0 do
                local top = stack[#stack]
                local node = top.node
                if top.ready then
                    table.remove(stack)
                    if #node.children == 0 then
                        slots[node] = nextSlot
                        nextSlot = nextSlot + 1
                    else
                        local sum = 0
                        for _, child in ipairs(node.children) do
                            sum = sum + slots[child]
                        end
                        slots[node] = sum / #node.children
                    end
                else
                    top.ready = true
                    depth[node] = top.depth
                    if top.depth > maxDepth then maxDepth = top.depth end
                    for i = #node.children, 1, -1 do
                        stack[#stack + 1] =
                            {node = node.children[i], depth = top.depth + 1, ready = false}
                    end
                end
            end
            return slots, depth, math.max(nextSlot, 1), maxDepth
        end

        local function graphData()
            local rev = redo and redo.rev or 0
            if graphCache.rev == rev then return graphCache end
            local rows = redo and redo:getTreeView() or {}
            local status = {}
            for _, entry in ipairs(rows) do
                status[entry.node] = entry.status
            end
            local root = rows[1] and rows[1].node
            local slots, depth, leafCount, maxDepth = {}, {}, 1, 0
            if root then
                slots, depth, leafCount, maxDepth = layoutGraph(root)
            end
            graphCache = {
                rev = rev, rows = rows, status = status, root = root,
                slots = slots, depth = depth,
                leafCount = leafCount, maxDepth = maxDepth,
            }
            return graphCache
        end

        local function palette()
            if ctx.settings and ctx.settings.theme == 'light' then
                return {
                    text = {0.12, 0.12, 0.12},
                    dim = {0.52, 0.52, 0.52},
                    line = {0.62, 0.62, 0.62},
                    current = {0.12, 0.44, 0.62},
                }
            end
            return {
                text = {0.90, 0.90, 0.90},
                dim = {0.50, 0.50, 0.50},
                line = {0.44, 0.44, 0.44},
                current = {0.24, 0.62, 0.86},
            }
        end

        --- 节点圆的画法：当前=实心亮蓝，已完成=实心灰，已撤销=空心蓝，放弃的分支=空心暗灰
        local function nodeStyle(state, colors)
            if state == 'current' then return true, colors.current, NODE_R + 1 end
            if state == 'applied' then return true, colors.line, NODE_R end
            if state == 'undone' then return false, colors.current, NODE_R end
            return false, colors.dim, NODE_R
        end

        -- 所有分支：整棵历史树的树杈图；圆=历史节点，圆下方=这一步做了什么，点击切换分支
        function panel:NuiGraph()
            local data = graphData()
            local rows = data.rows

            ctx.ui:layoutRow('dynamic', 25, 1)
            ctx.ui:label(ctx.i18n:get('history.switch_branch_hint'))
            if #rows <= 1 then
                ctx.ui:layoutRow('dynamic', 22, 1)
                ctx.ui:label(ctx.i18n:get('history.empty'))
                return
            end

            local colors = palette()
            local fontH = textHeight()
            local canvasH = LEGEND_H + TOP_PAD + (data.maxDepth + 1) * LEVEL_H + TOP_PAD
            ctx.ui:layoutRow('dynamic', canvasH, 1)
            local bx, by, bw = ctx.ui:widgetBounds()
            ctx.ui:label('') -- 占位：让布局游标跨过整块画布，图形随后画在上面

            -- ui:text 在 C 层用 love.graphics.getFont() 注册字体（每帧每句一次，
            -- 上限 1024），这里显式指定正文字体，否则会用上一帧残留的字体：
            -- 中文字形会退化成方块，宽度也对不上
            local font = measure()
            if font then love.graphics.setFont(font) end

            local slotW = math.max(MIN_SLOT, (bw - SIDE_PAD * 2) / data.leafCount)
            local graphW = slotW * data.leafCount
            local x0 = bx + (bw - graphW) / 2
            local y0 = by + LEGEND_H + TOP_PAD

            local function nodeX(node) return x0 + (data.slots[node] + 0.5) * slotW end
            local function nodeTop(node) return y0 + data.depth[node] * LEVEL_H end
            local function labelY(node) return nodeTop(node) + NODE_R * 2 + LABEL_GAP end

            -- 命中判定限制在窗口可见内容区内，滚出视野的节点不接受点击
            local cx, cy, cw, ch = ctx.ui:windowGetContentRegion()
            local viewBottom = cy + ch
            local function hitTest(hx, hy, hw, hh)
                local x1 = math.max(hx, cx)
                local y1 = math.max(hy, cy)
                local x2 = math.min(hx + hw, cx + cw)
                local y2 = math.min(hy + hh, cy + ch)
                if x2 <= x1 or y2 <= y1 then return nil end
                return x1, y1, x2 - x1, y2 - y1
            end

            -- 图例：四种节点含义
            local legend = {
                {text = ctx.i18n:get('history.current'), fill = true, color = colors.current},
                {text = ctx.i18n:get('history.applied'), fill = true, color = colors.line},
                {text = ctx.i18n:get('history.undone'), fill = false, color = colors.current},
                {text = ctx.i18n:get('history.branch'), fill = false, color = colors.dim},
            }
            local legendW = 0
            for _, item in ipairs(legend) do
                item.w = textWidth(item.text)
                legendW = legendW + 8 + 4 + item.w + 14
            end
            local lx = bx + math.max(4, (bw - legendW) / 2)
            local ly = by + 3
            for _, item in ipairs(legend) do
                love.graphics.setLineWidth(2)
                love.graphics.setColor(item.color)
                ctx.ui:circle(item.fill and 'fill' or 'line', lx + 4, ly + fontH / 2, 4)
                love.graphics.setColor(colors.text)
                ctx.ui:text(item.text, lx + 12, ly, item.w, fontH)
                lx = lx + 8 + 4 + item.w + 14
            end

            -- 连线：从父节点文字下方连到子节点圆顶；放弃的分支用更暗的线
            love.graphics.setLineWidth(1)
            for _, entry in ipairs(rows) do
                local node = entry.node
                if #node.children > 0 then
                    local px = nodeX(node)
                    local py = labelY(node) + fontH + 2
                    for _, child in ipairs(node.children) do
                        local state = data.status[child] or 'applied'
                        love.graphics.setColor(state == 'branch' and colors.dim or colors.line)
                        ctx.ui:line(px, py, nodeX(child), nodeTop(child) - 2)
                    end
                end
            end

            -- 节点圆 + 圆下方的操作名
            local hovered
            local clicked
            for _, entry in ipairs(rows) do
                local node = entry.node
                local x = nodeX(node)
                local state = entry.status or 'applied'
                local filled, color, r = nodeStyle(state, colors)
                love.graphics.setLineWidth(2)
                love.graphics.setColor(color)
                ctx.ui:circle(filled and 'fill' or 'line', x, nodeTop(node) + r, r)

                local text = entry.is_root and ctx.i18n:get('history.initial')
                    or operationName(ctx.i18n, entry.operation)
                if state ~= 'applied' then
                    text = text .. ' · ' .. ctx.i18n:get('history.' .. state)
                end
                local maxW = slotW - 6
                local shown = elide(text, maxW)
                local tw = math.max(textWidth(shown), 1)
                -- 视野外的文字不画：ui:text 每句都要在 C 层注册一次字体（每帧上限 1024），
                -- 长历史滚出视野后没必要占额度
                local ly = labelY(node)
                local visible = (ly + fontH) >= cy and ly <= viewBottom
                if visible then
                    love.graphics.setColor(state == 'branch' and colors.dim or colors.text)
                    ctx.ui:text(shown, x - tw / 2, ly, tw, fontH)
                end

                local hitW = math.max(tw, r * 2 + 10)
                local hitH = r * 2 + LABEL_GAP + fontH + 4
                local hx, hy, hw, hh = hitTest(x - hitW / 2, nodeTop(node) - 2, hitW, hitH)
                if hx then
                    if ctx.ui:inputIsHovered(hx, hy, hw, hh) then
                        love.graphics.setColor(colors.current)
                        ctx.ui:circle('line', x, nodeTop(node) + r, r + 3)
                        hovered = hovered or {text = text, shown = shown, x = x, y = ly}
                    end
                    if ctx.ui:inputIsMousePressed('left', hx, hy, hw, hh) then
                        clicked = node
                    end
                end
            end

            -- 悬停时把被截断的完整操作名补画一遍（最后画，压在其它的文字上）
            if hovered and hovered.text ~= hovered.shown then
                local tw = textWidth(hovered.text)
                love.graphics.setColor(colors.current)
                ctx.ui:text(hovered.text, hovered.x - tw / 2, hovered.y, tw, fontH)
            end
            love.graphics.setColor(1, 1, 1, 1)

            if clicked then
                redo:jumpToNode(clicked)
            end
        end

        function panel:Nui()
            ctx.ui:layoutRow('dynamic', 25, 1)
            ctx.ui:label(ctx.i18n:get('history.view'))
            ctx.ui:layoutRow('dynamic', 28, 1)
            local picked = ctx.ui:combobox(self.view, {
                ctx.i18n:get('history.view_current_branch'),
                ctx.i18n:get('history.view_all_branches'),
            })
            if type(picked) == 'number' then self.view = picked end

            if self.view == VIEW_ALL then
                self:NuiGraph()
                return
            end

            local history, cursor = {}, 0
            local forks = {}
            if redo then
                history, cursor = redo:getHistory()
                for _, entry in ipairs(redo:getTreeView()) do
                    if entry.is_fork and entry.operation then forks[entry.operation] = true end
                end
            end
            self:NuiBranch(history, cursor, forks)
        end

        sidebarRoom:addGroup(panel)
        homeGroup:addObject(nav, 10)
    end,

    destroy = function(ctx)
        if homeGroup and nav then homeGroup:deleteObject(nav) end
        if sidebarRoom and panel then
            if sidebarRoom.displayed_content == 'operation history' then
                sidebarRoom:to('nil')
            end
            sidebarRoom:deleteGroup(panel)
        end
        sidebarRoom, homeGroup, panel, nav = nil, nil, nil, nil
    end,
}
