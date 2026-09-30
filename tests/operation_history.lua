-- 操作历史回归：只使用内存谱面，不启动游戏或写入用户数据。
require('src.utils.room')
require('src.utils.table')

beat = {get = function(_, value) return value[1] + value[2] / value[3] end}
event_type = {'x', 'w', 'lpos', 'rpos'}
meta_chart = {__index = {
    note = {}, event = {}, bpm_list = {}, track = {}, effect = {},
    info = {}, preference = {},
}}
meta_extra_chart_track = {x = {}, w = {}, lpos = {}, rpos = {}, note = {}}
fNote = {sort = function() end}
fEvent = {sort = function() end}
sidebar = {displayed_content = 'operation history', to = function(self, name)
    self.displayed_content = name
end}

local Note = require('src.objects.Note')
local Event = require('src.objects.Event')
local chart = require('src.services.chartService')
redo = require('plugins.redo')

local function check(value, message) assert(value, message) end
local function near(a, b) return math.abs(a - b) < 0.000001 end

chart:setChart({note = {}, event = {}, track = {}})
local hold = Note.new({type = 'hold', track = 1, beat = {2, 0, 1}, beat2 = {5, 0, 1}})
chart:add(hold, 'history.add_hold')
check(#redo.revoke == 1 and redo.revoke[1].action_key == 'history.add_hold', 'single action')
check(near(redo.revoke[1].beat_start, 2) and near(redo.revoke[1].beat_end, 5), 'hold range')

local early = Note.new({type = 'note', track = 1, beat = {1, 1, 4}})
local event = Event.new({type = 'x', track = 1, beat = {6, 0, 1}, beat2 = {9, 1, 2}})
chart:push()
chart:add(early)
chart:add(event)
chart:pop('history.paste')
local timeline, cursor = redo:getHistory()
check(#timeline == 2 and cursor == 2 and timeline[2].action_key == 'history.paste', 'batch action')
check(near(timeline[2].beat_start, 1.25) and near(timeline[2].beat_end, 9.5), 'batch range')

check(redo:jumpTo(0), 'jump to initial state')
check(chart:getNoteCount() == 0 and chart:getEventCount() == 0, 'initial chart contents')
check(sidebar.displayed_content == 'operation history', 'panel remains visible')
timeline, cursor = redo:getHistory()
check(#timeline == 2 and cursor == 0 and timeline[1].action_key == 'history.add_hold', 'undone entries remain')
check(redo:jumpTo(2), 'jump to latest state')
check(chart:getNoteCount() == 2 and chart:getEventCount() == 1, 'latest chart contents')
check(redo:jumpTo(1), 'jump to intermediate state')
check(chart:getNoteCount() == 1 and chart:getEventCount() == 0, 'intermediate chart contents')

chart:add(Note.new({type = 'note', track = 1, beat = {7, 0, 1}}), 'history.add_note')
timeline, cursor = redo:getHistory()
check(#timeline == 2 and cursor == 2 and #redo.redo == 0, 'new action leaves the redo chain empty')
check(timeline[2].action_key == 'history.add_note', 'new action label')

-- 历史树：撤销后放弃的内容保留为分支，不再被丢弃
local rows = redo:getTreeView()
check(#rows == 4, 'tree keeps the abandoned branch')
check(rows[1].is_root and rows[1].status == 'applied', 'root row')
check(rows[2].operation.action_key == 'history.add_hold' and rows[2].is_fork, 'fork node recorded')
check(rows[3].operation.action_key == 'history.paste' and rows[3].status == 'branch', 'undone branch kept')
check(rows[4].operation.action_key == 'history.add_note' and rows[4].status == 'current', 'new action is current')
check(rows[3].depth == 2 and rows[4].depth == 2, 'both branches hang under the fork node')

-- 跨分支跳转：切到被放弃的分支，原分支同样保留
local addNoteNode = rows[4].node
check(redo:jumpToNode(rows[3].node), 'switch to the abandoned branch')
check(chart:getNoteCount() == 2 and chart:getEventCount() == 1, 'branch content replayed')
check(#redo.revoke == 2 and redo.revoke[2].action_key == 'history.paste', 'branch tip becomes current')
rows = redo:getTreeView()
check(rows[4].operation.action_key == 'history.add_note' and rows[4].status == 'branch',
    'the other branch is kept after switching')
check(redo:jumpToNode(rows[1].node) and chart:getNoteCount() == 0 and chart:getEventCount() == 0,
    'jump back to the tree root')
check(#redo.revoke == 0 and #redo:getTreeView() == 4, 'root is current, both branches still listed')
check(redo:jumpToNode(addNoteNode), 'return to the abandoned-then-kept branch')
check(chart:getNoteCount() == 2 and chart:getEventCount() == 0 and #redo.revoke == 2, 'returned branch state')
chart:push()
chart:pop('history.batch_delete')
check(#redo.revoke == 2, 'empty batch is not recorded')

-- 插件入口在侧边栏首页出现，条目显示说明和范围，点击可跳转。
local root = room:new('main')
local edit = room:new('edit')
local side = group:new('sidebar')
local home = group:new('nil')
root:addRoom(edit)
edit:addGroup(side)
side:addGroup(home)
side.displayed_content = 'nil'
function side:to(name) self.displayed_content = name end

-- 假 love：树杈图直接用 love.graphics 设颜色/线宽，测试环境里记录最后一次设置
local lastColor
love = {
    graphics = {
        setColor = function(a, b, c, d)
            if type(a) == 'table' then
                lastColor = {a[1], a[2], a[3], a[4]}
            else
                lastColor = {a, b, c, d}
            end
        end,
        setLineWidth = function() end,
        newFont = function() error('test environment has no font module') end,
    },
}
local labels, buttons, combos, texts, circles, lines = {}, {}, {}, {}, {}, {}
local click, pressPoint, hoverPoint
local function inRect(px, py, x, y, w, h)
    return px ~= nil and px >= x and px <= x + w and py >= y and py <= y + h
end
-- 取被画某个文字（节点下方的操作名）的中心，用来模拟点击该节点
local function centerOf(value)
    for _, item in ipairs(texts) do
        if item.value:find(value, 1, true) then
            return item.x + item.w / 2, item.y + item.h / 2
        end
    end
end
local ui = {
    layoutRow = function() end,
    label = function(_, value) labels[#labels + 1] = value end,
    button = function(_, value)
        buttons[#buttons + 1] = value
        return click and value:find(click, 1, true) ~= nil
    end,
    combobox = function(_, index, items)
        if type(items) == 'table' then combos[#combos + 1] = table.concat(items, ' ') end
        return index
    end,
    widgetBounds = function() return 100, 60, 340, 600 end,
    windowGetContentRegion = function() return 0, 0, 480, 900 end,
    text = function(_, value, x, y, w, h)
        texts[#texts + 1] = {value = value, x = x, y = y, w = w, h = h}
    end,
    circle = function(_, mode, x, y, r)
        circles[#circles + 1] = {mode = mode, x = x, y = y, r = r, color = lastColor}
    end,
    line = function(_, x1, y1, x2, y2)
        lines[#lines + 1] = {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
    end,
    inputIsHovered = function(_, x, y, w, h)
        return inRect(hoverPoint and hoverPoint[1], hoverPoint and hoverPoint[2], x, y, w, h)
    end,
    inputIsMousePressed = function(_, button, x, y, w, h)
        return inRect(pressPoint and pressPoint[1], pressPoint and pressPoint[2], x, y, w, h)
    end,
}
local zh = require('i18n.zh-CN')
local plugin = dofile('plugins/operationHistory.lua')
plugin.init({
    root = root, ui = ui, settings = {theme = 'dark'},
    i18n = {get = function(_, key) return zh[key] or key end},
})
click = '操作历史'
home('Nui')
check(side.displayed_content == 'operation history', 'sidebar navigation')
click = nil
side:getGroup('operation history'):Nui()
check(table.concat(buttons, ' '):find('放置 hold', 1, true), 'localized operation shown')
check(table.concat(labels, ' '):find('2–5', 1, true), 'beat range shown')
click = '1. 放置 hold'
side:getGroup('operation history'):Nui()
check(#redo.revoke == 1 and chart:getNoteCount() == 1, 'click jumps to selected step')

-- 视图可选：切到"所有分支"后把整棵树画成树杈图（圆 + 圆下方的操作名 + 图例）
local panel = side:getGroup('operation history')
labels, buttons, combos, click, texts, circles, lines = {}, {}, {}, nil, {}, {}, {}
panel.view = 2
panel:Nui()
check(table.concat(combos, ' '):find('所有分支', 1, true), 'view selector offered')
check(#buttons == 0, 'graph view draws no buttons')
local function graphText()
    local all = {}
    for _, item in ipairs(texts) do all[#all + 1] = item.value end
    return table.concat(all, ' ')
end
check(graphText():find('粘贴', 1, true) and graphText():find('分支', 1, true),
    'abandoned branch drawn as a node')
check(graphText():find('当前', 1, true), 'current node labelled')
check(#circles == 4 + 4, 'one circle per node plus the legend')
check(#lines == 3, 'every parent-child link is drawn')
local hollowBranch = false
local filledNode = false
for _, item in ipairs(circles) do
    local color = item.color or {}
    if item.mode == 'line' and color[1] == 0.5 and color[2] == 0.5 then hollowBranch = true end
    if item.mode == 'fill' then filledNode = true end
end
check(hollowBranch and filledNode, 'node styles differ by status')

-- 点击圆节点即切换分支：坐标从画出的文字位置反推
pressPoint = {centerOf('粘贴')}
panel:Nui()
pressPoint = nil
check(redo.tree.current.operation and redo.tree.current.operation.action_key == 'history.paste',
    'click on a graph node switches to the abandoned branch')
check(chart:getEventCount() == 1, 'chart contents follow the graph click')

-- 悬停不再切换，只做高亮
hoverPoint = {centerOf('粘贴')}
local before = redo.tree.current
panel:Nui()
hoverPoint = nil
check(redo.tree.current == before, 'hover alone does not switch branch')

labels, buttons, click = {}, {}, nil
panel.view = 1
panel:Nui()
check(#buttons == 3 and table.concat(buttons, ' '):find('粘贴', 1, true),
    'current branch view follows the switch')
plugin.destroy({})
check(side:getGroup('operation history') == nil and home:getObject('operation history navigation') == nil,
    'plugin cleans up its sidebar content')

chart:setChart({note = {}, event = {}, track = {}})
check(#redo.revoke == 0 and #redo.redo == 0, 'switching charts clears history')
local oldEvent = Event.new({type = 'x', track = 1, beat = {2, 0, 1}, beat2 = {4, 0, 1}})
chart:add(oldEvent, 'history.add_x_event')
local movedEvent = oldEvent:copy()
movedEvent:setBeat({1, 0, 1})
movedEvent:setBeat2({6, 0, 1})
chart:push()
chart:add(movedEvent)
chart:delete(oldEvent)
chart:pop('history.move_event_start')
check(near(redo.revoke[2].beat_start, 1) and near(redo.revoke[2].beat_end, 6),
    'editing range includes both previous and new endpoints')
print('PASS: operation history, ranges, jumps, branch tree, sidebar plugin')
