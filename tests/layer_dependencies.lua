-- 依赖方向回归：加载工具不会向上加载服务，服务不加载 UI 实体路径。
package.path = './?.lua;./?/init.lua;' .. package.path
local event = require('src.utils.event')
local note = require('src.utils.note')
local track = require('src.utils.track')
assert(not package.loaded['src.services.chartService'])
assert(not package.loaded['src.services.coordinateService'])
assert(not package.loaded['src.objects.Note'] and not package.loaded['src.objects.Event'])

WINDOW = {w = 1600, h = 900}
require('src.utils.table')
require('src.utils.math')
require('src.objects.meta')
require('src.utils.beat')
save = function() return true end
local chart = require('src.services.chartService')
assert(chart == require('src.services.chartService.init'), 'chart service paths created separate instances')
local Note = require('src.models.Note')
local Event = require('src.models.Event')
assert(not package.loaded['src.objects.Note'] and not package.loaded['src.objects.Event'])
assert(Note == require('src.objects.Note') and Event == require('src.objects.Event'))

-- 工具可使用任意符合接口的实现；服务排序不反向调用工具单例。
local function forbidden() error('service called an editor tool') end
fNote, fEvent = {sort = forbidden}, {sort = forbidden}
chart:setChart({})
assert(chart:load())
chart:push()
chart:add(Event.new({type = 'x', track = 4, beat = {4, 0, 1}, beat2 = {5, 0, 1}}))
chart:add(Event.new({type = 'x', track = 2, beat = {2, 0, 1}, beat2 = {3, 0, 1}}))
chart:add(Note.new({track = 4, beat = {5, 0, 1}}))
chart:add(Note.new({track = 2, beat = {1, 0, 1}}))
chart:pop()
assert(chart:getEvent(1):getTrack() == 2 and chart:getNote(1):getTrack() == 2)
local coordinates = require('src.services.coordinateService')
event:init({chart = chart, event = Event, coordinates = coordinates})
note:init({chart = chart, note = Note, coordinates = coordinates})
track:init({chart = chart})
assert(track:track_get_max_track() == 4)
assert(table.concat(track:track_get_all_track(), ',') == '2,4')

-- 防止把向上引用改成延迟 require 后重新引入。
for _, name in ipairs({'event', 'note', 'track'}) do
    local file = assert(io.open('src/utils/' .. name .. '.lua', 'r'))
    local source = file:read('*a')
    file:close()
    assert(not source:match("require%s*%(%s*['\"]src[./]services[./]"), name)
    assert(not source:match("require%s*%(%s*['\"]src[./]objects[./]"), name)
end
print('PASS: dependency layers, injected interfaces, model aliases and service-owned sorting')
