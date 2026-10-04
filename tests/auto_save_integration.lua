-- 检查自动保存与清理的调用顺序，所有文件操作均为内存替身。
local digest = string.rep('a', 64)
local now = os.time()
love = {data = {hash = function() return 'digest' end, encode = function() return digest end}}
PATH = {base = 'test', usersPath = {auto_save = 'test/backups/'}}
menu = {chartInfo = {chart_name = {{path = 'test/chart.json'}}}, selectChartPos = 1}
settings = {}
local warnings, writes, removals, lists = {}, {}, {}, 0
log = function(message) warnings[#warnings+1] = message end
dkjson = {encode = function() return '{"chart":true}' end}
local failWrite, failDelete, failEncode = false, false, false
local old = {name = 'dakumi-' .. digest .. '-1-1.json', type = 'file', modtime = now-4000000, size = 10}
local current
nativefs = {
    mount = function() return false end,
    getInfo = function() return nil end,
    write = function(path, content)
        writes[#writes+1] = path
        assert(not path:find('evil'), '标题不应参与文件路径')
        assert(content == '{"chart":true}')
        if failWrite then return false, 'disk full' end
        current = {name = path:match('[^/]+$'), type = 'file', modtime = now, size = #content}
        return true
    end,
    getDirectoryItemsInfo = function()
        lists = lists+1
        return {old, current}
    end,
    remove = function(path)
        removals[#removals+1] = path
        if failDelete then error('readonly') end
        return true
    end,
}
require('src.utils.save')
local chart = {info = {song_name = '../../evil', chart_name = 'evil'}}
failWrite = true
local ok, err = save(chart, 'chart.json.auto')
assert(not ok and err == 'disk full' and lists == 0 and #removals == 0, '写入失败不得清理旧备份')
failWrite = false
assert(save(chart, 'chart.json.auto'))
assert(lists == 1 and #removals == 1 and removals[1] == 'test/backups/' .. old.name)
failDelete = true
assert(save(chart, 'chart.json.auto'), '清理失败不能否认新备份写入成功')
assert(#warnings >= 2)
local beforeWrites, beforeLists = #writes, lists
dkjson.encode = function() error('encode failed') end
assert(not save(chart, 'chart.json.auto'))
assert(#writes == beforeWrites and lists == beforeLists)
print('PASS: 自动备份成功后清理、写入与编码失败保护、清理失败报告、标题路径隔离')
