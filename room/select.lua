--选择的歌曲的房间
local pos = "select"
chart_tab = {} --所有谱面的文件夹
select_music_pos = 1 --选择到的谱面
select_chart_pos = 1 --选择到的歌曲
chart_info = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
path = ''
local ui_dakumi = love.graphics.newImage("asset/icon.png")

function select_music()
    if chart_tab[select_music_pos] then
        chart_info = {song_name = nil,bg = nil,chart_name = {},song = nil} --谱面的信息
        --输出选择到的谱面的谱面信息
        local file_tab = love.filesystem.getDirectoryItems("chart/"..chart_tab[select_music_pos]) --得到谱面文件夹下的谱面
        for i,v in ipairs(file_tab) do
            if string.find(v,".d3") then --谱面文件
                local info = love.filesystem.read("chart/"..chart_tab[select_music_pos].."/"..v)
                pcall(function() info = loadstring("return "..info)() end)
                local is_true_chart = true
                if type(info) ~= "table" then
                    log("It is "..type(info))
                    is_true_chart = false
                    info = {}
                end
                setmetatable(info,meta_chart) --防谱报废
                fillMissingElements(info,meta_chart.__index)


                fillMissingElements(chart,meta_chart.__index)
                chart_info.song_name = info.info.song_name
                chart_info.chart_name[#chart_info.chart_name + 1] = {name = info.info.chart_name,
                path = "chart/"..chart_tab[select_music_pos].."/"..v,is_true_chart = is_true_chart}
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

    love.filesystem.createDirectory("chart" )
    chart_tab = love.filesystem.getDirectoryItems("chart" ) --得到谱面文件夹下的所有谱面
    
    love.filesystem.createDirectory("temporary" )
    local temporary_tab = love.filesystem.getDirectoryItems("temporary" ) --得到文件夹下的所有文件
    for i ,v in ipairs(temporary_tab) do
        love.filesystem.remove("temporary".."/"..v) --删除临时文件
    end

    love.filesystem.createDirectory("auto_save" ) --创建自动保存文件夹

    love.filesystem.createDirectory("ui")

    local export_path = "/export"
    nativefs.mount(love.filesystem.getSourceBaseDirectory( ))
    nativefs.createDirectory(export_path)
    nativefs.unmount()
    
    select_music()

end
room_select = {
    load = function()

            objact_button_todakumi_in_select.load(850,0,0,25,25)
            objact_button_togithub_in_select.load(850,25,0,25,25)
            objact_edit_chart.load(0,750,0,100,50)
            objact_delete_chart.load(100,750,0,100,50)
            objact_new_chart.load(200,750,0,100,50)
            
            objact_file_selection_dialog_box.load(1100,0,0,100,50)
            objact_flushed.load(1200,0,0,100,50)
            objact_export.load(1300,0,0,100,50)
            objact_delete_music.load(1400,0,0,100,50)
            objact_open_directory.load(1500,0,0,100,50)
            
            --objact_select_file.load(1400,0,0,100,50)
            
            
            --objact_selector.load(500,50,0,1100,800)

        load_select()
    end,
    draw = function()
        if not the_room_pos(pos) then
            return
        end
        
        love.graphics.setColor(1,1,1,0.2)

        --装饰网格
        for i= 0,74 do
            love.graphics.rectangle('fill',i*25,0,1,800)
        end
        for i= 0,32 do
            love.graphics.rectangle('fill',0,i*25,1600,1)
        end

        love.graphics.setColor(1,1,1,1)

        if chart_info.bg then

            local bg_width, bg_height = chart_info.bg:getDimensions( ) -- 得到宽高
            local bg_scale_h
            local bg_scale_w
            bg_scale_h = 1 / bg_height * 300 
            bg_scale_w = 1 / bg_height * 300 / (window_w_scale / window_h_scale)
            love.graphics.draw(chart_info.bg,400 - 150 /bg_height *bg_width ,400 - 150,0,bg_scale_w,bg_scale_h,0,0,0,0)
            love.graphics.rectangle('fill',400 - 150 /bg_height *bg_width - 10,400 - 150 - 10,10,5)
            love.graphics.rectangle('fill',400 - 150 /bg_height *bg_width - 10,400 - 150 - 10,5,10)

            love.graphics.rectangle('fill',400 + 150 /bg_height *bg_width + 10,400 + 150 + 10,-10,-5)
            love.graphics.rectangle('fill',400 + 150 /bg_height *bg_width + 10,400 + 150 + 10,-5,-10)

        end
        love.graphics.setFont(font_plus)

        love.graphics.setLineWidth(1)
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.polygon("line",1220,0,1100,400,1220,800,1600,800,1600,0)

        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(3)
        love.graphics.line(1210,0,1090,400)
        love.graphics.line(1090,400,1210,800)

        love.graphics.setLineWidth(1)
        --图像范围限制函数
        local function myStencilFunction()
            love.graphics.polygon("fill",1220,0,1100,400,1220,800,1600,800,1600,0)
        end

        love.graphics.stencil(myStencilFunction, "replace", 1)
        love.graphics.setStencilTest("greater", 0)
        --输出所有歌曲
        --背景板
        ui_style:button(1100,0,600,800)

        local middle = 350 --信息显示中心
        local real_middle = 400 --真的中心
        local the_music_pos = 1 --用来当做i的
        local fontHeight = love.graphics.getFont():getHeight() --字体高度
        for i,v in ipairs(chart_tab) do
            if the_music_pos == select_music_pos then
                

                love.graphics.setColor(1,1,1,0.2)
                love.graphics.rectangle("fill",1100,middle,600,100)

                love.graphics.setColor(1,1,1,1)
                love.graphics.printf( v, 1100,real_middle - fontHeight / 2,600, "center")
                
            else
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.printf( v, 1100 + math.abs(select_music_pos - the_music_pos) *30,(the_music_pos -select_music_pos)*100+ real_middle - fontHeight / 2,600, "center")
            end
            the_music_pos = the_music_pos + 1
            
        end
        
        
        --图像范围限制函数
        local function myStencilFunction()
            love.graphics.polygon("fill",900,400,900,800,1220,800,1100,400)
        end

        love.graphics.stencil(myStencilFunction, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        love.graphics.setFont(font)
        local fontHeight = love.graphics.getFont():getHeight() --字体高度
        local chart_middle = 587.5
        local real_chart_middle = 600 --真的中心
        love.graphics.setColor(1,1,1,1)

        --谱面信息展示
        
        for i = 1,#chart_info.chart_name do --谱面名
            if i == select_chart_pos then
                love.graphics.setColor(1,1,1,0.2)
                love.graphics.rectangle("fill",900,chart_middle,300,25)

                love.graphics.setColor(1,1,1,1)
                if not chart_info.chart_name[i].is_true_chart then love.graphics.setColor(1,0.5,0.5,1) end
                love.graphics.printf( "chart"..i..":"..chart_info.chart_name[i].name, 900,real_chart_middle - fontHeight / 2,300, "center")
            else
                love.graphics.setColor(1,1,1,1-math.abs(select_chart_pos -i)*0.15)
                if not chart_info.chart_name[i].is_true_chart then love.graphics.setColor(1,0.5,0.5,1) end
                love.graphics.printf(  "chart"..i..":"..chart_info.chart_name[i].name, 900,(select_chart_pos -i)*25+ real_chart_middle  - fontHeight / 2,300, "center")
            end
        end

        love.graphics.setStencilTest()

        love.graphics.setFont(font_plus)
        love.graphics.setColor(1,1,1,1)
        --[[ove.graphics.print(
        objact_language.get_string_in_languages('You can drag the chart or folder containing the chart or song to the window for import.')
        ,0,720)]]
        --上下两边的边框
        love.graphics.setColor(1,1,1,1)
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
        if mouse.x > 1150 and mouse.x < 1600 then

            if y < 0 then
                select_music_pos = select_music_pos + 1
            else
                select_music_pos = select_music_pos - 1
            end

            if select_music_pos > #chart_tab then
                select_music_pos = #chart_tab
            elseif select_music_pos < 1 then 
                select_music_pos = 1
            end

            select_chart_pos = 1 --归位
            select_music()
        elseif mouse.x > 800 and mouse.x < 1150 then

            if y < 0 then
                select_chart_pos = select_chart_pos + 1
            else
                select_chart_pos = select_chart_pos - 1
            end

            if select_chart_pos > #chart_info.chart_name then
                select_chart_pos = #chart_info.chart_name
            elseif select_chart_pos < 1 then 
                select_chart_pos = 1
            end

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

    end,
    mousepressed = function( x, y, button, istouch, presses )
        if not the_room_pos(pos) then
            return
        end
        --objact_selector.mousepressed(x,y,button,istouch,presses)

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