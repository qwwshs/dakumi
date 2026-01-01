-- Copyright (C) 2010-2024 qwwshs

DAKUMI = {_VERSION = "0.5.0"}
beat = beat
time = {nowtime = 0 ,alltime = 1}
chart = {}
bg = nil
music = nil
music_play = false
mouse  = {x = 0,y = 0,down = false}--鼠标按下状态
elapsed_time = 0 -- 已运行时间
FONT = {normal = love.graphics.newFont("assets/fonts/LXGWNeoXiHei.ttf", 13),plus = love.graphics.newFont("assets/fonts/LXGWNeoXiHei.ttf", 26)}

iskeyboard = {} --key的按下状态
iskeyboard.alt = false --alt按下状态
iskeyboard.ctrl  = false --ctrl按下状态
iskeyboard.shift = false --shift按下状态

WINDOW = {w = 1600,h = 800,scale = 1,nowW = 1600,nowH = 800}
PATH = {
    i18n = 'i18n/',
    users = 'users/',
    usersPath = {
        settings = 'users/',
        hit = 'users/',
        chart = 'users/chart/',
        log = 'users/log/',
        export = 'users/export/',
        auto_save = 'users/auto_save/',
        ui = 'users/ui/',
    },
    key = '',
    editToolData = '',
    defaultBezier = '',
    base = love.filesystem.getSourceBaseDirectory( ), --保存路径
    web = {
        github = "https://github.com/qwwshs/daikumi/",
        dakumi = "https://dakumi.qwwshs.top"
    }
}


love.keyboard.setKeyRepeat(true) --键重复
love.graphics.setFont(FONT.normal)

require 'isRequire'

Nui = nuklear.newUI()
Nui:styleLoadColors({
    ['text'] = '#afafaf',
    ['window'] = '#2d2d2d',
    ['header'] = '#282828',
    ['border'] = '#414141',
    ['button'] = '#323232',
    ['button hover'] = '#282828',
    ['button active'] = '#232323',
    ['toggle'] = '#646464',
    ['toggle hover'] = '#787878',
    ['toggle cursor'] = '#2d2d2d',
    ['select'] = '#2d2d2d',
    ['select active'] = '#232323',
    ['slider'] = '#262626',
    ['slider cursor'] = '#646464',
    ['slider cursor hover'] = '#787878',
    ['slider cursor active'] = '#969696',
    ['property'] = '#262626',
    ['edit'] = '#262626',
    ['edit cursor'] = '#afafaf',
    ['combo'] = '#2d2d2d',
    ['chart'] = '#787878',
    ['chart color'] = '#2d2d2d',
    ['chart color highlight'] = '#ff0000',
    ['scrollbar'] = '#282828',
    ['scrollbar cursor'] = '#646464',
    ['scrollbar cursor hover'] = '#787878',
    ['scrollbar cursor active'] = '#969696',
    ['tab header'] = '#282828'
    })

--快捷键相关
key = loadstring(nativefs.read(PATH.key..'key.lua'))() or {}
for i,v in pairs(key) do
    input:new(i,v)
end

room:load("start")

function love.load()

    --文件夹创建与检查
    nativefs.mount(PATH.base)
    nativefs.createDirectory(PATH.users)
    for k,v in pairs(PATH.usersPath) do
        nativefs.createDirectory(v)
    end

    nativefs.unmount(PATH.base)
    room("load")
end
function love.update(dt)
    math.randomseed(elapsed_time) --随机数种子
    elapsed_time = elapsed_time + dt

    Nui:frameBegin()
    Nui:translate((WINDOW.nowW - WINDOW.w * WINDOW.scale)/2,(WINDOW.nowH - WINDOW.h * WINDOW.scale)/2)
    Nui:scale(WINDOW.scale,WINDOW.scale)
    Nui:styleSetFont(FONT.normal)

    if love.window.getFullscreen()  then  --全屏
        local w, h = love.graphics.getDesktopDimensions()   
        WINDOW.nowW = w
        WINDOW.nowH = h
        WINDOW.scale = math.min(w / WINDOW.w,h / WINDOW.h)
    end

    local original_x, original_y = love.mouse.getPosition( ) --对缩放进行处理
    mouse.x = original_x / WINDOW.scale - (WINDOW.nowW - WINDOW.w * WINDOW.scale)/2  
    mouse.y = original_y / WINDOW.scale - (WINDOW.nowH - WINDOW.h * WINDOW.scale)/2

    room("update",dt)

    Nui:frameEnd()
end
function love.draw()
    love.graphics.setScissor((WINDOW.nowW - WINDOW.w * WINDOW.scale)/2,(WINDOW.nowH - WINDOW.h * WINDOW.scale)/2,WINDOW.w * WINDOW.scale, WINDOW.h * WINDOW.scale)
    love.graphics.translate((WINDOW.nowW - WINDOW.w * WINDOW.scale)/2,(WINDOW.nowH - WINDOW.h * WINDOW.scale)/2)
    love.graphics.scale(WINDOW.scale,WINDOW.scale)

    room("draw")
    messageBox:draw()
    Nui:draw()

end

function love.keypressed(key, scancode, isrepeat)

    local t,r = pcall(function() Nui:keypressed(key, scancode, isrepeat) end )
    if r then
        return
    end

    if key == "lctrl" or key == "rctrl" then
        iskeyboard.ctrl = true
    end
    if key == "lalt" or key == "ralt" then
        iskeyboard.alt = true
    end
    if key == "lshift" or key == "rshift" then
        iskeyboard.shift = true
    end
    iskeyboard[key] = true
    if string.sub(key,1,2) == "kp" then
        key = string.sub(key,3,3)
    end

    room("keypressed",key, scancode, isrepeat)
end

function love.keyreleased(key,scancode)
    local t,r = pcall(function() Nui:keyreleased(key, scancode) end)
    if r then
        return
    end

    if key == "lctrl" or key == "rctrl" then
        iskeyboard.ctrl = false
    end 
    if key == "lalt" or key == "ralt" then
        iskeyboard.alt = false
    end
    if key == "lshift" or key == "rshift" then
        iskeyboard.shift = false
    end
    iskeyboard[key] = false

    room("keyreleased",key, scancode)
end

function love.wheelmoved(x, y)
    local t,r = pcall(function() Nui:wheelmoved(x, y) end)
    if r then
        return
    end

    room("wheelmoved",x, y)
end

function love.mousepressed( x, y, button, istouch, presses )
    local t,r = pcall(function() Nui:mousepressed(x, y, button, istouch, presses) end)
    if r then
        return
    end

    x = mouse.x  --对缩放进行处理
    y = mouse.y
    mouse.down = true
    room("mousepressed", x, y, button, istouch, presses )
end

function love.mousereleased( x, y, button, istouch, presses )
    local t,r = pcall(function() Nui:mousereleased(x, y, button, istouch, presses) end)
    if r then
        return
    end

    x = mouse.x  --对缩放进行处理
    y = mouse.y
    mouse.down = false
    
    room("mousereleased", x, y, button, istouch, presses )
end

function love.mousemoved(x, y, dx, dy, istouch)
    local t,r = pcall(function() Nui:mousemoved(x, y, dx, dy, istouch) end)
    if r then
        return
    end

    x = mouse.x  --对缩放进行处理
    y = mouse.y

    room("mousemoved",x, y, dx, dy, istouch)
end

function love.textinput(input)
    local t,r = pcall(function() Nui:textinput(input) end)
    if r then
        return
    end

    room("textinput",input)
end
function love.quit()
    room("quit")
end

function love.resize( w, h )
    WINDOW.nowW = w
    WINDOW.nowH = h
    WINDOW.scale = math.min(w / WINDOW.w,h / WINDOW.h)
    room("resize", w, h )
end


function love.directorydropped( path ) --文件夹拖入
    room("directorydropped", path )
end

function love.filedropped( file ) --文件拖入
    room("filedropped", file )
end

-- 错误处理

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    if type(save) == 'function' then pcall(function() save(chart,"chart.json") end) end
    love.system.openURL(love.filesystem.getRealDirectory( "chart" ))
	msg = tostring(msg)
    if type(log) == 'function' then log("error:"..msg) end
	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, WINDOW.h, 600)
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
