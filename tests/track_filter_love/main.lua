-- 用固定轨道数据验证三种筛选模式，不读取或改写用户谱面。
local root = love.filesystem.getSource():gsub('[/\\]tests[/\\]track_filter_love[/\\]?$', '')
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
group = {new = function(_, name) return {name = name} end}

local fields = {
    [1] = {name = 'Alpha', type = 'xw', parent = 0, zindex = 2,
        w0thenShow = 1, boundary_type = 'track'},
    [2] = {name = 'Beta', type = 'xw', parent = 1, zindex = 5,
        w0thenShow = 0, boundary_type = 'pos'},
}
package.loaded['src.services.chartService'] = {
    getTrackField = function(_, trackId, key) return fields[trackId][key] end,
}

local filter = require('src.objects.sidebar.track')
local function run()
    local a, b = {x = 10, w = 20}, {x = 30, w = 40}
    assert(filter:matches(1, a, 'Alpha') and filter:matches(2, b, 'Beta'))

    filter.turnOnFilter.value = true
    filter.range.x.from.value, filter.range.x.to.value = '25', ''
    assert(not filter:matches(1, a, 'Alpha') and filter:matches(2, b, 'Beta'))
    filter.range.x.from.value, filter.range.x.to.value = '40', '20'
    assert(filter:matches(2, b, 'Beta'), 'reversed position range')
    filter.range.x.from.value = 'invalid'
    assert(not filter:matches(2, b, 'Beta'), 'invalid range was accepted')

    filter.filterMode.value, filter.nameQuery.value = 2, 'ALP'
    assert(filter:matches(1, a, 'Alpha') and not filter:matches(2, b, 'Beta'))
    filter.nameQuery.value = 'a'
    assert(filter:matches(1, a, 'Alpha') and filter:matches(2, b, 'Beta'))

    filter.filterMode.value, filter.settingIndex.value = 3, 3 -- 父轨道
    filter.settingQuery.value = '1'
    assert(not filter:matches(1, a, 'Alpha') and filter:matches(2, b, 'Beta'))
    filter.settingIndex.value, filter.settingQuery.value = 5, '5' -- 层级
    assert(filter:matches(2, b, 'Beta'))
    filter.settingIndex.value = 2 -- 零宽时显示
    filter.switchValue.value = 2
    assert(filter:matches(1, a, 'Alpha') and not filter:matches(2, b, 'Beta'))
    filter.settingIndex.value, filter.settingQuery.value = 6, 'TRAC' -- 边界类型
    assert(filter:matches(1, a, 'Alpha') and not filter:matches(2, b, 'Beta'))
    print('PASS: position, name, numeric, switch and text setting filters')
end

function love.load()
    local ok, err = xpcall(run, debug.traceback)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
end
