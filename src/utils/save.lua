function save(tab, name)         --谱与设置保存
    if name == "chart.json" then --特殊保存
        if not menu.chartInfo.chart_name[menu.selectChartPos].path then log(name..' save error: not path') return end

        local s,result =  pcall(function()
            nativefs.mount(PATH.base)
            nativefs.write(menu.chartInfo.chart_name[menu.selectChartPos].path, dkjson.encode(tab, { indent = true }))
            nativefs.unmount()
        end)
        if not s then
            log(name..' save error:' .. tostring(result))
        end
        if s then
            log("chart saved:",menu.chartInfo.chart_name[menu.selectChartPos].path)
        end
        return
    elseif name == "chart.json.auto" then --自动保存
        if not menu.chartInfo.chart_name[menu.selectChartPos].path then log(name..'auto save warn: not path') end
        local s,result = pcall(function()
            nativefs.mount(PATH.base)
            nativefs.write(
            PATH.usersPath.auto_save .. os.date("%Y %m %d %H %M %S") .. chart.info.song_name ..
            "-" .. chart.info.chart_name .. '.json', dkjson.encode(tab, { indent = true }))
            nativefs.unmount()
        end)
        if not s then
            log(name..' save error:' .. tostring(result))
        end
        return
    end
    local file = io.open(name, "w")
    if file then
        if type(tab) == "table" then
            file:write(tableToString(tab))
        elseif type(tab) == "string" then
            file:write(tab)
        end
        file:close()
    end
end
