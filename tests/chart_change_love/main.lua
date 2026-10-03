-- 使用真实的 ChartService、记录器和撤销插件验证统一谱面变更通知。
local root = love.filesystem.getSource():gsub('[/\\]tests[/\\]chart_change_love[/\\]?$', '')
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path

require('src.utils.room')
require('src.utils.table')
beat = {get = function(_, v) return v[1] + v[2] / v[3] end,
    toBeat = function(_, _, seconds) return seconds or 0 end}
time = {alltime = 10}
event_type = {'x', 'w', 'lpos', 'rpos', 'event_group'}
event_property_type = {'x', 'w', 'lpos', 'rpos'}
easings = {1}
meta_chart = {__index = {note = {}, event = {}, bpm_list = {}, track = {}, effect = {},
    info = {}, preference = {}, event_groups = {}, offset = 0}}
meta_track = {__index = {}}
meta_extra_chart_track = {x = {}, w = {}, lpos = {}, rpos = {}, event_group = {}, note = {}}
fNote = {sort = function() end}
fEvent = {sort = function() end}
sidebar = {displayed_content = 'operation history', to = function() end}
save = function() error('测试不得写入谱面文件') end

local bus = require('src.utils.eventBus')
local Chart = require('src.services.chartService')
local Note = require('src.objects.Note')
local Event = require('src.objects.Event')
local redo = require('plugins.redo')
local changes = {}
local mutations = {}
local unsubscribe = bus:on('chart:changed', function(change)
    changes[#changes + 1] = {kind = change.kind, actionKey = change.actionKey,
        operation = change.operation, notes = Chart:getNoteCount(),
        events = Chart:getEventCount(), offset = Chart:getOffset()}
end)
local unsubscribeMutations = bus:on('chart:mutated', function(change)
    mutations[#mutations + 1] = change
end)
local function last(kind)
    assert(changes[#changes].kind == kind, 'expected ' .. kind .. ', got ' ..
        tostring(changes[#changes].kind))
end
local function count() return #changes end
local function run()
    Chart:setChart({})
    last('replace')
    assert(redo:getHistory() ~= nil)

    local n = Note.new({type = 'note', beat = {1, 0, 1}})
    Chart:addNote(n, 'history.add_note')
    last('commit')
    assert(mutations[#mutations].kind == 'note_added')
    assert(changes[#changes].operation.add.note[1] == n)
    assert(changes[#changes].notes == 1 and changes[#changes].actionKey == 'history.add_note')
    local before = count()
    n:setFake(0)
    assert(count() == before, 'unchanged setter notified')
    n:setFake(1)
    last('commit')
    assert(mutations[#mutations].kind == 'note_updated' and
        mutations[#mutations].method == 'setFake')
    assert(count() == before + 1 and #changes[#changes].operation.del.note == 1)

    before = count()
    Chart:push()
    Chart:addEvent(Event.new({type = 'x', beat2 = {2, 0, 1}}))
    Chart:addNote(Note.new({type = 'note', beat = {3, 0, 1}}))
    assert(count() == before, 'batch notified before commit')
    assert(mutations[#mutations].kind == 'note_added', 'batch mutation was not immediate')
    Chart:pop('history.paste')
    assert(count() == before + 1 and changes[#changes].events == 1 and changes[#changes].notes == 2)

    Chart:setOffset(240)
    assert(changes[#changes].operation.fields_after[1].kind == 'offset')
    assert(mutations[#mutations].kind == 'field_updated' and mutations[#mutations].field == 'offset')
    Chart:setBpmList({{bpm = 120, beat = {0, 0, 1}}})
    local bpmCopy = Chart:getBpm(1)
    bpmCopy.bpm = 300
    assert(Chart:getBpm(1).bpm == 120, 'BPM getter exposed writable chart data')
    before = count()
    Chart:setOffset(240)
    assert(count() == before, 'unchanged field notified')
    local mutationCount = #mutations
    assert(redo:undo())
    last('undo')
    assert(Chart:getBpmCount() == 0)
    assert(#mutations == mutationCount, 'undo emitted per-item mutations')
    assert(redo:redoOne())
    last('redo')
    assert(changes[#changes].offset == 240)
    assert(Chart:getBpm(1).bpm == 120)

    before = count()
    Chart:getTrackField(3, 'name')
    last('track_created')
    assert(count() == before + 1 and mutations[#mutations].kind == 'track_created')
    Chart:getTrackField(3, 'name')
    assert(count() == before + 1, 'existing track was announced again')

    local inner = {type = 'x', beat = {0, 0, 1}, beat2 = {1, 0, 1},
        from = 0, to = 1, trans = {type = 'easings', easings = 1}}
    before = count()
    assert(Chart:putEventGroup('A', {event = {inner}}))
    assert(count() == before + 1 and changes[#changes].operation.groups_after.A)
    before = count()
    assert(Chart:putEventGroup('A', {event = {inner}}))
    assert(count() == before, 'unchanged group notified')
    local ref = Event.new({type = 'event_group', event_group = 'A', beat2 = {2, 0, 1}})
    Chart:addEvent(ref)
    before = count()
    assert(Chart:putEventGroup('B', {event = {inner}}, 'A'))
    assert(count() == before + 1, 'rename produced duplicate notifications')
    assert(ref:getEventGroup() == 'B' and #changes[#changes].operation.add.event == 1)

    assert(Chart:beginEventGroupEdit('B'))
    last('group_edit_begin')
    Chart:getEvent(1):setTo(2)
    last('commit')
    assert(Chart:syncEventGroupEdit())
    last('group_sync')
    assert(Chart:finishEventGroupEdit())
    last('group_edit_end')
    assert(Chart:getEventGroup('B').event[1].to == 2)
    assert(Chart:deleteEventGroup('B'))
    last('commit')

    before = count()
    Chart:setChart({note = {{type = 'note', beat = {0, 0, 1}}}})
    last('replace')
    assert(count() == before + 1)
    -- load 在实际应用中会保存，测试只验证通知链；使用内存替身拦截写盘。
    save = function() end
    assert(Chart:load())
    last('load')
    assert(type(Chart:getNote(1).getType) == 'function')
    unsubscribe()
    unsubscribeMutations()
    print('PASS: chart changes, batch, fields, undo/redo, event groups, replacement and load')
end

function love.load()
    local ok, err = xpcall(run, debug.traceback)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
end
