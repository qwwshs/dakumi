version = "0.4.0"
beat = {nowbeat = 0,allbeat = 100}
time = {nowtime = 0 ,alltime = 100}
denom = {scale = 1,denom = 4} --分度的缩放和使用的分度
chart = {}
track = {track = 1,fence = 20} -- 第一个轨道
language = {} --语言表
bg = nil
music = nil
music_data = {count = 0,soundData = nil} --音频可视化用的
room_pos = "start" --所属房间
music_play = false
mouse  = {x = 0,y = 0,original_x = 0,original_y = 0, down_state = false}--鼠标按下状态
elapsed_time = 0 -- 已运行时间
font = love.graphics.newFont("LXGWNeoXiHei.ttf", 13) -- 字体 
font_plus = love.graphics.newFont("LXGWNeoXiHei.ttf", 26) -- 字体 plus
isctrl  = false --ctrl按下状态
isalt = false --alt按下状态
iskeyboard = {} --key的按下状态
note_occurrence_point = -1000 --note出现点 （斜轨用的）
music_speed = 1 --播放速度
demo_mode = false --演示状态
window_w_scale = 1
window_h_scale = 1

require 'the_require'

love.window.setTitle("Dakumi editor")

function the_room_pos(pos) -- 房间状态判定
    local isroom = false
    if type(pos) == 'table' then
        for i, v in ipairs(pos) do
            if the_room_pos(v) then
                isroom = true
            end
        end

        return isroom
    else
        return pos == room_pos
    end
end

function love.load()
    --初始化
    love.graphics.setFont(font)
    setmetatable(chart,meta_chart) --防谱报废
        local language_file = io.open("language.txt", "r")  -- 以只读模式打开文件
        if language_file then
            local content = language_file:read("*a")  -- 读取整个文件内容
            language_file:close()  -- 关闭文件
            language = loadstring("return "..content)()
        end
        if type(language) ~= "table" then
            language = {}
        end


    -- 读取设置文件
    local settings_file = io.open("settings.txt", "r")  -- 以只读模式打开文件
    if settings_file then
        local content = settings_file:read("*a")  -- 读取整个文件内容
        settings_file:close()  -- 关闭文件
        settings = loadstring("return "..content)()
    end
    if type(settings) ~= "table" then
        settings = {}
    end
    setmetatable(settings,meta_settings) --防谱报废
    
    fillMissingElements(settings,meta_settings.__index)
    room_start.load()
    if log then log("start") end
    love.keyboard.setKeyRepeat(true) --键重复

end
function love.update(dt)
    if love.window.getFullscreen()  then  --全屏
        local width, height = love.graphics.getDesktopDimensions()   
        if height / 800 ~= window_h_scale  and width / 1600 ~= window_w_scale then --窗口缩放不等于全屏的缩放
            window_w_scale = width / 1600
            window_h_scale = height / 800
            
        end
    end
    math.randomseed(elapsed_time) --随机数种子
    mouse.original_x, mouse.original_y = love.mouse.getPosition( ) --对缩放进行处理
    mouse.x = mouse.original_x / window_w_scale
    mouse.y = mouse.original_y / window_h_scale
    elapsed_time = elapsed_time + dt
    animation_update(dt)
    room_tracks_edit.update(dt)
    room_play.update(dt)
    room_sidebar.update(dt)
    room_select.update(dt)
    room_edit_tool.update(dt)
    room_start.update(dt)
    objact_message_box.update(dt)

end
function love.draw()
    love.graphics.scale(window_w_scale,window_h_scale)
    room_start.draw()
    room_play.draw()
    room_tracks_edit.draw()
    room_sidebar.draw()
    room_select.draw()
    room_edit_tool.draw()
    input_box_draw_all()
    switch_draw_all()
    button_draw_all()
    objact_message_box.draw()
    objact_mouse.draw()

end

function love.keypressed(key)
    if message_window == true then
        return
    end
    if key == "lctrl" or key == "rctrl" then
        isctrl = true
    end
    if key == "lalt" or key == "ralt" then
        isalt = true
    end
    iskeyboard[key] = true
    if string.sub(key,1,2) == "kp" then
        key = string.sub(key,3,3)
    end

    room_play.keypressed(key)
    room_tracks_edit.keypressed(key)
    room_sidebar.keypressed(key)
    room_edit_tool.keypressed(key)
    objact_message_box.message(key)
    input_box_key(key) --所有键入内容都照样读的 直接塞主函数
    room_select.keypressed(key)
end
function love.keyreleased(key)
    if message_window == true then
        return
    end
    if key == "lctrl" or key == "rctrl" then
        isctrl = false
    end 
    if key == "lalt" or key == "ralt" then
        isalt = false
    end
    iskeyboard[key] = false
    room_play.keyreleased(key)
    room_tracks_edit.keyreleased(key)
end

function love.wheelmoved(x, y)
    if message_window == true then
        return
    end
    room_play.wheelmoved(x,y)
    room_edit_tool.wheelmoved(x,y)
    room_tracks_edit.wheelmoved(x,y)
    room_sidebar.wheelmoved(x,y)
    room_select.wheelmoved(x,y)

end

function love.mousepressed( x, y, button, istouch, presses )
    x = mouse.x  --对缩放进行处理
    y = mouse.y
    mouse.down_state = true
    objact_message_box.mousepressed( x, y, button, istouch, presses )
    if message_window == true then
        return
    end
    room_play.mousepressed( x, y, button, istouch, presses )
    room_tracks_edit.mousepressed( x, y, button, istouch, presses )
    room_sidebar.mousepressed( x, y, button, istouch, presses )
    room_edit_tool.mousepressed( x, y, button, istouch, presses )
    room_select.mousepressed( x, y, button, istouch, presses )

    objact_mouse.mousepressed( x, y, button, istouch, presses )
    

end

function love.mousereleased( x, y, button, istouch, presses )
    x = mouse.x  --对缩放进行处理
    y = mouse.y
    mouse.down_state = false
    if message_window == true then
        return
    end
    objact_mouse.mousereleased( x, y, button, istouch, presses )
    room_sidebar.mousereleased( x, y, button, istouch, presses )
    room_play.mousereleased(x, y, button, istouch, presses)
    room_tracks_edit.mousereleased( x, y, button, istouch, presses )
    room_select.mousereleased( x, y, button, istouch, presses )
    room_edit_tool.mousereleased( x, y, button, istouch, presses )
    
    input_box_mousepressed(x, y)
    button_mousepressed(x,y)
    switch_mousepressed(x,y)
end

function love.textinput(input)
    if message_window == true then
        return
    end

    input_box_textinput(input)
end
function love.quit()
    if message_window == true then
        return true
    end
    local quit = room_edit_tool.quit()
    return quit
end

function love.resize( w, h )
    window_w_scale = w / 1600
    window_h_scale = h / 800
end


function love.directorydropped( path ) --文件夹拖入
    room_select.directorydropped( path ) --文件夹拖入

end

function love.filedropped( file ) --文件拖入
    room_select.filedropped( file ) --文件拖入
end
-- 错误处理





local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    if type(save) == 'function' then pcall(function() save(chart,"chart.d3") end) end
    love.system.openURL(love.filesystem.getRealDirectory( "chart" ))
	msg = tostring(msg)
    if type(log) == 'function' then log("error:"..msg) end
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	local font = love.graphics.setNewFont(14)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, "Error\n")
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")
	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(89/255, 89/255, 89/255)
		love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
        p = p .. "\n\nDon‘t worry,your chart has been saved"
        p = p.. "\n\nPlease provide error feedback to the software developer as mush as possible"
        p = p.. "\n\nPress Ctrl+g go to github"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
            elseif e == "keypressed" and a == "g" and love.keyboard.isDown("lctrl", "rctrl") then --前往github
                if love.system then
				    love.system.openURL("https://github.com/qwwshs/daikumi_editor/")
                end
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

end
