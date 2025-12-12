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
    setmetatable(chart,meta_chart)
    chart:load() --初始化

    room_pos = 'edit' --进入编辑
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
    love.system.openURL("https://dakumi.com")
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = '',img = isImage.github}

menuUI.fileTool[#menuUI.fileTool].func = function()
    messageBox:add("github")
    love.system.openURL("https://github.com/qwwshs/daikumi_editor/")
end

menuUI.fileTool[#menuUI.fileTool + 1] = {type = 'button',text = 'file select'}

menuUI.fileTool[#menuUI.fileTool].func = function()
    if true then return end --暂时禁用 有问题
    local fileselect = ffi.load("fileselect")
    -- 定义函数原型
    ffi.cdef[[
        const char* OpenFileDialog(const char* filter);
        const char* SaveFileDialog(const char* filter);
    ]]
    -- ANSI 到 UTF-8 的转换函数
    local function ansi_to_utf8(ansi_str)
        -- 常量定义
        local CP_ACP = 0        -- ANSI代码页
        local CP_UTF8 = 65001   -- UTF-8代码页
    
        -- 首先将 ANSI 转换为 UTF-16
        local wlen = ffi.C.MultiByteToWideChar(CP_ACP, 0, ansi_str, -1, nil, 0)
        if wlen <= 0 then return ansi_str end
    
        local wstr = ffi.new("wchar_t[?]", wlen)
        ffi.C.MultiByteToWideChar(CP_ACP, 0, ansi_str, -1, wstr, wlen)
    
        -- 然后将 UTF-16 转换为 UTF-8
        local utf8len = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wstr, -1, nil, 0, nil, nil)
        if utf8len <= 0 then return ansi_str end
    
        local utf8str = ffi.new("char[?]", utf8len)
        ffi.C.WideCharToMultiByte(CP_UTF8, 0, wstr, -1, utf8str, utf8len, nil, nil)
    
        return ffi.string(utf8str)
    end

    -- 定义文件过滤器
    local filter = 
    "Audio Files (*.ogg;*.mp3;*.wav)\0*.ogg;*.mp3;*.wav\0Chart Files (*.json;*.mc)\0*.json;*.mc\0Image Files (*.jpg;*.png)\0*.jpg;*.png\0Package Files (*.dkz)\0*.dkz\0All Files (*.*)\0*.*\0";
    local selectedFile = fileselect.OpenFileDialog(filter)
    if selectedFile ~= nil then
        local filepath = ffi.string(selectedFile)
        local lastSlashIndex = string.find(filepath, "\\[^\\]*$") --找到最后一个斜杠的位置
        local file_name = string.sub(filepath, lastSlashIndex + 1) --从最后一个斜杠之后开始截取字符串
        local file = love.filesystem.newFile("temporary/"..file_name)
        file:open("w")
        local data = nativefs.read(filepath)
        file:write(data)
        file:close()
        menu:filedropped(file) --导入文件
    end
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