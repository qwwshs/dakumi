--[[
    模块名: main
    描述: dakumi editor 主入口文件，定义全局变量、UI 初始化、事件循环、错误处理
    作者: qwwshs
    版本: 0.5.0c
    框架: LOVE2D 11.4

    全局变量说明:
    - DAKUMI: 版本信息
    - time/beat: 时间和节拍状态
    - music/music_data/music_play: 音频状态
    - mouse/iskeyboard: 输入状态
    - WINDOW: 窗口尺寸和缩放信息
    - PATH: 资源和用户数据路径配置
    - FONT: 字体资源
    - bg: 当前背景图片
    - Nui: Nuklear UI 实例
]]

DAKUMI           = { _VERSION = "0.5.0c" }      -- 版本信息
beat             = beat                         -- 节拍计算模块（在 isRequire.lua 中初始化）
time             = { nowtime = 0, alltime = 1 } -- 时间状态：当前时间、总时长
-- chart/extra_chart 已由 ChartService 私有持有，不再定义全局变量
bg               = nil                          -- 当前背景图片
music            = nil                          -- 当前音频源
music_data       = nil                          -- 音频波形数据
music_play       = false                        -- 音乐是否正在播放

--- 鼠标状态
mouse            = { x = 0, y = 0, down = false, cursor = '' }
elapsed_time     = 0 -- 应用已运行时间（秒）

--- 字体资源
FONT             = {
    normal = love.graphics.newFont("assets/fonts/LXGWNeoXiHei.ttf", 13), -- 普通字体
    plus = love.graphics.newFont("assets/fonts/LXGWNeoXiHei.ttf", 26),   -- 大号字体
}

--- 键盘按下状态
iskeyboard       = {}
iskeyboard.alt   = false -- Alt 键是否按下
iskeyboard.ctrl  = false -- Ctrl 键是否按下
iskeyboard.shift = false -- Shift 键是否按下

--- 窗口信息
-- w/h: 设计分辨率, scale: 缩放比例, nowW/nowH: 实际窗口尺寸, fullscreen: 是否全屏
WINDOW           = { w = 1600, h = 900, scale = 1, nowW = 1600, nowH = 900, fullscreen = false }

--- 路径配置
PATH             = {
    i18n = 'i18n/',                                    -- 国际化文件目录
    users = 'users/',                                  -- 用户数据根目录
    usersPath = {
        settings = 'users/',                           -- 设置文件
        hit = 'users/',                                -- 打击音效
        chart = 'users/chart/',                        -- 谱面文件
        log = 'users/log/',                            -- 日志文件
        export = 'users/export/',                      -- 导出文件
        auto_save = 'users/auto_save/',                -- 自动保存
        ui = 'users/ui/',                              -- UI 配置
        key = 'users/',                                -- 快捷键配置
    },
    plugins = 'plugins/',                              -- 插件目录（外部可访问）
    defaultBezier = '',                                -- 默认贝塞尔曲线文件路径（运行时设置）
    base = love.filesystem.getSourceBaseDirectory(),   -- 应用基础目录
    web = {
        github = "https://github.com/qwwshs/daikumi/", -- GitHub 仓库
        dakumi = "https://dakumi.qwwshs.top"           -- 官方网站
    }
}

-- 将插件目录添加到 Lua 搜索路径
package.path     = PATH.plugins .. "?.lua;" .. PATH.plugins .. "?/init.lua;" .. package.path

love.keyboard.setKeyRepeat(true) -- 启用键重复（长按时连续触发）
love.graphics.setFont(FONT.normal)
FONT.normal:setFilter("linear", "nearest")
FONT.plus:setFilter("linear", "nearest")

-- 加载所有模块和依赖
local app = require 'isRequire'
local room, input, eventBus = app.root, app.input, app.eventBus

-- 初始化插件管理器和服务层
PluginManager = require("src.utils.plugin")
local ChartService = require("src.services.chartService")
local KeyCapture = require('src.services.keyCapture')
local BpmMeasureService = require('src.services.bpmMeasureService')
local CoordinateService = require("src.services.coordinateService")
local AudioService = require("src.services.audioService")
local ThemeService = require("src.services.themeService")
ThemeService:load(PATH.usersPath.ui .. 'theme.yml')

--- 插件上下文：提供给插件的服务访问接口
PluginManager:init({
    root = room,              -- 根场景，可按路径定位任意 room/group
    input = input,            -- 快捷键查询
    chart = ChartService,      -- 谱面数据服务
    eventBus = eventBus,       -- 谱面变更等全局事件
    coord = CoordinateService, -- 坐标转换服务
    audio = AudioService,      -- 音频服务
    beat = beat,               -- 节拍计算模块
    settings = settings,       -- 用户设置（场景模块已完成加载）
    i18n = i18n,               -- 国际化
    WINDOW = WINDOW,           -- 窗口信息
    PATH = PATH,               -- 路径配置
})

Nui = nuklear.newUI()
local uiThemeColors = {
  dark = {
    ['text'] = '#FFFFFF',                    -- 亮灰色文字
    ['window'] = '#000000',                  -- 更深的窗口背景
    ['header'] = '#202020',                  -- 头部背景
    ['border'] = '#000000',                  -- 边框颜色
    ['button'] = '#000000',                  -- 按钮默认
    ['button hover'] = '#3D3D3D',            -- 按钮悬停
    ['button active'] = '#7C7D80',           -- ImGui风格的蓝色激活状态
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
  },
  light = {
    ['text'] = '#25282C', ['window'] = '#F1F2F4', ['header'] = '#D9DDE2',
    ['border'] = '#B8BEC6', ['button'] = '#E4E7EB', ['button hover'] = '#D1D7DE',
    ['button active'] = '#B7C6D8', ['toggle'] = '#D9DDE2', ['toggle hover'] = '#CBD2DA',
    ['toggle cursor'] = '#4387C5', ['select'] = '#E4E7EB', ['select hover'] = '#D1D7DE',
    ['select active'] = '#C7D2DF', ['slider'] = '#D9DDE2', ['slider cursor'] = '#4387C5',
    ['slider cursor hover'] = '#3478B6', ['slider cursor active'] = '#28649A',
    ['property'] = '#E4E7EB', ['edit'] = '#FFFFFF', ['edit cursor'] = '#25282C',
    ['combo'] = '#FFFFFF', ['chart'] = '#E4E7EB', ['chart color'] = '#4387C5',
    ['chart color highlight'] = '#D94A4A', ['scrollbar'] = '#D9DDE2',
    ['scrollbar cursor'] = '#AEB6C0', ['scrollbar cursor hover'] = '#929DAA',
    ['scrollbar cursor active'] = '#4387C5', ['tab header'] = '#D9DDE2'
  }
}

function setUiTheme(theme)
    theme = theme == 'light' and 'light' or 'dark'
    settings.theme = theme
    Nui:styleLoadColors(ThemeService:nuklearColors(theme, uiThemeColors[theme]))
    if isImage and isImage.setTheme then isImage:setTheme(theme) end
    for _, name in ipairs({'play', 'demo', 'menu', 'editTool'}) do
        local ok, colors = pcall(require, 'config.colors.' .. name)
        if ok then
            ThemeService:restoreColors(colors, name)
            if colors.setTheme then colors.setTheme(theme) end
            ThemeService:overrideColorTable(colors, name == 'editTool' and 'edit_tool' or name, theme)
        end
    end
    local background = ThemeService:backgroundColor(theme)
    if background then
        love.graphics.setBackgroundColor(unpack(background))
    elseif theme == 'light' then
        love.graphics.setBackgroundColor(0.93, 0.94, 0.96, 1)
    else
        love.graphics.setBackgroundColor(0, 0, 0, 1)
    end
end

setUiTheme(settings.theme)

Nui:stylePush {
    ['window'] = { ['rounding'] = 0 },
    ['button'] = {
        ['rounding'] = 0,
        ['text alignment'] = 'centered',     -- 文字居中
        -- 纯图片按钮由 ui:imageButton 按原始比例绘制；此项仅作用于 Nuklear 内置图片按钮。
        ['image padding'] = { x = 0, y = 0 }
    },
    ['contextual button'] = { ['rounding'] = 0 },
    ['menu button'] = { ['rounding'] = 0 },
    ['selectable'] = { ['rounding'] = 0 },
    ['slider'] = { ['rounding'] = 0,},
    ['progress'] = {
        ['rounding'] = 0,
        ['cursor rounding'] = 0,
    },
    ['property'] = {
        ['rounding'] = 0,
        ['edit'] = {
            ['rounding'] = 0,
            ['scrollbar'] = {
                ['rounding'] = 0,
                ['rounding cursor'] = 0
            }
        }
    },
    ['edit'] = {
        ['rounding'] = 0,
        ['scrollbar'] = {
            ['rounding'] = 0,
            ['rounding cursor'] = 0
        }
    },
    ['chart'] = { ['rounding'] = 0 },
    ['scrollh'] = {
        ['rounding'] = 0,
        ['rounding cursor'] = 0
    },
    ['scrollv'] = {
        ['rounding'] = 0,
        ['rounding cursor'] = 0
    },
    ['tab'] = {
        ['rounding'] = 0,
        ['tab maximize button'] = { ['rounding'] = 0 },
        ['tab minimize button'] = { ['rounding'] = 0 },
        ['node maximize button'] = { ['rounding'] = 0 },
        ['node minimize button'] = { ['rounding'] = 0 }
    },
    ['combo'] = {
        ['rounding'] = 0,
        ['button'] = { ['rounding'] = 0 }
    }
}
room:load("start")

function love.load(arg)
    math.randomseed(os.time()) --随机数种子
    setUiTheme(settings.theme)

    --文件夹创建与检查
    nativefs.mount(PATH.base)
    nativefs.createDirectory(PATH.users)
    for k, v in pairs(PATH.usersPath) do
        nativefs.createDirectory(v)
    end

    nativefs.unmount(PATH.base)

    -- 插件目录统一负责发现和注册；此时日志目录、场景和 Nui 均已就绪。
    PluginManager.ctx.ui = Nui
    PluginManager.loadResult = require('plugins.init')(PluginManager)
    room("load")
end

function love.update(dt)
    mouse.cursor = ''
    cursor:pop()
    timer.update(dt)
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

    ui:transOrgin()
    Nui:styleSetFont(FONT.normal)
    local original_x, original_y = love.mouse.getPosition() --对缩放进行处理
    mouse.x, mouse.y = CoordinateService:screenToGame(original_x, original_y)

    BpmMeasureService:update()
    room("update", dt)

    if mouse.cursor ~= '' then
        cursor:set(mouse.cursor)
    end
end

function love.draw()
    room("draw")
    messageBox:draw()
    Nui:draw()
end

-- 原生输入统一经过路由，主入口不再判断具体编辑控件。
local InputRouter = require('src.services.inputRouter')
local inputRouter = InputRouter.new({ui = Nui, root = app.root, capture = KeyCapture,
    keyboard = app.keyboard, uiKeyboard = app.uiKeyboard, mouse = app.mouse, window = app.window, report = log})
for _, method in ipairs({'keypressed', 'keyreleased', 'wheelmoved', 'mousepressed',
    'mousereleased', 'mousemoved', 'textinput', 'focus'}) do
    local event = method
    love[event] = function(...) return inputRouter:dispatch(event, ...) end
end

function love.quit()
    room("quit")
end

function love.resize(w, h)
    WINDOW.nowW = w
    WINDOW.nowH = h
    WINDOW.scale = math.min(w / WINDOW.w, h / WINDOW.h)
    room("resize", w, h)
end

function love.directorydropped(path) --文件夹拖入
    room("directorydropped", path)
end

function love.filedropped(file) --文件拖入
    room("filedropped", file)
end

function love.run()
    love.load(love.arg.parseGameArguments(arg), arg)

    -- We don't want the first frame's dt to include time taken by love.load.
    love.timer.step()

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        love.event.pump()
        for name, a, b, c, d, e, f in love.event.poll() do
            if name == "quit" then
                if not love.quit or not love.quit() then
                    return a or 0
                end
            end
            love.handlers[name](a, b, c, d, e, f)
        end

        -- Update dt, as we'll be passing it to update
        dt = love.timer.step()

        -- Call update and draw
        Nui:frameBegin()
        love.update(dt) -- will pass 0 if love.timer is disabled
        Nui:frameEnd()
        if love.graphics.isActive() then
            -- A scissor and transform persist across frames in this custom
            -- run loop. Reset them before clearing, otherwise the letterbox
            -- area retains old frames and visibly flickers while resizing.
            love.graphics.origin()
            love.graphics.setScissor()
            love.graphics.clear(love.graphics.getBackgroundColor())

            local viewportX = (WINDOW.nowW - WINDOW.w * WINDOW.scale) / 2
            local viewportY = (WINDOW.nowH - WINDOW.h * WINDOW.scale) / 2
            love.graphics.setScissor(viewportX, viewportY, WINDOW.w * WINDOW.scale, WINDOW.h * WINDOW.scale)
            love.graphics.translate(viewportX, viewportY)
            love.graphics.scale(WINDOW.scale, WINDOW.scale)
            love.draw()

            love.graphics.origin()
            love.graphics.setScissor()
            love.graphics.present()
        end
        love.timer.sleep(1 / 120) --避免100%占用CPU
    end
end

-- 错误处理

local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1 + (layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
    if type(ChartService) == 'table' then pcall(function() ChartService:save("chart.json") end) end
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
                    love.system.openURL(PATH.web.github)
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
