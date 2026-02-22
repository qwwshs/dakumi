local layout         = require 'config.layouts.menu' --菜单布局
local colors         = require 'config.colors.menu'  --菜单颜色
local file_extension = {
    music = { 'mp3', 'ogg', 'wav' },
    chart = { 'json' },
    old_chart = { 'd3' },
    bg = { 'jpg', 'jpeg', 'png' }
}
menu                 = room:new('menu')
menu.color           = colors
room:addRoom(menu)
menu:addObject(require 'src.objects.menu.select_music')
menu:addObject(require 'src.objects.menu.select_chart')
menu:addObject(require 'src.objects.menu.FFT')

--选择的歌曲的房间
menu.chartTab = {}                                                          --所有谱面的文件夹
menu.selectMusicPos = 1                                                     --选择到的谱面
menu.selectChartPos = 1                                                     --选择到的歌曲
menu.chartInfo = { song_name = nil, bg = nil, chart_name = {}, song = nil } --谱面的信息
menu.path = ''
menu.bgPath = ''
menu.musicPath = ''

local effect = moonshine(WINDOW.nowW, WINDOW.nowH, moonshine.effects.gaussianblur) -- 高斯模糊
    .chain(moonshine.effects.boxblur)                                            -- 盒模糊
effect.gaussianblur.sigma = 3.5                                                  -- 模糊强度
effect.boxblur.radius = 100                                                      -- 模糊强度

local flesh_st = false                                                           --闪烁
local bg_animation = {
    usetime = 0.5,
    st = { alpha = 1 },
    now = { alpha = 1 },
    ed = { alpha = 0.5 },
    trans = 'linear',
    callback = function() flesh_st = true end,
    st2 = { alpha = 0.55 },
    ed2 = { alpha = 0.5 },
    trans2 = 'linear',
}

local beat_last = 0 --用于动画

local menuUI = require 'src.objects.menu.ui'

function menu:check(istype, file) --检查格式是否正确
    if istype == 'chart' then
        local s = pcall(function() file = dkjson.decode(file) end)
        local is_true_chart = true
        if not s then
            log("It is " .. type(file))
            log(file)
            is_true_chart = false
            file = {}
            return is_true_chart
        end
        return is_true_chart
    elseif istype == 'bg' then
        return pcall(function()
            nativefs.mount(PATH.base)
            love.graphics.newImage(file)
            nativefs.unmount()
        end)
    elseif istype == 'music' then
        return pcall(function()
            nativefs.mount(PATH.base)
            love.audio.newSource(file, "stream")
            nativefs.unmount()
        end)
    end
end

function menu:select_music()
    if menu.chartTab[menu.selectMusicPos] then
        love.audio.stop()                                                           --停止上一个歌曲
        beat_last = 0
        menu.chartInfo = { song_name = nil, bg = nil, chart_name = {}, song = nil } --谱面的信息
        --输出选择到的谱面的谱面信息
        nativefs.mount(PATH.base)
        local now_file_path = PATH.usersPath.chart .. menu.chartTab[menu.selectMusicPos] .. "/"
        local file_tab = love.filesystem.getDirectoryItems(PATH.usersPath.chart .. menu.chartTab[menu.selectMusicPos]) --得到谱面文件夹下的谱面
        for i, v in ipairs(file_tab) do
            local v_extemsion = getFileExtension(v)
            print("found file:", v_extemsion)
            if table.find(file_extension.chart, v_extemsion) then --谱面文件
                local info = love.filesystem.read(now_file_path .. v)
                local is_true_chart = menu:check('chart', info)
                if is_true_chart then
                    info = dkjson.decode(info)
                else
                    info = {}
                end
                table.fill(info, meta_chart.__index)
                table.fill(chart, meta_chart.__index)
                menu.chartInfo.song_name = info.info.song_name
                menu.chartInfo.chart_name[#menu.chartInfo.chart_name + 1] = {
                    name = info.info.chart_name,
                    path = now_file_path .. v,
                    is_true_chart = is_true_chart
                }
                if menu.selectChartPos == #menu.chartInfo.chart_name then
                    chart = table.copy(info)        --读取谱面
                    setmetatable(chart, meta_chart) --防谱报废
                end
            end
            if table.find(file_extension.bg, getFileExtension(v)) then --bg
                menu.bgPath = now_file_path .. v
                if menu:check('bg', menu.bgPath) then
                    menu.chartInfo.bg = love.graphics.newImage(PATH.usersPath.chart ..
                        menu.chartTab[menu.selectMusicPos] .. "/" .. v)
                    bg = menu.chartInfo.bg
                    bg_animation.now.alpha = bg_animation.st.alpha
                    flesh_st = false
                    timer.tween(bg_animation.usetime, bg_animation.now, bg_animation.ed, bg_animation.trans,
                        bg_animation.callback)
                else
                    menu.chartInfo.bg = nil
                    bg = nil
                    log("bg file error")
                end
            end
        end
        table.fill(chart, meta_chart.__index)
        for i, v in ipairs(file_tab) do                                   --因为一些数据在chart里面 所以分开读
            local v_extemsion = getFileExtension(v)
            if table.find(file_extension.music, getFileExtension(v)) then --歌曲
                love.audio.stop()                                         --停止上一个歌曲
                if menu:check('music', now_file_path .. v) then
                    menu.chartInfo.song = love.audio.newSource(
                        now_file_path .. v, "stream")
                    love.audio.setVolume(settings.music_volume / 100) --设置音量大小
                    menu.chartInfo.song:play()

                    --读取音频信息
                    music = menu.chartInfo.song
                    menu.musicPath = now_file_path .. v
                    time.alltime = music:getDuration() + chart.offset / 1000
                    beat.allbeat = beat:toBeat(chart.bpm_list, time.alltime)
                else
                    log("music file error")
                    menu.chartInfo.song = nil
                    music = nil
                    time.alltime = 0
                    beat.allbeat = 0
                end
            end
        end

        nativefs.unmount()
    end
    self('select_music')
end

function menu:flushed()                                                         --刷新
    menu.chartTab = {}                                                          --所有谱面的文件夹
    menu.chartInfo = { song_name = nil, bg = nil, chart_name = {}, song = nil } --谱面的信息
    love.audio.stop()                                                           --停止上一个歌曲

    local dir = love.filesystem.getIdentity()                                   --文件的写入目录

    love.filesystem.createDirectory("chart")

    nativefs.mount(PATH.base)
    menu.chartTab = nativefs.getDirectoryItems(PATH.usersPath.chart) --得到谱面文件夹下的所有谱面
    nativefs.unmount()

    love.filesystem.createDirectory("temporary")
    local temporary_tab = love.filesystem.getDirectoryItems("temporary") --得到文件夹下的所有文件
    for i, v in ipairs(temporary_tab) do
        love.filesystem.remove("temporary" .. "/" .. v)                  --删除临时文件
    end

    love.filesystem.createDirectory("auto_save") --创建自动保存文件夹

    love.filesystem.createDirectory("ui")

    menu:select_music()
end

function menu:load()
    menu('load')
    menu:flushed()
end

function menu:draw()
    love.graphics.setColor(colors.line1)
    --装饰网格
    for i = 0, 74 do
        love.graphics.rectangle('fill', i * 25, 0, 1, WINDOW.h)
    end
    for i = 0, 36 do
        love.graphics.rectangle('fill', 0, i * 25, WINDOW.w, 1)
    end
    effect.draw( --模糊背景
        function()
            love.graphics.setColor(1, 1, 1, bg_animation.now.alpha)

            if menu.chartInfo.bg then
                local bg_width, bg_height = menu.chartInfo.bg:getDimensions() -- 得到宽高
                local bg_scale_h = 1 / bg_height * WINDOW.nowH
                local bg_scale_w = 1 / bg_width * WINDOW.nowW
                love.graphics.draw(menu.chartInfo.bg, 0, 0, 0, bg_scale_w, bg_scale_h) --居中显示
            end
        end
    )
    love.graphics.setColor(1, 1, 1)

    if menu.chartInfo.bg then
        local bg_width, bg_height = menu.chartInfo.bg:getDimensions() -- 得到宽高
        local bg_scale_h
        local bg_scale_w
        bg_scale_h = 1 / bg_height * layout.bg.size
        bg_scale_w = 1 / bg_height * layout.bg.size
        love.graphics.draw(menu.chartInfo.bg, layout.bg.x - layout.bg.size / 2 / bg_height * bg_width,
            layout.bg.y - layout.bg.size / 2, 0, bg_scale_w, bg_scale_h)
        love.graphics.rectangle('fill',
            layout.bg.x - layout.bg.size / 2 / bg_height * bg_width - layout.bg.pointSize,
            layout.bg.y - layout.bg.size / 2 - layout.bg.pointSize, layout.bg.pointSize, layout.bg.pointSize)

        love.graphics.rectangle('fill',
            layout.bg.x + layout.bg.size / 2 / bg_height * bg_width + layout.bg.pointSize,
            layout.bg.y + layout.bg.size / 2 + layout.bg.pointSize, -layout.bg.pointSize, -layout.bg.pointSize)
    end

    menu('draw')
end

function menu:wheelmoved(x, y)
    menu('wheelmoved', x, y)
end

function menu:mousereleased(x, y, button, istouch, presses)
    menu('mousereleased', x, y, button, istouch, presses)
end

function menu:update(dt)
    menu('update', dt)

    --更新music时间
    if menu.chartInfo.song then
        time.nowtime = time.nowtime + dt
        beat.nowbeat = beat:toBeat(chart.bpm_list, time.nowtime)
    else
        time.nowtime = 0
    end
    if chart and chart.bpm_list and #chart.bpm_list > 0 then
        beat.nowbeat = beat:toBeat(chart.bpm_list, time.nowtime)
    end
    if chart and chart.bpm_list and #chart.bpm_list > 0 and math.floor(beat.nowbeat) ~= beat_last then
        bg_animation.now.alpha = bg_animation.st2.alpha
        beat_last = math.floor(beat.nowbeat)
        if flesh_st then
            timer.tween(
            beat:toTime(chart.bpm_list, math.floor(beat.nowbeat) + 1) -
            beat:toTime(chart.bpm_list, math.floor(beat.nowbeat)), bg_animation.now, bg_animation.ed2,
                bg_animation.trans2)
        end
    end

    if Nui:windowBegin('chartTool', layout.chartTool.x, layout.chartTool.y, layout.chartTool.w, layout.chartTool.h, 'border') then
        Nui:layoutRow('dynamic', layout.chartTool.h, layout.chartTool.cols)
        for i, obj in ipairs(menuUI.chartTool) do
            if obj.type == 'button' then
                if Nui:button(i18n:get(obj.text), obj.img) then
                    obj.func()
                end
            end
        end

        Nui:windowEnd()
    end
    if Nui:windowBegin('fileTool', layout.fileTool.x, layout.fileTool.y, layout.fileTool.w, layout.fileTool.h, 'border') then
        Nui:layoutRow('dynamic', layout.fileTool.h, layout.fileTool.cols)
        for i, obj in ipairs(menuUI.fileTool) do
            if obj.type == 'button' then
                if Nui:button(i18n:get(obj.text), obj.img) then
                    obj.func()
                end
            end
        end

        Nui:windowEnd()
    end
end

function menu:resize(w, h)
    effect.resize(w, h)
end

function menu:filedropped(file) -- 文件拖入
    menu('filedropped', file)
    file:open("r")
    local flie_name = file:getFilename()
    local lastSlashIndex = string.find(flie_name, "/[^/]*$") --找到最后一个斜杠的位置
    if not lastSlashIndex then
        lastSlashIndex = string.find(flie_name, "\\[^\\]*$") --找到最后一个斜杠的位置
    end
    if not lastSlashIndex then
        lastSlashIndex = 0
    end
    local content = file:read()
    local flie_name = string.sub(flie_name, lastSlashIndex + 1)
    local isfile_extension = getFileExtension(flie_name)

    nativefs.mount(PATH.base)
    local now_file_path = PATH.usersPath.chart .. menu.chartTab[menu.selectMusicPos] .. "/"
    if table.find(file_extension.bg, isfile_extension) then --bg
        nativefs.newFile(now_file_path .. flie_name)        --复制到当前文件夹下
        nativefs.write(now_file_path .. flie_name,
            content)
        --复制到新的文件夹
    elseif table.find(file_extension.chart, isfile_extension) then --谱面格式
        nativefs.newFile(now_file_path .. flie_name)               --复制到当前文件夹下
        nativefs.write(now_file_path .. flie_name,
            content)
    elseif table.find(file_extension.old_chart, isfile_extension) then                          --旧谱面格式
        local json_name = string.sub(flie_name, 1, string.find(flie_name, ".[^.]*$")) .. "json" --更改后缀
        nativefs.newFile(now_file_path .. json_name)                                            --复制到当前文件夹下

        --更新谱面格式
        chart = loadstring('return ' .. content)()
        setmetatable(chart, meta_chart)
        chart:update()
        log(nativefs.write(now_file_path .. json_name,
            dkjson.encode(chart)))                                              --复制到新的文件夹
    elseif table.find(file_extension.music, isfile_extension) then              --音频文件
        --创建新文件夹
        local path_name = flie_name                                             --文件夹名

        path_name = string.sub(path_name, 1, string.find(path_name, ".[^.]*$")) --删除后缀

        while love.filesystem.getInfo(PATH.usersPath.chart .. path_name) do     --防止撞名
            path_name = path_name .. "_"
        end
        local new_file_name = flie_name
        nativefs.createDirectory(PATH.usersPath.chart .. path_name)                        --创建新的文件夹
        nativefs.newFile(PATH.usersPath.chart .. path_name .. "/" .. new_file_name)
        nativefs.write(PATH.usersPath.chart .. path_name .. "/" .. new_file_name, content) --复制到新的文件夹

        --创建默认谱面
        nativefs.newFile(PATH.usersPath.chart .. path_name .. "/" .. 'chart.json')
        local tab = {}
        table.fill(tab, meta_chart.__index)
        nativefs.write(PATH.usersPath.chart .. path_name .. "/" .. 'chart.json', dkjson.encode(tab)) --复制到新的文件夹
    end
    nativefs.unmount()
    menu:flushed() --重新加载
end
