--[[
    模块名: tabs
    描述: 标签页管理器，将右侧 edit 区域拆分为多个标签页窗口
    作者: qwwshs
    依赖: object, Nui, play, track, ChartService, demoInEdit, messageBox, i18n

    功能:
    - 标签页窗口位于 editTool 下方（同长度同 x），拖动条窗口位于其下
    - 一个标签页 = 一个 edit 区域（宽度与 edit 区域相同）
    - + 添加标签页、X 关闭标签页、拖动排序（浏览器式）、双击修改标签页代表的轨道
    - 标签页与其 edit 窗口（轨道）的横坐标时刻保持一致（含拖动、换位与标签条滚动）；
      edit 内容和遮罩由 demoInEdit 实例绘制，顶部位置条与底部信息板由 tabs 用 Nuklear 绘制
    - 每个标签页显示其轨道 note/x/w/lpos/rpos 的合并开关（同时控制可编辑与可复制）
    - 标签页本体（背景/标题/关闭按钮/合并开关/轨道号输入框/+按钮）全部由 nuklear 绘制，
      轨道号输入框内嵌在标签页标题行，输入内容清晰可见
    - 轨道 0 代表 track.track（跟随 editTool 选择的轨道）
    - 新建标签页自动分配谱面中未被占用的轨道；每个 edit 窗口顶部显示 x/w/lpos/rpos
    - 标签页数量为 1 时: demo 区域保持原大小，edit 窗口锁定在 track.track
    - 标签页数量不为 1 时: demo 区域扩大到整个区域且不可交互（覆盖 0.5 透明黑遮罩），
      edit 窗口按标签顺序从左到右排列
]]

local tabs = group:new('tabs')
local ChartService = require("src.services.chartService")
local ThemeService = require("src.services.themeService")
local SpectrogramRuler = require('src.services.spectrogramRuler')
local demoInEdit = require 'src.objects.play.demoInEdit'
tabs.layout = require 'config.layouts.tab'
local infoFont = love.graphics.newFont('assets/fonts/LXGWNeoXiHei.ttf', 10)
infoFont:setFilter('linear', 'nearest')

-- 标签页窗口有独立的 Nuklear 样式，需在每帧按当前主题取色。
local tabColors = {
    dark = {
        border = '#4A4A4A', tab = '#26262B', activeTab = '#45454D',
        draggedTab = '#3D3D47', tabBorder = '#73737A',
        close = {'#4A4A52', '#8C8C8C', '#A0A0A5'},
        laneOn = {'#388CD9', '#2A6FB5', '#1E6F9F'},
        laneOff = {'#525257', '#5E5E63', '#46464B'},
        plus = {'#333338', '#3D3D47', '#45454D'},
        bar = {0.09, 0.09, 0.10}, thumb = {0.35, 0.35, 0.38},
    },
    light = {
        border = '#AAB4C0', tab = '#D9DEE5', activeTab = '#F2F4F7',
        draggedTab = '#C9D4E0', tabBorder = '#9CA8B5',
        close = {'#DDE3EA', '#C8D3DF', '#B6C5D3'},
        laneOn = {'#A6CDEA', '#8FBCDF', '#75AAD2'},
        laneOff = {'#CDD6DF', '#BFCBD6', '#ACBBC9'},
        plus = {'#DDE3EA', '#C8D3DF', '#B6C5D3'},
        bar = {0.82, 0.85, 0.89}, thumb = {0.58, 0.64, 0.71},
    },
}

local function currentTabColors()
    local mode = settings.theme == 'light' and 'light' or 'dark'
    return ThemeService:tabColors(mode, tabColors[mode])
end

local function clamp(v, lo, hi)
    return math.max(lo, math.min(hi, v))
end

-- 频率尺默认收起；展开状态跟随各标签页保存。
local rulerExpanded = setmetatable({}, { __mode = 'k' })
local rulerToggleBounds = {}

--- 新建标签页（默认轨道 0 = 跟随 track.track）
local function newTab(trackId)
    local tab = {
        track = trackId or 0,
        edit = { note = true, x = true, w = true, lpos = true, rpos = true },  -- 各轨道类型可编辑
        copy = { note = true, x = true, w = true, lpos = true, rpos = true },  -- 各轨道类型可复制
        renaming = false,
        renameBuf = { value = '' },
    }
    -- edit 窗口实例：窗口渲染（裁剪/遮罩/标题/内容）由实例自行完成
    tab.editView = demoInEdit:new{ tabbed = true, tab = tab }
    return tab
end

tabs.list = {}
tabs.active = 1          -- 活动标签页
tabs.offset = 0          -- 标签条横向滚动偏移
tabs.maxOffset = 0       -- 最大滚动偏移
tabs.drag = nil          -- 拖拽排序状态 {index, grabX}
tabs.scrollDrag = false  -- 拖动条拖拽状态
tabs._scrollGrab = 0     -- 拖动条按下点相对滑块左缘的偏移
tabs._lastClick = { index = 0, time = 0 } -- 双击检测
tabs._renameRect = nil   -- 重命名输入框位置（标签页标题行）

function tabs:load()
    -- 从 play.layout / WINDOW 推导布局值，避免魔法硬编码
    local ly = self.layout
    local wl = WINDOW or {}
    local pl = play and play.layout
    local w = wl.w or 1600
    local h = wl.h or 900
    local contentW = (pl and (pl.x + pl.w)) or (w - 400 + 20)  -- 1600 - sidebar.w
    local editToolH = 100
    local editToolY = 0

    ly.tabBar = { x = 0, y = editToolY + editToolH, w = contentW, h = 70 }
    ly.scroll = { x = 0, y = ly.tabBar.y + ly.tabBar.h, w = contentW, h = 22 }
    local regionTop = (pl and pl.y) or editToolY + editToolH + ly.tabBar.h + ly.scroll.h
    local regionH = h - regionTop
    ly.region = { y = regionTop, h = regionH }
    ly.tabW = (pl and pl.edit and pl.edit.w) or 300
    ly.demoW = (pl and pl.demo and pl.demo.w) or 900
    ly.regionW = (pl and pl.w) or 1200

    self.list = { newTab(0) }
    self.active = 1
    self.offset = 0
    self.maxOffset = 0
    self.drag = nil
    self.scrollDrag = false
    self._scrollGrab = 0
    self._lastClick = { index = 0, time = 0 }
    self._renameRect = nil
    if ctrl then ctrl:convertTabsClipboardToPlay() end
    self('load')
end

-- ============================================================
-- 查询辅助
-- ============================================================

function tabs:isSingle()
    return ChartService:isEditingEventGroup() ~= nil or #self.list <= 1
end

--- 解析标签页的实际轨道（0 = 跟随 track.track）
function tabs:getTabTrack(tab,org)
    if tab.track == 0 then
        if org then
            return 0
        end
        return track.track
    end
    return tab.track
end

--- 标签条内容总宽度（含行说明槽与 + 按钮）
function tabs:layoutWidth()
    return self.layout.gutter + #self.list * self.layout.tabW + self.layout.plusW
end

--- 标签页 i 的 edit 窗口 x（与标签条中该标签页的横坐标时刻一致，含行说明槽与滚动偏移；
--  拖拽中的标签页跟随鼠标，编辑区域随标签页一起位移）
function tabs:windowX(i)
    if self:isSingle() then
        return play.layout.edit.x
    end
    if self.drag and i == self.drag.index then
        return mouse.x - self.drag.grabX
    end
    local ly = self.layout
    return ly.tabBar.x + ly.gutter - self.offset + (i - 1) * ly.tabW
end

--- 标签页标题：轨道数，有轨道名则为 名字（第几轨）
function tabs:tabTitle(tab)
    local tr = self:getTabTrack(tab)
    local name = ChartService:getTrackField(tr, 'name')
    if name and name ~= '' then
        return name .. ' (' .. tr .. ')'
    end
    return tostring(tr)
end

--- 解析鼠标所在 edit 窗口的轨道类型（多标签页）
-- @treturn number|nil 标签页下标
-- @treturn string|nil 轨道类型
function tabs:getLane(x, y)
    local region = self.layout.region
    if y < region.y or y > region.y + region.h then return nil end
    if self:isSingle() then
        local lane = trackSequence:getType(x)
        if lane then return 1, lane end
        return nil
    end
    for i = 1, #self.list do
        local wx = self:windowX(i)
        if x >= wx and x < wx + self.layout.tabW then
            local k = math.floor((x - wx) / play.layout.edit.interval) + 1
            if k >= 1 and k <= 5 then return i, self.layout.lane[k] end
            return i, nil
        end
    end
    return nil
end

--- 鼠标所在的标签页下标（用于粘贴基准轨道）
function tabs:getTabAtMouse()
    local region = self.layout.region
    if mouse.y < region.y or mouse.y > region.y + region.h then return nil end
    if self:isSingle() then return 1 end
    for i = 1, #self.list do
        local wx = self:windowX(i)
        if mouse.x >= wx and mouse.x < wx + self.layout.tabW then return i end
    end
    return nil
end

-- ============================================================
-- 标签页操作
-- ============================================================

--- 新建标签页并自动分配到当前轨道
function tabs:addTab()
    local used = { [track.track] = true } -- 轨道 0 标签跟随 track.track，跳过当前选中轨道
    for _, t in ipairs(self.list) do
        used[t.track] = true
    end
    local nt = 0
    table.insert(self.list, newTab(nt))
    self.active = #self.list
    self.offset = self.maxOffset
    messageBox:add("tab add")
end

function tabs:closeTab(i)
    if #self.list <= 1 then
        return
    end
    table.remove(self.list, i)
    if self.active == i then
        self.active = math.min(i, #self.list)
    elseif self.active > i then
        self.active = self.active - 1
    end
    if self.active < 1 then self.active = 1 end
    if self.active == 1 then
        self.list[1].track = 0
    end
    if #self.list == 1 and ctrl then
        ctrl:convertTabsClipboardToPlay()
    end
    messageBox:add("tab close")
end

-- ============================================================
-- 重命名
-- ============================================================

function tabs:renamingIndex()
    for i, tab in ipairs(self.list) do
        if tab.renaming then return i end
    end
    return nil
end

function tabs:isRenaming()
    return self:renamingIndex() ~= nil
end

function tabs:startRename(i)
    for k, tab in ipairs(self.list) do
        tab.renaming = (k == i)
    end
    local tab = self.list[i]
    tab.renameBuf = { value = tostring(self:getTabTrack(tab,'org')) }
end

--- 提交输入：把该标签页改为输入的轨道号（0 = 跟随 track.track；非整数则保持原轨道）
function tabs:commitRename()
    local ri = self:renamingIndex()
    if not ri then return end
    local tab = self.list[ri]
    local v = (tab.renameBuf and tab.renameBuf.value) or ''
    v = v:gsub('%s+$', '')
    local n = tonumber(v)
    if n and n >= 0 and n == math.floor(n) then
        tab.track = n
        messageBox:add("tab track change")
    end
    tab.renaming = false
end

function tabs:cancelRename()
    local ri = self:renamingIndex()
    if ri then self.list[ri].renaming = false end
end

-- ============================================================
-- 滚动条
-- ============================================================

function tabs:scrollClick(x)
    if self.maxOffset <= 0 then return end
    local ly = self.layout
    local thumbW = math.max(30, ly.scroll.w * ly.scroll.w / self:layoutWidth())
    local thumbX = ly.scroll.x + (ly.scroll.w - thumbW) * (self.offset / self.maxOffset)
    if x >= thumbX and x <= thumbX + thumbW then
        -- 记录按下点相对滑块左缘的偏移，拖动时滑块跟手
        self.scrollDrag = true
        self._scrollGrab = x - thumbX
    else
        local frac = (x - ly.scroll.x - thumbW / 2) / (ly.scroll.w - thumbW)
        self.offset = clamp(frac * self.maxOffset, 0, self.maxOffset)
    end
end

function tabs:scrollToMouse()
    local ly = self.layout
    local thumbW = math.max(30, ly.scroll.w * ly.scroll.w / self:layoutWidth())
    local thumbX = mouse.x - self._scrollGrab
    local frac = (thumbX - ly.scroll.x) / (ly.scroll.w - thumbW)
    self.offset = clamp(frac * self.maxOffset, 0, self.maxOffset)
end

-- ============================================================
-- nuklear 窗口
-- ============================================================

--- 透明窗口样式（仅边框，区域内容由 love.graphics 绘制）
local function transparentWindow(colors)
    return {
        ['window'] = {
            ['background'] = '#00000000',
            ['fixed background'] = '#00000000',
            ['border color'] = colors.border,
            ['padding'] = { x = 0, y = 0 },
            ['header'] = {
                ['normal'] = '#00000000',
                ['hover'] = '#00000000',
                ['active'] = '#00000000',
            },
        },
    }
end

local function editInfoStyle(light, padding)
    local colors = currentTabColors()
    return {
        ['window'] = {
            ['background'] = colors.info_background or (light and '#E0E5EB' or '#171A1E'),
            ['fixed background'] = colors.info_background or (light and '#E0E5EB' or '#171A1E'),
            ['border color'] = colors.info_border or (light and '#AAB4C0' or '#4A4A4A'),
            ['padding'] = padding,
        },
    }
end

-- 顶部显示轨道位置，底部显示其余信息；两块面板都由 Nuklear 绘制。
local function drawEditInfo(tab, index, x, width)
    local trackId = tabs:getTabTrack(tab)
    local nowX, nowW = fEvent:get(trackId, beat.nowbeat, true)
    local leftPos = nowX - nowW / 2
    local rightPos = nowX + nowW / 2
    local trackName = ChartService:getTrackField(trackId, 'name') or ''
    local hidden = ChartService:getTrackField(trackId, 'w0thenShow') == 0
    local light = settings.theme == 'light'

    local topY = tabs.layout.region.y
    local topHeight = 22
    local topName = 'edit_position_' .. index
    local rulerKey = index == 'event_group' and 'event_group' or tab
    local expanded = rulerExpanded[rulerKey] == true
    Nui:stylePush(editInfoStyle(light, { x = 3, y = 0 }))
    Nui:styleSetFont(infoFont)
    if Nui:windowBegin(topName, x, topY, width, topHeight, 'border', 'background') then
        Nui:layoutRow('dynamic', 18, {0.2, 0.17, 0.22, 0.22, 0.19})
        Nui:label('x:' .. math.roundToPrecision(nowX, 100))
        Nui:label('w:' .. math.roundToPrecision(nowW, 100))
        Nui:label('lpos:' .. math.roundToPrecision(leftPos, 100))
        Nui:label('rpos:' .. math.roundToPrecision(rightPos, 100))
        if settings.spectrogram == 1 and settings.spectrogram_ruler ~= 0 then
            Nui:button(expanded and '^' or 'v')
            rulerToggleBounds[rulerKey] = {
                x = x + width * 0.8, y = topY, w = width * 0.2, h = topHeight,
                index = type(index) == 'number' and index or nil,
            }
        else
            Nui:label('')
        end
    end
    Nui:windowEnd()
    Nui:windowSetBounds(topName, x, topY, width, topHeight)
    Nui:styleSetFont(FONT.normal)
    Nui:stylePop()

    -- 频率控件紧贴位置栏下方；收起时不占编辑区域空间。
    if expanded and settings.spectrogram == 1 and settings.spectrogram_ruler ~= 0 then
        local rulerY = topY + topHeight
        local rulerHeight = 32
        local rulerName = 'edit_spectrogram_ruler_' .. index
        Nui:stylePush(editInfoStyle(light, { x = 3, y = 0 }))
        Nui:styleSetFont(infoFont)
        if Nui:windowBegin(rulerName, x, rulerY, width, rulerHeight, 'border', 'background') then
            SpectrogramRuler:draw(Nui, x, width)
        end
        Nui:windowEnd()
        Nui:windowSetBounds(rulerName, x, rulerY, width, rulerHeight)
        Nui:styleSetFont(FONT.normal)
        Nui:stylePop()
    end

    -- 面板始终从判定线下方开始，不再为了容纳内容向上盖住判定线。
    local y = math.max(tabs.layout.region.y + topHeight, settings.judge_line_y + 20)
    local height = math.max(0, WINDOW.h - y)
    Nui:stylePush(editInfoStyle(light, { x = 6, y = 4 }))
    local name = 'edit_info_' .. index
    if Nui:windowBegin(name, x, y, width, height, 'border', 'background') then
        Nui:layoutRow('dynamic', 24, 2)
        Nui:label(i18n:get('beat') .. ': ' .. math.roundToPrecision(beat.nowbeat, 100))
        Nui:label(i18n:get('time') .. ': ' .. math.roundToPrecision(time.nowtime, 100))
        Nui:layoutRow('dynamic', 24, 2)
        Nui:label(i18n:get('track') .. ': ' .. trackId)
        Nui:label(i18n:get(hidden and 'hide' or 'do_not_hide'))
        Nui:layoutRow('dynamic', 24, 1)
        Nui:label(i18n:get('track_name') .. ': ' .. trackName)
    end
    Nui:windowEnd()
    Nui:windowSetBounds(name, x, y, width, height)
    Nui:stylePop()
end

-- ============================================================
-- 生命周期
-- ============================================================

function tabs:update(dt)
    rulerToggleBounds = {}
    if demo.open then return end
    local editing = ChartService:isEditingEventGroup()
    if editing then
        local ly = self.layout
        play.layout.demo.w = ly.demoW
        self.drag, self.scrollDrag = nil, false
        local name = 'event_group_edit_mode'
        if Nui:windowBegin(name, ly.tabBar.x, ly.tabBar.y, ly.tabBar.w,
            ly.tabBar.h, 'border', 'background') then
            Nui:layoutRow('dynamic', ly.tabBar.h - 12, 1)
            Nui:label(i18n:get('event_group.editing') .. ': ' .. editing)
        end
        Nui:windowEnd()
        drawEditInfo({track = 0}, 'event_group', play.layout.edit.x, ly.tabW)
        return
    end
    self('update', dt)
    local ly = self.layout
    local colors = currentTabColors()

    -- 拖动条拖拽
    if self.scrollDrag then
        if love.mouse.isDown(1) then
            self:scrollToMouse()
        else
            self.scrollDrag = false
        end
    end

    -- 标签拖拽排序（浏览器式，实时换位；重命名时不响应拖拽）
    if self.drag and not self:isRenaming() then
        if love.mouse.isDown(1) then
            local curX = mouse.x - self.drag.grabX
            local target = clamp(math.floor((curX - (ly.tabBar.x - self.offset) + ly.tabW / 2) / ly.tabW) + 1, 1, #self.list)
            if target ~= self.drag.index then
                local tab = table.remove(self.list, self.drag.index)
                table.insert(self.list, target, tab)
                if self.active == self.drag.index then
                    self.active = target
                elseif self.drag.index < self.active and target >= self.active then
                    self.active = self.active - 1
                elseif self.drag.index > self.active and target <= self.active then
                    self.active = self.active + 1
                end
                self.drag.index = target
            end
        else
            self.drag = nil
        end
    end

    self.maxOffset = math.max(0, self:layoutWidth() - ly.tabBar.w)
    self.offset = clamp(self.offset, 0, self.maxOffset)

    -- demo 宽度随标签页数量切换
    if self:isSingle() then
        play.layout.demo.w = ly.demoW
    else
        play.layout.demo.w = ly.regionW
    end

    -- 区域窗口（透明边框壳，内容由 love.graphics 绘制）
    Nui:stylePush(transparentWindow(colors))
    -- 标签条底板窗口
    if Nui:windowBegin('tabs', ly.tabBar.x, ly.tabBar.y, ly.tabBar.w, ly.tabBar.h, 'border', 'background') then
        Nui:windowEnd()
    end
    -- 拖动条窗口
    if Nui:windowBegin('tabs_scroll', ly.scroll.x, ly.scroll.y, ly.scroll.w, ly.scroll.h, 'border', 'background') then
        Nui:windowEnd()
    end
    -- demo 窗口
    local demoW = self:isSingle() and ly.demoW or ly.regionW
    if Nui:windowBegin('demo_area', play.layout.demo.x, ly.region.y, demoW, ly.region.h, 'border', 'background') then
        Nui:windowEnd()
    end
    Nui:windowSetBounds('demo_area', play.layout.demo.x, ly.region.y, demoW, ly.region.h)
    -- edit 窗口（每个标签页一个）
    for i = 1, #self.list do
        local name = 'edit_area' .. i
        local wx = self:windowX(i)
        self.list[i].editView.x = wx -- 窗口左缘每帧与标签页横坐标保持一致
        if Nui:windowBegin(name, wx, ly.region.y, ly.tabW, ly.region.h, 'border', 'background') then
            Nui:windowEnd()
        end
        Nui:windowSetBounds(name, wx, ly.region.y, ly.tabW, ly.region.h)
    end
    Nui:stylePop()

    for i, tab in ipairs(self.list) do
        drawEditInfo(tab, i, self:windowX(i), ly.tabW)
    end

    -- 标签页窗口（标签页本体全部由 nuklear 绘制）
    local closeIdx = nil -- 关闭按钮点击延迟到循环后处理，避免遍历中修改列表
    for i = 1, #self.list do
        local tab = self.list[i]
        local name = 'tab' .. i
        local tx = self:windowX(i)
        local bg = colors.tab
        if i == self.active then bg = colors.activeTab end
        if self.drag and i == self.drag.index then bg = colors.draggedTab end
        Nui:stylePush({
            ['window'] = {
                ['background'] = bg,
                ['fixed background'] = bg,
                ['border color'] = colors.tabBorder,
                ['padding'] = { x = 2, y = 2 },
            },
        })
        if Nui:windowBegin(name, tx + 1, ly.tabBar.y + 1, ly.tabW - 2, ly.tabBar.h - 2, 'border') then
            if tab.renaming then
                -- 轨道号输入框（内嵌标题行，标签页背景不透明，内容清晰可见）
                Nui:layoutRow('dynamic', ly.titleH - 6, 1)
                ui:edit('simple', tab.renameBuf)
            else
                -- 标题 + 关闭按钮
                Nui:layoutRow('dynamic', ly.titleH - 6, { (ly.tabW - ly.closeW) / ly.tabW, ly.closeW / ly.tabW })
                local str = ''
                if tab.track == 0 then
                    str = '('..i18n:get('now_track')..')'
                end
                Nui:label(self:tabTitle(tab)..str)
                Nui:stylePush({
                    ['button'] = {
                        ['normal'] = colors.close[1],
                        ['hover'] = colors.close[2],
                        ['active'] = colors.close[3],
                    },
                })
                if Nui:button('x') then
                    closeIdx = i
                end
                Nui:stylePop()
            end
            -- 标题行与合并开关行之间的空隙
            Nui:layoutRow('dynamic', ly.gapH, 1)
            Nui:label('')
            -- 合并开关行（编/复合并：同一开关同时控制可编辑与可复制）
            Nui:layoutRow('dynamic', ly.rowH, 5)
            for k = 1, 5 do
                local lane = ly.lane[k]
                local on = tab.edit[lane]
                Nui:stylePush({
                    ['button'] = {
                        ['normal'] = on and colors.laneOn[1] or colors.laneOff[1],
                        ['hover'] = on and colors.laneOn[2] or colors.laneOff[2],
                        ['active'] = on and colors.laneOn[3] or colors.laneOff[3],
                    },
                })
                if Nui:button(lane) then
                    tab.edit[lane] = not on
                    tab.copy[lane] = tab.edit[lane]
                end
                Nui:stylePop()
            end
            Nui:windowEnd()
        end
        Nui:stylePop()
        Nui:windowSetBounds(name, tx + 1, ly.tabBar.y + 1, ly.tabW - 2, ly.tabBar.h - 2)
    end
    if closeIdx then
        self:closeTab(closeIdx)
    end

    -- + 按钮窗口（始终创建，避免 windowBegin 返回 false 导致按钮失效）
    local contentX = ly.tabBar.x + ly.gutter - self.offset
    local px = contentX + #self.list * ly.tabW
    local plusVisible = px < ly.tabBar.x + ly.tabBar.w
    local bx = plusVisible and (px + ly.hitPad) or -200
    local bp = ly.buttonPad
    Nui:stylePush(transparentWindow(colors))
    if Nui:windowBegin('tabs_plus', bx, ly.tabBar.y + bp, ly.plusW - bp * 2, ly.tabBar.h - bp * 2) then
        Nui:layoutRow('dynamic', ly.tabBar.h - bp * 2 - 2, 1)
        Nui:stylePush({
            ['button'] = {
                ['normal'] = colors.plus[1],
                ['hover'] = colors.plus[2],
                ['active'] = colors.plus[3],
            },
        })
        if Nui:button('+') then
            self:addTab()
        end
        Nui:stylePop()
        Nui:windowEnd()
    end
    Nui:stylePop()
    Nui:windowSetBounds('tabs_plus', bx, ly.tabBar.y + bp, ly.plusW - bp * 2, ly.tabBar.h - bp * 2)

    -- 拖拽中的标签页与重命名中的标签页保持在最上层
    if self.drag then
        Nui:windowSetFocus('tab' .. self.drag.index)
    end
    local ri = self:renamingIndex()
    if ri then
        local tx = self:windowX(ri)
        self._renameRect = { x = tx, y = ly.tabBar.y, w = ly.tabW, h = ly.titleH }
        Nui:windowSetFocus('tab' .. ri)
    else
        self._renameRect = nil
    end

end

-- 展开按钮由主鼠标事件优先处理，避免点击被编辑区当作放置操作。
function tabs:handleRulerToggleClick(x, y, button)
    if button ~= 1 then return false end
    for key, r in pairs(rulerToggleBounds) do
        if x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h then
            rulerExpanded[key] = not rulerExpanded[key]
            if r.index then self.active = r.index end
            return true
        end
    end
    return false
end

function tabs:draw()
    if demo.open then return end
    if ChartService:isEditingEventGroup() then return end
    --限制绘制范围，避免超过范围到sidebar区域
    local ly = self.layout
    local colors = currentTabColors()

    -- 标签条底板（覆盖其下的节拍线，标签页本体由 nuklear 绘制在其上）
    love.graphics.setColor(colors.bar)
    love.graphics.rectangle('fill', ly.tabBar.x, ly.tabBar.y, ly.tabBar.w, ly.tabBar.h)
    -- 拖动条底板与 thumb
    love.graphics.setColor(colors.bar)
    love.graphics.rectangle('fill', ly.scroll.x, ly.scroll.y, ly.scroll.w, ly.scroll.h)
    if self.maxOffset > 0 then
        local thumbW = math.max(30, ly.scroll.w * ly.scroll.w / self:layoutWidth())
        local thumbX = ly.scroll.x + (ly.scroll.w - thumbW) * (self.offset / self.maxOffset)
        love.graphics.setColor(colors.thumb)
        love.graphics.rectangle('fill', thumbX, ly.scroll.y + 3, thumbW, ly.scroll.h - 6)
    end

    -- 多标签页：demo 全屏时覆盖 0.5 透明黑遮罩
    if not self:isSingle() then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle('fill', play.layout.demo.x, ly.region.y, play.layout.demo.w, ly.region.h)
    end

    -- 多标签页：绘制每个标签页的 edit 区域（拖拽中的最后绘制，保持最上层）
    if not self:isSingle() then
        local order = {}
        for i = 1, #self.list do
            if not (self.drag and i == self.drag.index) then
                order[#order + 1] = i
            end
        end
        if self.drag then order[#order + 1] = self.drag.index end
        for _, i in ipairs(order) do
            -- 窗口内容与遮罩由 editView 实例绘制；顶部位置条由 Nuklear 处理。
            -- 左缘再同步一次：+ 按钮新建标签页发生在 update 同步循环之后，当帧即需绘制
            local v = self.list[i]
            v.editView.x = self:windowX(i)
            v.editView:draw()
        end
    end
    self('draw')
    -- edit 窗口绘制完成后，再绘制框选与复制/粘贴预览。
    if not self:isSingle() and ctrl then
        ctrl:draw(true)
    end
end

function tabs:mousepressed(x, y, button, istouch, presses)
    if demo.open or ChartService:isEditingEventGroup() then return end
    self('mousepressed', x, y, button, istouch, presses)
    if button ~= 1 then return end
    local ly = self.layout

    -- 重命名状态：点击输入框外提交（输入框由 nuklear 绘制并处理输入）
    if self:isRenaming() then
        local r = self._renameRect
        if r and not (x >= r.x and x <= r.x + r.w and y >= r.y and y <= r.y + r.h) then
            self:commitRename()
        else
            return
        end
    end

    -- 拖动条
    if y >= ly.scroll.y and y <= ly.scroll.y + ly.scroll.h then
        self:scrollClick(x)
        return
    end

    -- 标签条
    if y < ly.tabBar.y or y > ly.tabBar.y + ly.tabBar.h then
        -- 点击 edit 窗口使其标签页成为活动
        if not self:isSingle() and y >= ly.region.y and y <= ly.region.y + ly.region.h then
            for i = 1, #self.list do
                local wx = self:windowX(i)
                if x >= wx and x < wx + ly.tabW then
                    self.active = i
                    return
                end
            end
        end
        return
    end

    local contentX = ly.tabBar.x + ly.gutter - self.offset

    -- + 按钮由 nuklear 处理，跳过该区域
    if x >= contentX + #self.list * ly.tabW and x < contentX + #self.list * ly.tabW + ly.plusW then
        return
    end

    for i, tab in ipairs(self.list) do
        local tx = contentX + (i - 1) * ly.tabW
        if x >= tx and x < tx + ly.tabW then
            -- X 关闭按钮由 nuklear 处理，跳过该区域（避免误触发拖拽）
            if x >= tx + ly.tabW - ly.closeHitW and y < ly.tabBar.y + ly.titleH then
                return
            end

            --选中
            if math.intersect(y,y,ly.tabBar.y,ly.tabBar.y + ly.tabBar.h) then
                self.active = i
            end
            --拖拽排序
            if y < ly.tabBar.y + ly.titleH + ly.gutter then
                self.active = i
                self.drag = { index = i, grabX = x - tx }
            end
            -- 标题行：双击重命名
            if y < ly.tabBar.y + ly.titleH then
                local now = love.timer.getTime()
                if self._lastClick.index == i and now - self._lastClick.time < 0.4 then
                    self._lastClick = { index = 0, time = 0 }
                    self.drag = nil
                    self:startRename(i)
                    return
                end
                self._lastClick = { index = i, time = now }
                return
            end
            -- 合并开关行由 nuklear 按钮处理
            return
        end
    end
end

function tabs:wheelmoved(x, y)
    if demo.open or ChartService:isEditingEventGroup() then return end
    self('wheelmoved', x, y)
    if self.maxOffset <= 0 then return end
    local ly = self.layout
    if mouse.y < ly.tabBar.y or mouse.y > ly.scroll.y + ly.scroll.h then return end
    self.offset = clamp(self.offset - y * 40, 0, self.maxOffset)
end

function tabs:keypressed(key)
    if demo.open or ChartService:isEditingEventGroup() then return end
    self('keypressed', key)
    if not self:isRenaming() then return end
    if key == 'return' or key == 'kpenter' then
        self:commitRename()
    elseif key == 'escape' then
        self:cancelRename()
    end
end

return tabs
