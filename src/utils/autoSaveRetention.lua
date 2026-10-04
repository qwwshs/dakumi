-- 自动备份保留策略：只识别本程序的备份文件，规划与磁盘删除分开。
local Retention = {}
local serial = 0
local function limit(value, fallback, low, high)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return fallback end
    return math.max(low, math.min(high, math.floor(value)))
end
function Retention.name(identity, now)
    -- 谱面路径散列避免同名谱面混淆，也避免歌曲名称成为文件路径。
    local digest = love.data.encode('string', 'hex', love.data.hash('sha256', identity))
    serial = serial + 1
    return 'dakumi-' .. digest .. '-' .. tostring(now) .. '-' .. tostring(serial) .. '.json'
end
local function key(name)
    if type(name) ~= 'string' or name:find('[/\\]') then return nil end
    local digest = name:match('^dakumi%-([a-f0-9]+)%-%d+%-%d+%.json$')
    if digest and #digest == 64 then return 'path:' .. digest end
    -- 兼容旧备份命名。旧格式只能按歌曲名与谱面名区分，保留独立的最后一份。
    local legacy = name:match('^%d%d%d%d %d%d %d%d %d%d %d%d %d%d(.+)%.json$')
    if legacy then return 'legacy:' .. legacy end
end
function Retention.plan(entries, now, options)
    options = options or {}
    local keep = limit(options.auto_save_keep, 50, 1, 10000)
    local age = limit(options.auto_save_days, 30, 1, 3650) * 86400
    local budget = limit(options.auto_save_max_mb, 256, 1, 1048576) * 1024 * 1024
    local files, total, seen = {}, 0, {}
    for _, item in ipairs(entries) do
        local owner = key(item.name)
        local stamp, size = tonumber(item.modtime), tonumber(item.size)
        if owner and item.type == 'file' and not seen[item.name] and stamp and size
            and stamp == stamp and size == size and stamp >= 0 and stamp < math.huge
            and size >= 0 and size < math.huge then
            seen[item.name] = true
            files[#files + 1] = {name = item.name, owner = owner, time = stamp, size = size}
            total = total + size
        end
    end
    table.sort(files, function(a, b)
        if a.time == b.time then
            local an = tonumber(a.name:match('%-(%d+)%.json$')) or 0
            local bn = tonumber(b.name:match('%-(%d+)%.json$')) or 0
            if a.owner == b.owner and an ~= bn then return an > bn end
            return a.name > b.name
        end
        return a.time > b.time
    end)
    local ranks, remove = {}, {}
    for _, file in ipairs(files) do
        local rank = (ranks[file.owner] or 0) + 1
        ranks[file.owner] = rank
        file.protected = rank == 1
        if not file.protected and (rank > keep or now - file.time > age) then
            file.remove = true
            total = total - file.size
        end
    end
    -- 超过总容量时优先清理最旧文件；每张谱面的最后一份仍保留。
    for index = #files, 1, -1 do
        local file = files[index]
        if total > budget and not file.protected and not file.remove then
            file.remove = true
            total = total - file.size
        end
        if file.remove then remove[#remove + 1] = file.name end
    end
    return remove, total
end
function Retention.prune(directory, fs, now, options)
    assert(type(directory) == 'string' and directory ~= '', '备份目录不能为空')
    local entries = fs.getDirectoryItemsInfo(directory, 'file')
    local remove = Retention.plan(entries, now, options)
    local failures = {}
    for _, name in ipairs(remove) do
        local ok, removed, err = pcall(fs.remove, directory:gsub('[/\\]+$', '') .. '/' .. name)
        if not ok or not removed then failures[#failures + 1] = name .. ': ' .. tostring(ok and err or removed) end
    end
    return #remove - #failures, failures
end
return Retention
