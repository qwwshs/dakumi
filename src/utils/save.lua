local AutoSaveRetention = require('src.utils.autoSaveRetention')

local function reportChartSaveFailure(content, reason)
    log('chart save error: ' .. tostring(reason))

    -- 自动保存不打断编辑；手动保存失败时，给玩家保留谱面内容的机会。
    if type(content) ~= 'string' or not love or not love.window or not love.window.showMessageBox then
        return
    end

    local title = i18n:get('chart_save_failed_title')
    local prompt = string.format(i18n:get('chart_save_failed_prompt'), tostring(reason))
    local choice = love.window.showMessageBox(title, prompt, {
        i18n:get('chart_save_copy'),
        i18n:get('chart_save_cancel'),
        enterbutton = 1,
        escapebutton = 2,
    }, 'warning', true)

    if choice ~= 1 then return end

    local ok, err = pcall(love.system.setClipboardText, content)
    if not ok then
        log('chart clipboard copy error: ' .. tostring(err))
        love.window.showMessageBox(title, i18n:get('chart_save_copy_failed'), 'error', true)
    end
end

local function encodeChart(tab)
    local ok, content, err = pcall(dkjson.encode, tab, { indent = true })
    if not ok then return nil, content end
    if type(content) ~= 'string' then return nil, err or 'JSON encoding returned no content' end
    return content
end

local function writeNative(path, content)
    local mountedOk, mounted = pcall(nativefs.mount, PATH.base)
    if not mountedOk then return false, mounted end

    local writeCallOk, wrote, writeErr = pcall(nativefs.write, path, content)
    if mounted then
        local unmountOk, unmounted, unmountErr = pcall(nativefs.unmount, PATH.base)
        if not unmountOk or not unmounted then
            local err = unmountOk and unmountErr or unmounted
            log('chart save unmount warning: ' .. tostring(err))
        end
    end

    if not writeCallOk then return false, wrote end
    if not wrote then return false, writeErr or 'Could not write file' end
    return true
end

function save(tab, name) -- 谱面与设置保存
    if name == 'chart.json' then -- 手动保存当前谱面
        local selected = menu and menu.chartInfo and menu.chartInfo.chart_name
            and menu.chartInfo.chart_name[menu.selectChartPos]
        local content, encodeErr = encodeChart(tab)
        if not content then
            reportChartSaveFailure(nil, encodeErr)
            return false, encodeErr
        end
        if not selected or not selected.path then
            reportChartSaveFailure(content, 'chart path is unavailable')
            return false, 'chart path is unavailable'
        end

        local ok, err = writeNative(selected.path, content)
        if not ok then
            reportChartSaveFailure(content, err)
            return false, err
        end

        log('chart saved:', selected.path)
        return true
    elseif name == 'chart.json.auto' then -- 自动保存
        local ok, content, encodeErr = pcall(function()
            local encoded, err = encodeChart(tab)
            if not encoded then error(err) end
            local selected = menu and menu.chartInfo and menu.chartInfo.chart_name
                and menu.chartInfo.chart_name[menu.selectChartPos]
            local info = tab and tab.info or {}
            local identity = selected and selected.path or
                (tostring(info.song_name or '') .. '/' .. tostring(info.chart_name or ''))
            local now = os.time()
            local directory = PATH.usersPath.auto_save:gsub('[/\\]+$', '') .. '/'
            local filename = AutoSaveRetention.name(identity, now)
            -- 同秒重启也不能覆盖已有备份。
            while nativefs.getInfo(directory .. filename) do filename = AutoSaveRetention.name(identity, now) end
            local wrote, err = writeNative(directory .. filename, encoded)
            if not wrote then return false, err end
            local cleaned, cleanupError = pcall(function()
                local _, failures = AutoSaveRetention.prune(directory, nativefs, now, settings)
                for _, failure in ipairs(failures) do log('auto save cleanup warning: ' .. failure) end
            end)
            if not cleaned then log('auto save cleanup warning: ' .. tostring(cleanupError)) end
            return true
        end)
        if not ok then
            log(name .. ' save error: ' .. tostring(content))
            return false, content
        end
        if not content then
            log(name .. ' save error: ' .. tostring(encodeErr))
            return false, encodeErr
        end
        return true
    end

    local content
    if type(tab) == 'table' then
        local ok, serialized = pcall(tableToString, tab)
        if not ok then return false, serialized end
        content = serialized
    elseif type(tab) == 'string' then
        content = tab
    else
        return false, 'unsupported save data type: ' .. type(tab)
    end

    local file, openErr = io.open(name, 'w')
    if not file then return false, openErr or 'Could not open file for writing' end

    local writeOk, writeErr = pcall(file.write, file, content)
    local closeOk, closeResult, closeErr = pcall(file.close, file)
    if not writeOk then return false, writeErr end
    if closeOk and closeResult == nil then return false, closeErr or 'Could not close file' end
    if not closeOk then return false, closeResult end
    return true
end
