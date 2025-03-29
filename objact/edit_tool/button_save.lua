
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local quit_click = 0 --点击次数
local save_time = 0 --保存时间
local save_thread = love.thread.newThread('thread/save.lua') --线程
local coroutine_save_start = false --第一次开始
local will_save = 0 --将会保存
local saveing = false --保存中
-- 通信的频道  
save_thread:start() --启动

local function coroutine_save()
    if not coroutine_save_start then -- 为了第一次不保存
        coroutine_save_start = true
        return
    end
    --一个个传 避免爆炸
    love.thread.getChannel( 'save' ):push({"start",chart_info.chart_name[select_chart_pos].path}) -- 发送数据到线程
    local the_table_to_str = ""
    local frequency = 0
    local function to_yield() --用来挂起
        frequency = frequency + 1
        if frequency > 500 then --挂起
            frequency = 0
            coroutine.yield()  -- 暂停协程，允许其他操作执行
            log('yield')
        end
    end
    for i,v in pairs(chart.bpm_list) do
        the_table_to_str = tableToString(v)
        love.thread.getChannel( 'save' ):push({"bpm_list["..i .."]" ,the_table_to_str})
        to_yield()
    end
    
    for i,v in pairs(chart.note) do
        the_table_to_str = tableToString(v)
        love.thread.getChannel( 'save' ):push({"note["..i .."]" ,the_table_to_str})
        to_yield()
    end
    for i,v in pairs(chart.event) do
        the_table_to_str = tableToString(v)
        love.thread.getChannel( 'save' ):push({"event["..i .."]" ,the_table_to_str})
        to_yield()
    end
    for i,v in pairs(chart.info) do
        the_table_to_str = v
        love.thread.getChannel( 'save' ):push({"info['"..i .."']" ,"[["..the_table_to_str.."]]"})
        to_yield()
    end
    for i,v in pairs(chart.effect) do
        the_table_to_str = v
        love.thread.getChannel( 'save' ):push({"effect['"..i .."']" ,"[["..the_table_to_str.."]]"})
        to_yield()
    end
    for i,v in pairs(chart.preference) do
        the_table_to_str = v
        love.thread.getChannel( 'save' ):push({"preference['"..i .."']" ,"[["..the_table_to_str.."]]"})
        to_yield()
    end

    the_table_to_str = chart.offset
    love.thread.getChannel( 'save' ):push({"offset" ,the_table_to_str})
    love.thread.getChannel( 'save' ):push({"end"}) -- 发送数据到线程
    log('end')
end

-- 创建协程  
local the_coroutine_save= coroutine.create(coroutine_save)
local function will_draw()
    return the_room_pos({"edit",'tracks_edit'}) and not demo_mode
end

local function do_save()
    will_save = will_save + 1
    saveing = true 
    objact_message_box.message("save")
end

objact_save = { --分度改变用的
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("save",do_save,x,y,w,h,ui:save(x,y,w,h),{will_draw = will_draw})
    end,
    draw = function()
        if saveing then
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(objact_language.get_string_in_languages('saving'),x + w ,y)
            local alpha = math.floor(elapsed_time*2) % 2
            love.graphics.setColor(1,1,1,alpha)
            love.graphics.rectangle("fill",x+w + 5,y+h/2,10,10) --加载动画
        end
    end,
    keyboard = function(key)
        if key == "s" and isctrl == true  then
            do_save()
        end
    end,

    mousepressed = function( x1, y1, button, istouch, presses )
    end,

    update = function(dt)
        if elapsed_time - save_time >= 114 and demo_mode == false and settings.auto_save == 1 then --保存
            save_time = elapsed_time
            do_save()
            objact_message_box.message("auto_save")
        end
        local msg = love.thread.getChannel( 'save completed' ):pop()  --得到
        if msg then
            objact_message_box.message("save completed")
            saveing = false
        end

        if coroutine.status(the_coroutine_save) ~= "dead" then
            local s,err = coroutine.resume(the_coroutine_save)  -- 恢复协程执行
            if err then
                log("coroutine:"..err)
            end
        elseif will_save > 0 and coroutine.status(the_coroutine_save) == "dead" then
            the_coroutine_save= coroutine.create(coroutine_save) --协程死了
            will_save = will_save - 1
        end

    end,
    quit = function()
    if quit_click > 0 then --防止无法退出
        return
    end
    quit_click = quit_click + 1

    -- 读取文本文件 内容相同直接退出
    local ischart = {}
    if chart_info.chart_name[select_chart_pos] then
        ischart = love.filesystem.read(chart_info.chart_name[select_chart_pos].path)  -- 以只读模式打开文件
        pcall(function() ischart = loadstring("return "..ischart)() end)
    end
    if type(chart) ~= "table" then
        return
    end
    if tablesEqual(ischart,chart) then
        return
    end
        local yes_func = function() save(chart,"chart.d3") love.event.quit(0) end
        local no_func = function()  love.event.quit(0) end
        objact_message_box.message_window_dlsplay("save",yes_func,no_func)
        return true
    end,
}