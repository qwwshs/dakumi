-- 只用虚拟目录验证保留策略，不接触用户的备份。
local Retention = require('src.utils.autoSaveRetention')
local now = 2000000000
local a, b = string.rep('a', 64), string.rep('b', 64)
local function file(owner, index, age, size)
    return {name = 'dakumi-' .. owner .. '-' .. (now - age) .. '-' .. index .. '.json',
        modtime = now - age, size = size or 1024, type = 'file'}
end
local entries = {file(a, 1, 0), file(a, 2, 1), file(a, 3, 2), file(b, 1, 4000000)}
local remove = Retention.plan(entries, now, {auto_save_keep = 2})
assert(#remove == 1 and remove[1] == entries[3].name)
remove = Retention.plan(entries, now, {auto_save_keep = 1})
assert(#remove == 2, '每张谱面保留最后一份')
entries = {file(a, 1, 0, 2*1024*1024), file(a, 2, 1, 2*1024*1024), file(b, 1, 4000000, 2*1024*1024)}
local bytes
remove, bytes = Retention.plan(entries, now, {auto_save_max_mb = 1})
assert(#remove == 1 and bytes == 4*1024*1024, '容量限制不能删除最后一份')
entries = {file(a, 1, 0), file(a, 2, 4000000)}
remove = Retention.plan(entries, now)
assert(#remove == 1 and remove[1] == entries[2].name, '过期备份应被清理')
entries[#entries+1] = {name = '../' .. entries[2].name, type = 'file', modtime = 0, size = 999999999}
entries[#entries+1] = {name = 'notes.json', type = 'file', modtime = 0, size = 999999999}
entries[#entries+1] = {name = entries[2].name, type = 'directory', modtime = 0, size = 999999999}
assert(#Retention.plan(entries, now) == 1, '不得删除目录、其他文件或路径穿越目标')
entries = {{name = '2025 01 01 00 00 00Song-Chart.json', type = 'file', modtime = now-4000000, size = 5},
    {name = '2025 01 02 00 00 00Song-Chart.json', type = 'file', modtime = now-3000000, size = 5}}
assert(#Retention.plan(entries, now) == 1, '旧格式也应保留最后一份')
-- 同一秒的第 10 次保存比第 9 次新，不能按字符串顺序误删最新一份。
local sameSecond = {file(a, 9, 0), file(a, 10, 0)}
local tied = Retention.plan(sameSecond, now, {auto_save_keep = 1})
assert(#tied == 1 and tied[1] == sameSecond[1].name)
local attempted = {}
local fs = {getDirectoryItemsInfo = function() return entries end,
    remove = function(path) attempted[#attempted+1] = path; return false, '拒绝写入' end}
local count, failures = Retention.prune('test/backups/', fs, now)
assert(count == 0 and #failures == 1 and #attempted == 1)
assert(attempted[1] == 'test/backups/' .. entries[1].name)
assert(#Retention.plan({}, now, {auto_save_keep = 0/0, auto_save_days = math.huge}) == 0)
print('PASS: 自动保存数量、期限、容量、最后一份保护、旧格式、安全路径、删除失败')
