
local ui_dakumi = isImage.dakumi
local layout = require 'config.layouts.menu' --菜单布局

menu  = room:new('menu')
room:addRoom(menu)

--选择的歌曲的房间
menu.chartTab = {} --所有谱面的文件夹
menu.selectMusicPos = 1 --选择到的谱面
menu.selectChartPos = 1 --选择到的歌曲
menu.chartInfo = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
menu.path = ''

local menuUI = require 'src.objects.menu.ui'

function menu:select_music()
    if menu.chartTab[menu.selectMusicPos] then
        menu.chartInfo = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
        --输出选择到的谱面的谱面信息
        nativefs.mount(PATH.base)

        local file_tab = love.filesystem.getDirectoryItems(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos]) --得到谱面文件夹下的谱面
        for i,v in ipairs(file_tab) do
            if string.find(v,".json") then --谱面文件
                local info = love.filesystem.read(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..v)
                pcall(function() info =  dkjson.decode(info) end)
                local is_true_chart = true
                if type(info) ~= "table" then
                    log("It is "..type(info))
                    is_true_chart = false
                    info = {}
                end
                setmetatable(info,meta_chart) --防谱报废
                table.fill(info,meta_chart.__index)


                table.fill(chart,meta_chart.__index)
                menu.chartInfo.song_name = info.info.song_name
                menu.chartInfo.chart_name[#menu.chartInfo.chart_name + 1] = {name = info.info.chart_name,
                path = PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..v,is_true_chart = is_true_chart}
                if menu.selectChartPos == #menu.chartInfo.chart_name then
                    chart = table.copy(info) --读取谱面
                    setmetatable(chart,meta_chart) --防谱报废
                end
            end
            if string.find(v,".jpg") or string.find(v,".png") or string.find(v,".jpeg") then --bg
                menu.chartInfo.bg = love.graphics.newImage(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..v)

                bg = menu.chartInfo.bg
            end
            
        end
        for i,v in ipairs(file_tab) do --因为一些数据在chart里面 所以分开读
            if string.find(v,".mp3") or string.find(v,".ogg") or string.find(v,".wav") then --歌曲
                love.audio.stop( ) --停止上一个歌曲
                menu.chartInfo.song = love.audio.newSource(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..v, "stream")
                love.audio.setVolume( settings.music_volume / 100 ) --设置音量大小
                menu.chartInfo.song:play()

                --读取音频信息
                music = menu.chartInfo.song
                time.alltime = music:getDuration() + chart.offset / 1000 -- 得到音频总时长
                beat.allbeat = beat:toBeat(chart.bpm_list,time.alltime)
            end
        end
        love.audio.stop( ) --停止上一个歌曲

        nativefs.unmount()
    end
end

function menu:flushed() --刷新
    
    menu.chartTab = {} --所有谱面的文件夹
    menu.chartInfo = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
    love.audio.stop( ) --停止上一个歌曲

    local dir = love.filesystem.getIdentity() --文件的写入目录

    love.filesystem.createDirectory("chart")

    nativefs.mount(PATH.base)
    menu.chartTab = nativefs.getDirectoryItems(PATH.usersPath.chart) --得到谱面文件夹下的所有谱面
    nativefs.unmount()

    love.filesystem.createDirectory("temporary")
    local temporary_tab = love.filesystem.getDirectoryItems("temporary") --得到文件夹下的所有文件
    for i ,v in ipairs(temporary_tab) do
        love.filesystem.remove("temporary".."/"..v) --删除临时文件
    end

    love.filesystem.createDirectory("auto_save") --创建自动保存文件夹

    love.filesystem.createDirectory("ui")

    menu:select_music()

end

function menu:load()
    menu:flushed()
end

function menu:draw()

    love.graphics.setColor(1,1,1,0.2)

    --装饰网格
    for i= 0,74 do
        love.graphics.rectangle('fill',i*25,0,1,WINDOW.h)
    end
    for i= 0,32 do
        love.graphics.rectangle('fill',0,i*25,WINDOW.w,1)
    end

    love.graphics.setColor(1,1,1,1)

    if menu.chartInfo.bg then

        local bg_width, bg_height = menu.chartInfo.bg:getDimensions( ) -- 得到宽高
        local bg_scale_h
        local bg_scale_w
        bg_scale_h = 1 / bg_height * layout.bg.size 
        bg_scale_w = 1 / bg_height * layout.bg.size / (WINDOW.scale / WINDOW.scale)
        love.graphics.draw(menu.chartInfo.bg,layout.bg.x - layout.bg.size / 2 /bg_height *bg_width ,layout.bg.y - layout.bg.size / 2,0,bg_scale_w,bg_scale_h)
        love.graphics.rectangle('fill',layout.bg.x - layout.bg.size / 2 /bg_height *bg_width - layout.bg.pointSize,layout.bg.y - layout.bg.size / 2 - layout.bg.pointSize,layout.bg.pointSize,layout.bg.pointSize)

        love.graphics.rectangle('fill',layout.bg.x + layout.bg.size / 2 /bg_height *bg_width + layout.bg.pointSize,layout.bg.y + layout.bg.size / 2 + layout.bg.pointSize,-layout.bg.pointSize,-layout.bg.pointSize)

    end
    love.graphics.setFont(FONT.plus)

    --歌曲信息

    --背景板
    love.graphics.setColor(0.2,0.2,0.2,0.7)
    love.graphics.rectangle("fill",layout.musicSelect.x,layout.musicSelect.y,layout.musicSelect.w,layout.musicSelect.h)

    --装饰线
    love.graphics.setColor(1,1,1,0.5)
    love.graphics.rectangle("fill",layout.musicSelect.x,layout.musicSelect.y,1,layout.musicSelect.h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("fill",layout.musicSelect.x-5,layout.musicSelect.y,3,layout.musicSelect.h)

    
    local middle = 400
    local fontHeight = love.graphics.getFont():getHeight()

    love.graphics.setColor(1,1,1,0.2)
    love.graphics.rectangle("fill",layout.musicSelect.x,middle - layout.musicSelect.musicH / 2,layout.musicSelect.w,layout.musicSelect.musicH)

    
    for i,v in ipairs(menu.chartTab) do
        if i == menu.selectMusicPos then
            love.graphics.setColor(1,1,1,1)
        else
            love.graphics.setColor(1,1,1,0.5)
        end
        love.graphics.printf( v, layout.musicSelect.x,(i - menu.selectMusicPos)*layout.musicSelect.musicH + middle - fontHeight / 2,layout.musicSelect.w, "center")
    end
    

    love.graphics.setFont(FONT.normal)
    local fontHeight = love.graphics.getFont():getHeight()
    love.graphics.setColor(1,1,1,1)

    --谱面信息
    love.graphics.setColor(1,1,1,0.2)
    love.graphics.rectangle("fill",layout.chartSelect.x,layout.chartSelect.y - layout.chartSelect.chartH/2,layout.chartSelect.w,layout.chartSelect.h)

    for i = 1,#menu.chartInfo.chart_name do
        if i == menu.selectChartPos then
            love.graphics.setColor(1,1,1,1)
        else
            love.graphics.setColor(1,1,1,0.5)
        end
        if not menu.chartInfo.chart_name[i].is_true_chart then love.graphics.setColor(1,0.5,0.5,1) end
        love.graphics.printf('chart:'..menu.chartInfo.chart_name[i].name, layout.chartSelect.x,(menu.selectChartPos -i)*layout.chartSelect.chartH+ layout.chartSelect.y  - fontHeight / 2,layout.chartSelect.w, "center")
    end


    love.graphics.setFont(FONT.normal)
end

function menu:wheelmoved(x,y)
    if mouse.x > layout.musicSelect.x and mouse.x < layout.musicSelect.x + layout.musicSelect.w then

        if y < 0 then
            menu.selectMusicPos = menu.selectMusicPos + 1
        else
            menu.selectMusicPos = menu.selectMusicPos - 1
        end

        menu.selectMusicPos = math.max(1,math.min(#menu.chartTab,menu.selectMusicPos))

        menu.selectChartPos = 1 --归位
        menu:select_music()
    elseif mouse.x > layout.chartSelect.x and mouse.x < layout.chartSelect.x + layout.chartSelect.w then

        if y < 0 then
            menu.selectChartPos = menu.selectChartPos + 1
        else
            menu.selectChartPos = menu.selectChartPos - 1
        end

        menu.selectChartPos = math.max(1,math.min(#menu.chartInfo.chart_name,menu.selectChartPos))

        menu.path = menu.chartInfo.chart_name[menu.selectChartPos].path
        local info = love.filesystem.read(menu.path)
        
        pcall(function() info = loadstring("return "..info)() end)
        if type(info) ~= "table" then
            log("It is "..type(info))
            info = {}
        end
        setmetatable(info,meta_chart) --防谱报废
        table.fill(info,meta_chart.__index)

        chart = table.copy(info) --读取谱面
    end 

end
function menu:mousereleased( x, y, button, istouch, presses )

end

function  menu:update(dt)
    if Nui:windowBegin('chartTool', layout.chartTool.x, layout.chartTool.y, layout.chartTool.w, layout.chartTool.h,'border') then
        Nui:layoutRow('dynamic', layout.chartTool.h, layout.chartTool.cols)
        for i,obj in ipairs(menuUI.chartTool) do
            if obj.type == 'button' then
                if Nui:button(i18n:get(obj.text),obj.img) then
                    obj.func()
                end
            end
        end

        Nui:windowEnd()
    end
    if Nui:windowBegin('fileTool', layout.fileTool.x, layout.fileTool.y, layout.fileTool.w, layout.fileTool.h,'border') then
        Nui:layoutRow('dynamic', layout.fileTool.h, layout.fileTool.cols)
        for i,obj in ipairs(menuUI.fileTool) do
            if obj.type == 'button' then
                if Nui:button(i18n:get(obj.text),obj.img) then
                    obj.func()
                end
            end
        end

        Nui:windowEnd()
    end

end

function menu:filedropped(file) -- 文件拖入
    file:open("r")
    local flie_name = file:getFilename()   
    local lastSlashIndex = string.find(flie_name, "/[^/]*$") --找到最后一个斜杠的位置
    if not lastSlashIndex then
        lastSlashIndex = string.find(flie_name, "\\[^\\]*$") --找到最后一个斜杠的位置
    end
    if not lastSlashIndex then
        lastSlashIndex = 0 --找到最后一个斜杠的位置
    end
    local content = file:read()
    local flie_name = string.sub(flie_name, lastSlashIndex + 1)
    if string.find(flie_name,"hit") then
        love.filesystem.newFile(flie_name,"w")
        love.filesystem.write(flie_name,
        content) --复制到目录
        return
    
    nativefs.mount(PATH.base)

    elseif string.find(flie_name,".jpg") or string.find(flie_name,".jpeg") or 
    string.find(flie_name,".png") or string.find(flie_name,".json") then --bg/谱面文件
        love.filesystem.newFile(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..flie_name,"w") --复制到当前文件夹下
        love.filesystem.write(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..flie_name,
        content) --复制到新的文件夹
    elseif string.find(flie_name,".mc") then --mc文件
        local json_name= string.sub(flie_name,1, string.find(flie_name, ".[^.]*$")).."json" --更改后缀
        love.filesystem.newFile(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..json_name,"w") --复制到当前文件夹下
        love.filesystem.write(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..json_name,
        tableToString(mc_to_takumi(content))) --复制到新的文件夹

    elseif string.find(flie_name,".json") then
        local json_name= flie_name --更改后缀
        love.filesystem.newFile(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..json_name,"w") --复制到当前文件夹下
        love.filesystem.write(PATH.usersPath.chart..menu.chartTab[menu.selectMusicPos].."/"..json_name,
        content) --复制到新的文件夹

    elseif string.find(flie_name,".ogg") or string.find(flie_name,".mp3") or string.find(flie_name,".wav") then --音频文件
        --创建新文件夹
        local path_name = flie_name --文件夹名
        local music_type = get_music_type(file)

        if music_type == "unknown" then --后缀错误
            love.window.showMessageBox('Unknown audio format',i18n:get('Unknown audio format'))
            return
        end

        path_name= string.sub(path_name,1, string.find(path_name, ".[^.]*$"))   --删除后缀

        while love.filesystem.getInfo(PATH.usersPath.chart..path_name ) do --防止撞名
            path_name = path_name.."_"
        end
        local new_file_name = path_name.."."..music_type --防止后缀错误
        love.filesystem.createDirectory(PATH.usersPath.chart..path_name ) --创建新的文件夹
        love.filesystem.newFile(PATH.usersPath.chart..path_name.."/"..new_file_name,"w")
        love.filesystem.write(PATH.usersPath.chart..path_name.."/"..new_file_name,content) --复制到新的文件夹
        love.filesystem.newFile(PATH.usersPath.chart..path_name.."/"..'chart.json',"w")
        love.filesystem.write(PATH.usersPath.chart..path_name.."/"..'chart.json',dkjson.encode(meta_chart.__index)) --复制到新的文件夹
    end
    nativefs.unmount()
    menu:flushed() --重新加载
end