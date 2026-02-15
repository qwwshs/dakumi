-- Copyright (C) 2010-2024 qwwshs

DAKUMI           = { _VERSION = "0.5.0b3" }
beat             = beat
time             = { nowtime = 0, alltime = 1 }
chart            = {}
bg               = nil
music            = nil
music_play       = false
mouse            = { x = 0, y = 0, down = false } --鼠标按下状态
elapsed_time     = 0                -- 已运行时间
FONT             = { normal = love.graphics.newFont("assets/fonts/LXGWNeoXiHei.ttf", 13), plus = love.graphics.newFont(
"assets/fonts/LXGWNeoXiHei.ttf", 26) }

iskeyboard       = {}                                                           --key的按下状态
iskeyboard.alt   = false                                                        --alt按下状态
iskeyboard.ctrl  = false                                                        --ctrl按下状态
iskeyboard.shift = false                                                        --shift按下状态

WINDOW           = { w = 1600, h = 900, scale = 1, nowW = 1600, nowH = 900, fullscreen = false } --窗口信息
PATH             = {
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
        key = 'users/',
    },
    editToolData = '',
    defaultBezier = '',
    base = love.filesystem.getSourceBaseDirectory(),  --保存路径
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
    ['text'] = '#F0F0F0',                    -- 亮灰色文字，更接近ImGui默认
    ['window'] = '#181818',                  -- 更深的窗口背景
    ['header'] = '#202020',                  -- 头部背景
    ['border'] = '#404040',                  -- 边框颜色
    ['button'] = '#2D2D2D',                  -- 按钮默认
    ['button hover'] = '#3D3D3D',            -- 按钮悬停
    ['button active'] = '#1E6F9F',           -- ImGui风格的蓝色激活状态
    ['toggle'] = '#2D2D2D',                  -- 切换框背景
    ['toggle hover'] = '#3D3D3D',            -- 切换框悬停
    ['toggle cursor'] = '#1E6F9F',           -- 切换框光标（蓝色）
    ['select'] = '#2d2d2d',                  -- 选择框背景
    ['select hover'] = '#3D3D3D',            -- 选择框悬停
    ['select active'] = '#232323',
    ['slider'] = '#2D2D2D',                  -- 滑块背景
    ['slider cursor'] = '#1E6F9F',           -- 滑块光标（蓝色）
    ['slider cursor hover'] = '#2596D1',     -- 滑块光标悬停（亮蓝色）
    ['slider cursor active'] = '#1A5A7A',    -- 滑块光标激活（深蓝色）
    ['property'] = '#202020',                -- 属性区域
    ['edit'] = '#2D2D2D',                    -- 编辑框
    ['edit cursor'] = '#F0F0F0',             -- 编辑框光标
    ['combo'] = '#2D2D2D',                   -- 组合框
    ['chart'] = '#3D3D3D',                   -- 图表背景
    ['chart color'] = '#1E6F9F',             -- 图表颜色（蓝色）
    ['chart color highlight'] = '#FF5555',   -- 图表高亮（红色）
    ['scrollbar'] = '#202020',               -- 滚动条背景
    ['scrollbar cursor'] = '#404040',        -- 滚动条光标
    ['scrollbar cursor hover'] = '#505050',  -- 滚动条光标悬停
    ['scrollbar cursor active'] = '#1E6F9F', -- 滚动条光标激活（蓝色）
    ['tab header'] = '#202020'               -- 标签页头部
})


room:load("start")

function love.load()
    --文件夹创建与检查
    nativefs.mount(PATH.base)
    nativefs.createDirectory(PATH.users)
    for k, v in pairs(PATH.usersPath) do
        nativefs.createDirectory(v)
    end

    nativefs.unmount(PATH.base)

    --快捷键相关
    nativefs.mount(PATH.base)

    local key_file = nativefs.read(PATH.usersPath.key .. 'key.json') or ''
    local key
    pcall(function() key = dkjson.decode(key_file) or meta_key.__index end)
    if type(key) ~= 'table' then
        key = meta_key.__index
    end
    table.fill(key, meta_key.__index)
    save(dkjson.encode(key, { indent = true }), PATH.usersPath.key .. 'key.json')
    for i, v in pairs(key) do
        input:new(i, v)
    end
    nativefs.unmount(PATH.base)

    room("load")
end

function love.update(dt)
    math.randomseed(elapsed_time) --随机数种子
    elapsed_time = elapsed_time + dt

    if love.window.getFullscreen() and not WINDOW.fullscreen then --全屏
        local w, h = love.graphics.getDesktopDimensions()
        WINDOW.nowW = w
        WINDOW.nowH = h
        WINDOW.scale = math.min(w / WINDOW.w, h / WINDOW.h)
        WINDOW.fullscreen = true
        love.resize(w, h)
    elseif not love.window.getFullscreen() and WINDOW.fullscreen then
        WINDOW.fullscreen = false
        WINDOW.nowW = WINDOW.w
        WINDOW.nowH = WINDOW.h
        WINDOW.scale = 1
        love.resize(WINDOW.w, WINDOW.h)
    end


    Nui:translate((WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2, (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2)
    Nui:scale(WINDOW.scale, WINDOW.scale)
    Nui:styleSetFont(FONT.normal)

    local original_x, original_y = love.mouse.getPosition()  --对缩放进行处理
    mouse.x = original_x / WINDOW.scale - (WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2
    mouse.y = original_y / WINDOW.scale - (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2

    room("update", dt)
end

function love.draw()
    room("draw")
    messageBox:draw()
    Nui:draw()
end

function love.keypressed(key, scancode, isrepeat)
    local t, r = pcall(function() Nui:keypressed(key, scancode, isrepeat) end)
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
    if string.sub(key, 1, 2) == "kp" then
        key = string.sub(key, 3, 3)
    end

    room("keypressed", key, scancode, isrepeat)
end

function love.keyreleased(key, scancode)
    local t, r = pcall(function() Nui:keyreleased(key, scancode) end)
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

    room("keyreleased", key, scancode)
end

function love.wheelmoved(x, y)
    local t, r = pcall(function() Nui:wheelmoved(x, y) end)
    if r then
        return
    end

    room("wheelmoved", x, y)
end

function love.mousepressed(x, y, button, istouch, presses)
    local t, r = pcall(function() Nui:mousepressed(x, y, button, istouch, presses) end)
    if r then
        return
    end

    x = mouse.x --对缩放进行处理
    y = mouse.y
    mouse.down = true
    room("mousepressed", x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    local t, r = pcall(function() Nui:mousereleased(x, y, button, istouch, presses) end)
    if r then
        return
    end

    x = mouse.x --对缩放进行处理
    y = mouse.y
    mouse.down = false

    room("mousereleased", x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    local t, r = pcall(function() Nui:mousemoved(x, y, dx, dy, istouch) end)
    if r then
        return
    end

    x = mouse.x --对缩放进行处理
    y = mouse.y

    room("mousemoved", x, y, dx, dy, istouch)
end

function love.textinput(input)
    local t, r = pcall(function() Nui:textinput(input) end)
    if r then
        return
    end

    room("textinput", input)
end

function love.quit()
    room("quit")
end

function love.resize(w, h)
    WINDOW.nowW = w
    WINDOW.nowH = h
    WINDOW.scale = math.min(w / WINDOW.w, h / WINDOW.h)
    room("resize", w, h)
    love.graphics.origin()
    love.graphics.setScissor((WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2, (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2,
        WINDOW.w * WINDOW.scale, WINDOW.h * WINDOW.scale)
    love.graphics.translate((WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2, (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2)
    love.graphics.scale(WINDOW.scale, WINDOW.scale)
end

function love.directorydropped(path)   --文件夹拖入
    room("directorydropped", path)
end

function love.filedropped(file)   --文件拖入
    room("filedropped", file)
end

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a, b, c, d, e, f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a, b, c, d, e, f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then dt = love.timer.step() end

        -- Call update and draw
        Nui:frameBegin()
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
        Nui:frameEnd()

        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end

            love.graphics.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end

-- 错误处理

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    if type(save) == 'function' then pcall(function() save(chart, "chart.json") end) end
    love.system.openURL(love.filesystem.getRealDirectory("chart"))
    msg = tostring(msg)
    if type(log) == 'function' then log("error:" .. msg) end
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
        for i, v in ipairs(love.joystick.getJoysticks()) do
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
        love.graphics.clear(89 / 255, 89 / 255, 89 / 255)
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
        p = p .. "\n\nPlease provide error feedback to the software developer as mush as possible"
        p = p .. "\n\nPress Ctrl+g go to github"
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
                local buttons = { "OK", "Cancel" }
                if love.system then
                    buttons[3] = "Copy to clipboard"
                end
                local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", buttons)
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
