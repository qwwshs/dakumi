-- 侧边栏轨道入口与滚轮回归；只用内存 UI，不读写用户数据。
require('src.utils.room')

local labels = {}
Nui = {
    button = function(_, label) labels[#labels + 1] = label; return false end,
    layoutRow = function() end,
    label = function() end,
    checkbox = function() end,
    widgetBounds = function() return 1400, 100, 150, 30 end,
    comboboxBegin = function() return false end,
}
ui = {edit = function() end}
track = {track = 1}
i18n = {get = function(_, key) return key end}
sidebar = {
    displayed_content = 'track',
    layout = {x = 1220, y = 0, w = 380, h = 900},
}
demo = {open = false}
mouse = {x = 1450, y = 400}
fTrack = {track_get_all_track = function() return {} end}
play = {get_all_track_pos = function() return {} end}

local home = require('src.objects.sidebar.nil')
for i, name in ipairs({'operation history', 'equalizer', 'takana'}) do
    home:addObject({Nui = function() labels[#labels + 1] = name end}, i * 10)
end
home:Nui()
assert(table.concat(labels, ',') ==
    'chart info,preference,track,settings,event_group.title,operation history,equalizer,takana',
    'track should be above settings and plugin entries')

local scrollY, setCalls = 0, 0
function Nui:windowGetScroll() return 0, scrollY end
function Nui:windowSetScroll(_, y) scrollY = y; setCalls = setCalls + 1 end

local trackPage = require('src.objects.sidebar.track')
trackPage:Nui()
trackPage:wheelmoved(0, -1)
trackPage:Nui()
assert(scrollY == trackPage.layout.uiH and setCalls == 1,
    'wheel down should advance the track list by one track')

-- Nuklear 已经自行滚动时，不叠加第二次滚动。
trackPage:wheelmoved(0, -1)
scrollY = 150
trackPage:Nui()
assert(scrollY == 150 and setCalls == 1, 'native scroll should not be doubled')

trackPage:wheelmoved(0, 1)
trackPage:Nui()
assert(scrollY == 150 - trackPage.layout.uiH, 'wheel up should move toward the beginning')

trackPage.comboPopup = {x = 1400, y = 300, w = 150, h = 100}
mouse.x, mouse.y = 1450, 350
trackPage:wheelmoved(0, -1)
assert(trackPage.pendingWheel == nil, 'wheel above filter dropdown should not scroll the list')
sidebar.displayed_content = 'nil'
mouse.x, mouse.y = 1450, 400
trackPage:wheelmoved(0, -1)
assert(trackPage.pendingWheel == nil, 'inactive track page should ignore wheel')

sidebar.displayed_content = 'track'
trackPage.comboPopup = nil
mouse.x, mouse.y = 1450, 110
trackPage:wheelmoved(0, -1)
assert(trackPage.pendingWheel == nil, 'wheel above filter header should not scroll the list')
print('PASS: sidebar order and track-list wheel scrolling')
