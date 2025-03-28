--选择的歌曲的房间
local pos = "select"
chart_tab = {} --所有谱面的文件夹
local music_pos = 0 --移动显示的位置
local chart_pos = 0 --移动显示的位置
select_music_pos = 1 --选择的歌曲
select_chart_pos = 1 --选择的谱面
chart_info = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
path = ''
animation_new("select_music_pos_x",1080,1080,0,0,{1,1,1,1})
animation.select_bg_alpha = 0.3

local function select_music()
    if chart_tab[select_music_pos] then
        chart_info = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
        --输出选择到的谱面的谱面信息
        local file_tab = love.filesystem.getDirectoryItems("chart/"..chart_tab[select_music_pos]) --得到谱面文件夹下的谱面
        for i,v in ipairs(file_tab) do
            if string.find(v,".d3") then --谱面文件
                local info = love.filesystem.read("chart/"..chart_tab[select_music_pos].."/"..v)
                pcall(function() info = loadstring("return "..info)() end)
                if type(info) ~= "table" then
                    love.filesystem.write("chart/"..chart_tab[select_music_pos].."/"..v,tableToString(meta_chart.__index))
                    info = copyTable(meta_chart.__index)
                end
                setmetatable(info,meta_chart) --防谱报废
                fillMissingElements(info,meta_chart.__index)


                fillMissingElements(chart,meta_chart.__index)
                chart_info.song_name = info.info.song_name
                chart_info.chart_name[#chart_info.chart_name + 1] = {name = info.info.chart_name,
                path = "chart/"..chart_tab[select_music_pos].."/"..v}
                if select_chart_pos == #chart_info.chart_name then
                    chart = copyTable(info) --读取谱面
                    setmetatable(chart,meta_chart) --防谱报废
                end
            end
            if string.find(v,".jpg") or string.find(v,".png") then --bg
                chart_info.bg = love.graphics.newImage("chart/"..chart_tab[select_music_pos].."/"..v)

                bg = chart_info.bg
            end
            
        end
        for i,v in ipairs(file_tab) do --因为一些数据在chart里面 所以分开读
            if string.find(v,".mp3") or string.find(v,".ogg") or string.find(v,".wav") then --歌曲
                love.audio.stop( ) --停止上一个歌曲
                chart_info.song = love.audio.newSource("chart/"..chart_tab[select_music_pos].."/"..v, "stream")
                love.audio.setVolume( settings.music_volume / 100 ) --设置音量大小
                chart_info.song:play()

                --读取音频信息
                music = chart_info.song
                time.alltime = music:getDuration() + chart.offset / 1000 -- 得到音频总时长
                beat.allbeat = time_to_beat(chart.bpm_list,time.alltime)
            end
        end

        if not chart_info.song then
            love.audio.stop( ) --停止上一个歌曲
        end
    end
end

function load_select() --刷新
    
    chart_tab = {} --所有谱面的文件夹
    chart_info = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
    love.audio.stop( ) --停止上一个歌曲

    local dir = love.filesystem.getIdentity() --文件的写入目录
    local is_chart,is_chart_type = love.filesystem.getInfo( "chart" ) --得到chart文件夹是否存在
    if not (is_chart) or is_chart_type ~= 'directory' then
        love.filesystem.createDirectory("chart" )
    end
    chart_tab = love.filesystem.getDirectoryItems("chart" ) --得到谱面文件夹下的所有谱面
    
    local is_temporary,is_temporary_type = love.filesystem.getInfo( "temporary" ) --得到local文件夹是否存在
    if not (is_temporary) or is_temporary_type ~= 'directory' then
        love.filesystem.createDirectory("temporary" )
    end
    local temporary_tab = love.filesystem.getDirectoryItems("temporary" ) --得到文件夹下的所有文件
    for i ,v in ipairs(temporary_tab) do
        love.filesystem.remove("temporary".."/"..v)
    end
    local ui_tab,ui_type = love.filesystem.getDirectoryItems("ui") --得到文件夹下的所有文件
    if not (ui_tab) or ui_type ~= 'directory' then
        love.filesystem.createDirectory("ui")
    end
    select_music()

end
room_select = {
    load = function()

            objact_button_todakumi_in_select.load(850,0,0,25,25)
            objact_button_togithub_in_select.load(850,25,0,25,25)
            objact_edit_chart.load(0,750,0,100,50)
            objact_delete_chart.load(100,750,0,100,50)
            objact_new_chart.load(200,750,0,100,50)
            objact_open_directory.load(1500,0,0,100,50)
            objact_flushed.load(1200,0,0,100,50)
            --objact_select_file.load(1400,0,0,100,50)
            objact_delete_music.load(1400,0,0,100,50)
            objact_export.load(1300,0,0,100,50)
            --objact_selector.load(500,50,0,1100,800)
            objact_file_select.load(1100,0,0,100,50)

        load_select()
    end,
    draw = function()
        if not the_room_pos(pos) then
            return
        end
        
        love.graphics.setFont(font_plus)

        love.graphics.setColor(1,1,1,animation.select_bg_alpha)
        --曲绘
        if chart_info.bg then
            local bg_width, bg_height = chart_info.bg:getDimensions( ) -- 得到宽高
            local bg_scale_h = 1 / bg_width * 1600 
            local bg_scale_w = 1 / bg_width * 1600 / (window_w_scale / window_h_scale)
            love.graphics.draw(chart_info.bg,0,0,0,bg_scale_w,bg_scale_h)
        end
        

        love.graphics.setFont(font_plus)
        if type(chart_info.song_name) == "string" then --曲名
            love.graphics.print(chart_info.song_name,0,0)
        end
        

        --输出所有歌曲
        
        local the_music_pos = 1 --用来当做i的
        for i,v in ipairs(chart_tab) do
            if the_music_pos == select_music_pos then
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",animation.select_music_pos_x,(the_music_pos +music_pos)*100,600,100)
                ui_style:button(animation.select_music_pos_x,(the_music_pos +music_pos)*100,600,100,v)
            else
                love.graphics.setColor(0,0,0,0.5)
                love.graphics.rectangle("fill",1200,(the_music_pos +music_pos)*100,600,100)
                ui_style:button(1200,(the_music_pos +music_pos)*100,600,100,v)
            end
            the_music_pos = the_music_pos + 1
            
        end

        --选择到的歌曲
        love.graphics.setColor(0,1,1,0.3)
        love.graphics.rectangle("fill",animation.select_music_pos_x ,(select_music_pos +music_pos)*100,10,100) 

        
        love.graphics.setColor(1,1,1,1)
        --歌曲信息展示


        
        --选择到的谱面
        if #chart_info.chart_name > 0 then
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line",300 ,330+ (select_chart_pos +chart_pos)*30,300,30) 
        end

        love.graphics.setFont(font)
        for i = 1,#chart_info.chart_name do --谱面名
            ui_style:button(300 ,330+ (chart_pos +i)*30,300,30,"chart"..i..": "..chart_info.chart_name[i].name)
        end


        love.graphics.setFont(font_plus)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(
        objact_language.get_string_in_languages('You can drag the chart or folder containing the chart or song to the window for import.')
        ,0,720)
        --上下两边的边框
        love.graphics.setColor(0,1,1,1)
        love.graphics.circle('fill',750,780,30,4)
        love.graphics.circle('fill',850,20,30,4)
        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle("fill",850,0,750,50)
        love.graphics.rectangle("fill",0,750,750,50)    
        love.graphics.circle('fill',750,775,25,4)
        love.graphics.circle('fill',850,25,25,4)    

        --objact_select_file.draw()
        --objact_selector.draw()

        love.graphics.setFont(font)
        love.graphics.setColor(1,1,1,1)

    end,
    keypressed = function(key)
        if not the_room_pos(pos) then
            return
        end
        --objact_selector.keyboard(key)

    end,
    wheelmoved = function(x,y)
        if not the_room_pos(pos) then
            return
        end
        --objact_selector.wheelmoved(x,y)
        if mouse.x > 800 and mouse.x < 1600 then
            if y > 0 then
                music_pos = music_pos + 1
            else
                music_pos = music_pos - 1
            end
        elseif mouse.x > 300 and mouse.x < 600 then
            if y > 0 then
                chart_pos = chart_pos + 1
            else
                chart_pos = chart_pos - 1
            end
        end
        while 330+ (#chart_info.chart_name +chart_pos)*30 < 0 do
            chart_pos = chart_pos + 1
        end
        while 330+ (1 +chart_pos)*30 > 800 do
            chart_pos = chart_pos - 1
        end
        while 20+ (#chart_tab +music_pos)*100 < 0 do
            music_pos = music_pos + 1
        end
        while 20+ (1 +music_pos)*100 > 800 do
            music_pos = music_pos - 1
        end
    end,
    mousepressed = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
        --objact_selector.mousepressed(x,y,button,istouch,presses)


        --点击选择歌曲
        if x > 1000 and x < 1600 and y > 50 and y < 750 and select_music_pos ~= math.floor(y/100) - music_pos then
            local temp_select_music_pos = math.floor(y/100) - music_pos
            if temp_select_music_pos < 1 then
                return
            end
            if temp_select_music_pos > #chart_tab then
                return
            end
            select_music_pos = temp_select_music_pos

            select_music()

            select_chart_pos = 1 --归位
            chart_pos = 0
    
            animation_new("select_music_pos_x",1200,1080,0,0.2,{1,1,1,1})
            animation_new("select_bg_alpha",0,0.3,0,0.2,{0,0,1,1})

        elseif x >= 300 and x <= 600 and y > 50 and y < 750 then --选择谱面
            local temp_select_chart_pos = math.floor((y -330)/30) - chart_pos
            if temp_select_chart_pos < 1 then
                return
            end
            if temp_select_chart_pos > #chart_info.chart_name then
                return
            end
            select_chart_pos = temp_select_chart_pos

            path = chart_info.chart_name[select_chart_pos].path
            local info = love.filesystem.read(path)
            
            pcall(function() info = loadstring("return "..info)() end)
            if type(info) ~= "table" then
                log("It is "..type(info))
                info = {}
            end
            setmetatable(info,meta_chart) --防谱报废
            fillMissingElements(info,meta_chart.__index)

            chart = copyTable(info) --读取谱面
            setmetatable(chart,meta_chart) --防谱报废
        end

        --objact_select_file.mousepressed(x,y,button,istouch,presses)


    end,

    mousereleased = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
    end,
    update = function(dt)
        if not the_room_pos(pos) then
            return
        end
        --objact_selector.update(dt)

    end,
    directorydropped = function(path ,iszip)
        love.filesystem.mount( path, "local_path",true)
        local local_path_tab = love.filesystem.getDirectoryItems("local_path" ) --得到文件夹下的所有内容
        for i,v in ipairs(local_path_tab) do
            if string.find(v,".ogg") or string.find(v,".mp3") or string.find(v,".wav") then --音频文件
                --先确定文件夹是否存在 存在就更改后缀
                local lastSlashIndex = string.find(path, "/[^/]*$") --找到最后一个斜杠的位置
                if not lastSlashIndex then
                    lastSlashIndex = string.find(path, "\\[^\\]*$") --找到最后一个斜杠的位置
                end
                if not lastSlashIndex then
                    lastSlashIndex = 0
                end
                local path_name = string.sub(path, lastSlashIndex + 1)

                if iszip and iszip == 'zip' then
                    path_name = string.sub(path_name,1, string.find(path_name, ".[^.]*$") - 1)   --删除后缀
                end

                while love.filesystem.getInfo("chart/"..path_name ) do --防止撞名
                    path_name = path_name.."_"
                end

                love.filesystem.createDirectory("chart/"..path_name ) --创建新的文件夹
                for k,a in ipairs(local_path_tab) do --复制到新目录
                    love.filesystem.newFile("chart/"..path_name.."/"..a,"w")
                    love.filesystem.write("chart/"..path_name.."/"..a,
                    love.filesystem.read("local_path/"..a)) --复制到新的文件夹
                end
                love.filesystem.unmount("local_path") --卸载
                --补充chart
                local is_chart = false
                for  i,v in ipairs(local_path_tab) do
                    if string.find(v,".d3") then
                        is_chart = true
                    end
                end
                if not is_chart then --里面没有谱面
                    love.filesystem.newFile("chart/"..path_name.."/"..'chart.d3',"w")
                    love.filesystem.write("chart/"..path_name.."/"..'chart.d3',tableToString(meta_chart.__index)) --复制到新的文件夹
                end
                break
            end
        end

        load_select() --重新加载
    end,
    filedropped = function(file) -- 文件拖入
        file:open("r")
        local flie_name = file:getFilename()   
        local lastSlashIndex = string.find(flie_name, "/[^/]*$") --找到最后一个斜杠的位置
        if not lastSlashIndex then
            lastSlashIndex = string.find(flie_name, "\\[^\\]*$") --找到最后一个斜杠的位置
        end
        if not lastSlashIndex then
            lastSlashIndex = 0 --找到最后一个斜杠的位置
        end
        local flie_name = string.sub(flie_name, lastSlashIndex + 1)
        if string.find(flie_name,"hit_sound") then
            love.filesystem.newFile(flie_name,"w")
            love.filesystem.write(flie_name,
            file:read()) --复制到目录
            return
        

        elseif string.find(flie_name,".jpg") or string.find(flie_name,".jpeg") or 
        string.find(flie_name,".png") or string.find(flie_name,".d3") then --bg/谱面文件
            love.filesystem.newFile("chart/"..chart_tab[select_music_pos].."/"..flie_name,"w") --复制到当前文件夹下
            love.filesystem.write("chart/"..chart_tab[select_music_pos].."/"..flie_name,
            file:read()) --复制到新的文件夹
        elseif string.find(flie_name,".mc") then --mc文件
            local d3_name= string.sub(flie_name,1, string.find(flie_name, ".[^.]*$")).."d3" --更改后缀
            love.filesystem.newFile("chart/"..chart_tab[select_music_pos].."/"..d3_name,"w") --复制到当前文件夹下
            love.filesystem.write("chart/"..chart_tab[select_music_pos].."/"..d3_name,
            tableToString(mc_to_takumi(file:read()))) --复制到新的文件夹


        elseif string.find(flie_name,".ogg") or string.find(flie_name,".mp3") or string.find(flie_name,".wav") then --音频文件
            --创建新文件夹
            local path_name = flie_name --文件夹名
            local music_type = get_music_type(file)

            if music_type == "unknown" then --后缀错误
                objact_message_box.message_window_dlsplay('Unknown audio format',function() end,function() end)
                return
            end

            path_name= string.sub(path_name,1, string.find(path_name, ".[^.]*$"))   --删除后缀

            while love.filesystem.getInfo("chart/"..path_name ) do --防止撞名
                path_name = path_name.."_"
            end
            local new_file_name = path_name.."."..music_type --防止后缀错误
            love.filesystem.createDirectory("chart/"..path_name ) --创建新的文件夹
            love.filesystem.newFile("chart/"..path_name.."/"..new_file_name,"w")
            love.filesystem.write("chart/"..path_name.."/"..new_file_name,file:read()) --复制到新的文件夹
            love.filesystem.newFile("chart/"..path_name.."/"..'chart.d3',"w")
            love.filesystem.write("chart/"..path_name.."/"..'chart.d3',tableToString(meta_chart.__index)) --复制到新的文件夹
        elseif string.find(flie_name,".dkz") then
            room_select.directorydropped(file:getFilename(),'zip') --当文件读
        end
        load_select() --重新加载
    end
}