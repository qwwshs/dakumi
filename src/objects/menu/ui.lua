local menuUI = {}

menuUI.chartTool = {}

menuUI.chartTool = {}

menuUI.chartTool[#menuUI.chartTool + 1] = {type = 'button',text = 'edit'}

menuUI.chartTool[#menuUI.chartTool].func = function()
    love.audio.stop( ) --停止歌曲
    if not menu.chartInfo.chart_name[menu.selectChartPos] then
        love.window.showMessageBox('Not music',i18n:get('Not music'))
        return
    end
    if not menu.chartInfo.chart_name[menu.selectChartPos].is_true_chart then 
        love.window.showMessageBox('Error chart',i18n:get('Error chart'))
        return
    end
    if not menu.chartInfo.chart_name[menu.selectChartPos] then
        love.window.showMessageBox('Create a chart first',i18n:get('Create a chart first'))
        return
    end
    log("load chart:",menu.chartInfo.chart_name[menu.selectChartPos].path)
    setmetatable(chart,meta_chart)

    menu('toedit')

    chart:load() --初始化
    time.nowtime = 0
    beat.nowbeat = 0
    room:to('edit')
    love.window.setTitle(chart.info.song_name.."-"..chart.info.chart_name)
end

menuUI.chartTool[#menuUI.chartTool + 1] = {type = 'button',text = 'new chart'}

menuUI.chartTool[#menuUI.chartTool].func = function()
    messageBox:add("new_chart")

    nativefs.mount(PATH.base)

    local name = PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/new_chart"
    while nativefs.getInfo( name..".json" )  do
        name = name .."_new"
    end

    local file = nativefs.newFile(name..".json")
    file:open("w") --为了创建谱面
    local isChart = {}
    table.fill(isChart,meta_chart.__index)
    file:write(dkjson.encode(isChart, {indent = true})) --初始化
    file:close()

    nativefs.unmount()
    menu.chartInfo.chart_name =  {}
    menu:select_music()

end

menuUI.chartTool[#menuUI.chartTool + 1] = {type = 'button',text = 'delete chart'}

menuUI.chartTool[#menuUI.chartTool].func = function()
        --找到谱面文件夹然后删除
        if love.window.showMessageBox( "", i18n:get("delete chart?"),{'no','yes'} ) == 2 then
            pcall(function() 
                nativefs.mount(PATH.base)
                nativefs.remove( menu.chartInfo.chart_name[menu.selectChartPos].path ) 
                menu.selectChartPos = 1 
                nativefs.unmount()
            end)
            menu:flushed()
        end
end

menuUI.fileTool = {}

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = '',img = isImage.dakumi}

menuUI.fileTool[#menuUI.fileTool].func = function()
    messageBox:add("dakumi")
    love.system.openURL(PATH.web.dakumi)
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = '',img = isImage.github}

menuUI.fileTool[#menuUI.fileTool].func = function()
    messageBox:add("github")
    love.system.openURL(PATH.web.github)
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = 'export'}

menuUI.fileTool[#menuUI.fileTool].func = function()
    if not menu.chartTab[menu.selectMusicPos] then
        return
    end
    nativefs.mount(PATH.base)
    nativefs.createDirectory(PATH.usersPath.export) --防止有人运行一半删文件夹

    local file_tab = nativefs.getDirectoryItems(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos]) --导出
    for i,v in ipairs(file_tab) do
        local info = nativefs.read(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..v)
        local file = io.open(PATH.usersPath.export.."/"..v, "wb")
        file:write(info)
        file:close()
    end
    local err = os.execute("cd "..PATH.usersPath.export.." && 7z a "..menu.chartTab[menu.selectMusicPos]..".zip"..[[ *]])  --导出 调用7zip
    messageBox:add("export")
    if err ~= 0 then
        log("export error:"..err,menu.chartTab[menu.selectMusicPos]..".zip", [[ *]])
    end
    
    for i,v in ipairs(file_tab) do
        nativefs.remove(PATH.usersPath.export.."/"..v)  --删除
    end
    nativefs.unmount()
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = 'delete music'}

menuUI.fileTool[#menuUI.fileTool].func = function()
    --找到谱面文件夹然后删除
    if love.window.showMessageBox( "", i18n:get("delete music?"),{'no','yes'} ) == 2 then
        pcall(function() 
            nativefs.mount(PATH.base)
            local file_tab = nativefs.getDirectoryItems(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos]) --得到谱面文件夹下的所有文件
            for i,v in ipairs(file_tab) do
    
                local s = nativefs.remove( PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..v ) --删除谱面文件夹下的所有文件 
            end
            nativefs.remove( PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos] ) --删除谱面文件夹
            nativefs.unmount()
        end)
        menu:flushed()
    end
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = 'flushed'}

menuUI.fileTool[#menuUI.fileTool].func = function()
    menu:flushed()
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = 'open directory'}

menuUI.fileTool[#menuUI.fileTool].func = function()
    love.system.openURL(love.filesystem.getSaveDirectory( ))
end

return menuUI