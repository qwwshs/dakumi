--[[
    模块名: isRequire
    描述: 集中加载所有依赖模块和源码模块
    作者: qwwshs

    加载顺序说明:
    1. 平台/语言内置模块 (utf8, socket, ffi)
    2. GUI 框架 (nuklear)
    3. 序列化/工具库 (serpent, yaml, timer, moonshine, cursor)
    4. 核心系统模块 (file, pass, room, window, meta)
    5. 业务逻辑模块 (beat, event, note, log, string, table, save)
    6. 数据处理库 (nativefs, dkjson, easings, bezier, math, track, input)
    7. UI 和对象模块 (messageBox, i18n, allImage, ui)
    8. 场景模块 (edit, menu, start)
    9. 插件系统 (plugin, services)
    10. 内置插件注册
]]

-- ============================================================
-- 第1层: 平台/语言内置模块
-- ============================================================
utf8 = require("utf8")        -- UTF-8 字符串处理（LuaJIT/LOVE2D 内置）
socket = require("socket")    -- 网络通信（LuaSocket）
ffi = require("ffi")          -- LuaJIT FFI，用于调用 C 语言库

-- ============================================================
-- 第2层: GUI 框架
-- ============================================================
nuklear = require 'nuklear'                        -- Nuklear 即时模式 GUI（通过 DLL 加载）

-- ============================================================
-- 第3层: 序列化/工具库（第三方库，不可修改）
-- ============================================================
serpent = require("src.utils.serpent")    -- Lua 表序列化库
yaml = require("src.utils.yaml")         -- YAML 解析库
timer = require("src.utils.timer")       -- 定时器库（基于 hump.timer）
moonshine = require("src.utils.moonshine") -- 后处理特效库
cursor = require 'src.utils.cursor'      -- 鼠标光标样式管理

-- ============================================================
-- 第4层: 核心系统模块
-- ============================================================
require('src.utils.file')    -- 文件工具函数（getFileExtension）
require('src.utils.pass')    -- 空函数占位符

require("src.utils.room")    -- 房间/场景管理系统（object, container, group, room）
require("src.utils.window")  -- 窗口坐标变换管理
require('src/objects/meta')  -- 元数据定义（meta_chart, meta_event, meta_note, meta_bpm, meta_track 等）

-- ============================================================
-- 第5层: 业务逻辑模块
-- ============================================================
require("src.utils.beat")    -- 节拍/时间计算模块
fEvent = require("src.utils.event")  -- 事件处理模块
fNote = require("src.utils.note")    -- 音符处理模块

require("src.utils.log")     -- 日志系统
require("src.utils.string")  -- 字符串工具函数
require("src.utils.table")   -- 表工具函数（eq, copy, find, fill）
require("src.utils.save")    -- 谱面保存功能

-- ============================================================
-- 第6层: 数据处理库
-- ============================================================
nativefs = require("src.utils.nativefs")  -- 原生文件系统（绕过 LOVE2D 沙箱）
dkjson = require("src.utils.dkjson")      -- JSON 解析/序列化库
easings = require('src.utils.easings')    -- 缓动函数库

require("src.utils.bezier")  -- 贝塞尔曲线计算
require("src.utils.math")    -- 数学工具函数（分数运算、区间判断等）

fTrack = require("src.utils.track")  -- 轨道管理模块
input = require("src.utils.input")   -- 快捷键输入管理

-- ============================================================
-- 第7层: UI 和对象模块
-- ============================================================
require('src.objects.messageBox')  -- 消息提示框组件
require('src/objects.i18n')        -- 国际化模块
require('src.objects.allImage')    -- 图片资源加载
ui = require("src.objects.ui")     -- UI 工具函数封装

-- ============================================================
-- 第8层: 场景模块
-- ============================================================
require("src.rooms.edit")   -- 编辑场景（包含 play, sidebar, editTool, demo 子场景）
require("src.rooms.menu")   -- 菜单场景
require("src.rooms.start")  -- 启动场景

-- ============================================================
-- 第9层: 插件系统（在 main.lua 中初始化）
-- ============================================================
-- PluginManager 和服务层在 main.lua 中加载和初始化
-- 插件统一在 love.load 中由 plugins/init.lua 自动发现、注册并按层挂载
