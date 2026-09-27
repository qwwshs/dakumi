# Daikumi Editor 开发者文档

## 目录

1. [项目架构](#项目架构)
2. [模块加载顺序](#模块加载顺序)
3. [核心数据结构](#核心数据结构)
4. [服务层 API](#服务层-api)
5. [插件开发指南](#插件开发指南)
6. [场景系统](#场景系统)
7. [色彩系统](#色彩系统)
8. [快捷键系统](#快捷键系统)
9. [目录结构](#目录结构)

---

## 项目架构

### 整体分层

```
┌─────────────────────────────────────────────────┐
│                   插件层 (Plugins)                │
│   equalizer / to_takana / fft / hit / directEventEditing  │
├─────────────────────────────────────────────────┤
│                  服务层 (Services)                │
│      ChartService / CoordinateService / AudioService      │
├─────────────────────────────────────────────────┤
│                 业务逻辑层 (Objects)              │
│     meta / redo / event / note / track / ctrl    │
├─────────────────────────────────────────────────┤
│                 场景层 (Rooms)                    │
│        play / menu / editTool / demo / sidebar   │
├─────────────────────────────────────────────────┤
│                 基础设施层 (Utils)                │
│    room / beat / table / input / plugin / window │
├─────────────────────────────────────────────────┤
│                 第三方库 (不可修改)                │
│   nuklear / moonshine / dkjson / serpent  │
│   nativefs / lua-yaml / luafft / lovefft / easings │
└─────────────────────────────────────────────────┘
```

### 四层对象架构

编辑器使用自定义的四层对象系统（定义在 `src/utils/room.lua`）：

| 层级 | 名称 | 说明 |
|------|------|------|
| 1 | `object` | 基础对象，所有实体的基类 |
| 2 | `container` | 容器，可包含子对象（objects）和子组（groups） |
| 3 | `group` | 容器变体，用于组合多个对象，不支持嵌套房间 |
| 4 | `room` | 场景管理器，支持多场景切换和生命周期调度 |

**生命周期方法**（由 room 调度）：

```lua
load              -- 加载
update(dt)        -- 每帧更新
draw              -- 绘制
keypressed(key)   -- 键盘按下
keyreleased(key)  -- 键盘释放
mousepressed(x, y, button, istouch, presses)  -- 鼠标按下
mousereleased(x, y, button, istouch, presses)  -- 鼠标释放
wheelmoved(x, y)  -- 鼠标滚轮
textinput(text)   -- 文本输入
resize(w, h)      -- 窗口大小变化
quit              -- 退出
```

---

## 模块加载顺序

模块通过 `isRequire.lua` 按层级加载，避免循环依赖：

```
第1层: 平台/语言内置模块     (utf8, socket, ffi)
第2层: GUI 框架              (nuklear)
第3层: 序列化/工具库          (serpent, yaml, timer, moonshine, cursor)
第4层: 核心系统模块           (file, pass, room, window, meta)
第5层: 业务逻辑模块           (beat, event, note, log, string, table, save)
第6层: 数据处理库             (nativefs, dkjson, easings, bezier, math, track, input)
第7层: UI 和对象模块          (messageBox, i18n, allImage, ui)
第8层: 场景模块               (edit, menu, start)
第9层: 插件管理器             (在 main.lua 中初始化)
运行期: 插件自动发现/注册      (love.load → plugins/init.lua，按 target/layer 挂载)
```

**关键约束**：
- 下层模块不可引用上层模块
- 同层模块尽量避免相互引用

---

## 核心数据结构

### Beat 格式

```lua
{整数, 分子, 分母}
-- 例如: {2, 1, 4} 表示 2又1/4拍 = 2.25
```

通过 `beat:get({2, 1, 4})` 转换为数值 `2.25`。

### 谱面数据 (chart)

`chart` 已不是全局变量，而是 ChartService 的私有状态。以下是其内部数据结构（理解数据格式用，
代码中必须通过 ChartService 的接口访问）：

```lua
chart = {
    bpm_list = {                    -- BPM 列表
        { beat = {0, 0, 1}, bpm = 120, linear_ramp = 0 },
        -- linear_ramp: 0=突变, 1=线性渐变
    },
    note = {                        -- 音符列表
        {
            type = "note",          -- "note" | "hold" | "wipe"
            track = 1,              -- 轨道编号
            beat = {1, 0, 1},       -- 位置
            beat2 = {2, 0, 1},      -- hold 结束位置（仅 hold）
            fake = 0,               -- 0=正常, 1=假音符
            note_head = 0,          -- hold 头部类型
            wipe_head = 0,          -- 是否为 wipe 头
        },
    },
    event = {                       -- 事件列表
        {
            type = "x",             -- "x" | "w" | "lpos" | "rpos"
            track = 1,              -- 轨道编号
            beat = {0, 0, 1},       -- 起始位置
            beat2 = {4, 0, 1},      -- 结束位置
            from = 0,               -- 起始值
            to = 1,                 -- 结束值
            trans = {               -- 过渡方式
                type = "bezier",    -- "bezier" | "easings"
                trans = {0.5, 0},   -- 贝塞尔控制点 或 缓动索引
                easings = 1,
            },
        },
    },
    effect = {},                    -- 效果列表
    track = {},                     -- 轨道定义（键为字符串 "1", "2", ...）
    offset = 0,                     -- 音频偏移量（毫秒）
    info = {                        -- 谱面信息
        song_name = "",
        chart_name = "",
        chartor = "",
        artist = "",
    },
    preference = {                  -- 偏好设置
        x_offset = 0,
        event_scale = 1,
    },
}
```

### extra_chart 索引数据

`extra_chart` 是 `chart` 的按轨道分类索引，是 ChartService 的私有状态（**不存在全局变量**）。
外部只能通过 `hasTrack` / `getTrackEventCount` / `getTrackEvent` 查询，无法拿到索引内部表。

```lua
extra_chart = {
    track = {
        [1] = {                     -- 轨道 1
            x = { ... },            -- x 类型事件列表
            w = { ... },            -- w 类型事件列表
            lpos = { ... },         -- lpos 类型事件列表
            rpos = { ... },         -- rpos 类型事件列表
            note = { ... },         -- 音符列表
        },
        [2] = { ... },              -- 轨道 2
    }
}
```

模板定义在 `meta_extra_chart_track`（`src/objects/meta.lua`）。

---

## 服务层 API

### ChartService (`src/services/chartService.lua`)

`chart` 与 `extra_chart` 是 ChartService 的**私有状态**（module-local），不再是全局变量。
**不提供任何返回内部表引用的接口**：读取走 计数+下标+字段访问器（Note/Event 对象按实体返回，
其字段修改走对象方法）；所有写入必须通过本服务的方法。修改 chart 时自动同步 extra_chart 索引。

#### 谱面替换与生命周期

```lua
ChartService:setChart(data)       -- 替换整张谱面（深拷贝 + 补默认字段，菜单选谱/导入用）
ChartService:update()             -- 版本迁移和字段填充
ChartService:load()               -- 加载谱面（构建 extra_chart 索引）
ChartService:save(name)           -- 序列化保存（"chart.json" / "chart.json.auto" / 其它路径）
ChartService:encodeJson()         -- 编码为 JSON 字符串（旧格式导入重写文件用）
```

#### 列表读取（计数 + 下标，不返回内部表）

```lua
ChartService:getNoteCount() / getNote(i)      -- 音符数量 / 第 i 个 Note 对象
ChartService:getEventCount() / getEvent(i)    -- 事件数量 / 第 i 个 Event 对象
ChartService:getBpmCount()  / getBpm(i)       -- BPM 数量 / 第 i 个 BPM 条目
ChartService:getEffectCount() / getEffect(i)  -- 效果数量 / 第 i 个效果条目
```

#### 索引查询（extra_chart，只读）

```lua
ChartService:hasTrack(trackId)                           -- 轨道是否存在于索引
ChartService:getTrackEventCount(trackId, eventType)      -- 指定轨道指定类型的事件数
ChartService:getTrackEvent(trackId, eventType, i)        -- 第 i 个事件对象
```

#### 标量字段与轨道定义

```lua
ChartService:getOffset() / setOffset(v)                  -- 音频偏移量（毫秒）
ChartService:getInfoField(f) / setInfoField(f, v)        -- song_name / chart_name / chartor / artist
ChartService:getPreferenceField(f) / setPreferenceField(f, v)  -- x_offset / event_scale
ChartService:setBpmList(list)                            -- 整体替换 BPM 列表（chart_info 保存用）
ChartService:ensureTrack(trackId)                        -- 懒创建轨道定义
ChartService:getTrackField(trackId, f) / setTrackField(trackId, f, v)  -- name/w0thenShow/type/parent/scale_with_parent
```

#### beat 桥接（内部使用 chart.bpm_list）

```lua
ChartService:toBeat(t)            -- 时间(秒) → beat 值
ChartService:toTime(b)            -- beat 值 → 时间(秒)
```

#### 数据写入（自动同步 extra_chart）

```lua
ChartService:add(noteOrEvent)     -- 添加 note/event（含批量缓冲、撤销记录、排序、插件钩子）
ChartService:delete(noteOrEvent)  -- 删除 note/event
ChartService:push() / pop()       -- 批量操作（push 与 pop 之间的增删被缓冲，pop 统一提交）
ChartService:addNote(note) / deleteNote(note)   -- 直接增删音符（内部用）
ChartService:addEvent(event) / deleteEvent(event)
ChartService:sortEvents() / sortNotes() / sortBpmList()  -- 排序（同步 chart 与 extra_chart）
```

### CoordinateService (`src/services/coordinateService.lua`)

封装坐标转换。

```lua
-- beat ↔ 屏幕坐标
CoordinateService:beatToScreenY(isbeat)    -- beat → 屏幕 Y
CoordinateService:screenYToBeat(y)         -- 屏幕 Y → beat
CoordinateService:beatToNumber(beatTable)  -- beat 表 → 数值
CoordinateService:addBeat(b1, b2)          -- beat 相加
CoordinateService:subBeat(b1, b2)          -- beat 相减
CoordinateService:snapToBeat(isbeat)       -- 对齐到最近 beat

-- 时间 ↔ beat
CoordinateService:timeToBeat(bpmList, time)
CoordinateService:beatToTime(bpmList, isbeat)

-- 轨道 ↔ 屏幕
CoordinateService:trackToScreen(x, w)      -- 谱面坐标 → 屏幕坐标
CoordinateService:trackToScreenX(x)        -- 谱面 x → 屏幕 x
CoordinateService:screenToTrackX(x)        -- 屏幕 x → 谱面 x
CoordinateService:getAllTrackPos()         -- 所有轨道位置
CoordinateService:getAllTrackIds()         -- 所有轨道 ID
CoordinateService:getNearFence()           -- 最近栅栏
```

### AudioService (`src/services/audioService.lua`)

封装音频状态访问。

```lua
AudioService:getSource()          -- 获取音频源
AudioService:setSource(source)    -- 设置音频源
AudioService:getSoundData()       -- 获取波形数据
AudioService:isPlaying()          -- 是否正在播放
AudioService:setPlaying(playing)  -- 设置播放状态
AudioService:getCurrentTime()     -- 当前时间（秒）
AudioService:setCurrentTime(t)    -- 设置当前时间
AudioService:getDuration()        -- 总时长
AudioService:getCurrentBeat()     -- 当前 beat
AudioService:setCurrentBeat(b)    -- 设置当前 beat
AudioService:getAllBeat()         -- 总 beat 数
AudioService:pause()              -- 暂停
AudioService:resume()             -- 恢复
AudioService:stop()               -- 停止
```

---

## 插件开发指南

完整文档位于 [plugins/README.md](plugins/README.md)。

插件入口支持 `plugins/name.lua` 和 `plugins/name/init.lua`。每个入口返回描述表，自动加载器在场景、服务和 Nui 初始化后统一注册，无需修改游戏内文件。以下划线开头的文件/目录不加载。

```lua
return {
    name = 'example',
    target = 'edit/play',
    layer = 85,
    update = function(ctx, dt)
        -- ctx.chart / ctx.coord / ctx.audio / ctx.settings / ctx.ui
    end,
}
```

目标可以是任意嵌套 room/group 路径或对象引用；省略目标时挂载根容器。层从小到大执行，默认最高层，同层按导入顺序执行。描述表回调的第一个参数为 `ctx`；`object` 模式保留对象的 `self`。

管理器提供 `register`、`unregister`、`getPluginNames`、`getPlugin`、`setLayer`、`on`、`emit`。正常的更新、绘制和输入已经由目标容器调用，不能再使用 `callAll` 重复广播这些生命周期。

内置插件：fft（menu/30）、redo（edit/play/90）、alt（100）、ctrl（110）、directEventEditing（130）。它们的注册信息均在各自插件文件中。

普通谱面增删钩子仍仅覆盖 `ChartService:add/delete`；批量操作、撤销重做和直接字段修改不触发，详细限制见完整文档。

---

## 场景系统

### 容器分层

`addObject(obj, layer)`、`addGroup(group, layer)`、`addRoom(room, layer)` 把子内容加入指定层。所有类型统一排序，非活动 room 不执行。省略层号时使用 `container.TOP_LAYER`（`math.huge`），同层按导入顺序执行。

每个容器拥有独立的 `layers` 表；用 `getLayer(child)` / `setLayer(child, layer)` 查询和修改，不直接改内部表。嵌套容器各自排序。`self('update', dt)` 等调用在自定义方法中显式转发；未定义该方法的容器自动向子内容转发。

通过 `room:findContainer('edit/sidebar/event')` 可定位任意嵌套容器。增删操作必须使用容器接口，以保持对象列表和层索引一致。

### 场景列表

| 场景 | 文件 | 说明 |
|------|------|------|
| play | `src/rooms/play.lua` | 编辑/游玩区域 |
| menu | `src/rooms/menu.lua` | 菜单选择界面 |
| editTool | `src/rooms/editTool.lua` | 编辑工具栏 |
| demo | `src/rooms/demo.lua` | 演示/预览模式 |
| sidebar | `src/rooms/sidebar.lua` | 侧边栏面板 |
| start | `src/rooms/start.lua` | 启动画面 |

### 子场景/组件

| 组件 | 文件 | 说明 |
|------|------|------|
| denomPlay | `src/objects/play/denomPlay.lua` | 分度线渲染 |
| demoInEdit | `src/objects/play/demoInEdit.lua` | 编辑区演示渲染 |
| demoPlay | `src/objects/play/demoPlay.lua` | 游玩区渲染 |
| ctrl | `src/objects/play/ctrl.lua` | 编辑控制逻辑 |
| redo | `src/objects/play/redo.lua` | 撤销/重做 |
| slider | `src/objects/play/slider.lua` | 进度条 |
| select_music | `src/objects/menu/select_music.lua` | 歌曲选择 |
| select_chart | `src/objects/menu/select_chart.lua` | 谱面选择 |

---

## 色彩系统

### 基色定义 (`config/colors/base.lua`)

```lua
local base = {
    white  = {1, 1, 1},         -- 白色
    cyan   = {0, 1, 1},         -- 青色
    dcyan  = {0, 0.7, 0.7},     -- 暗青色
    black  = {0, 0, 0},         -- 黑色
    red    = {1, 0, 0},         -- 红色
    lred   = {1, 0.5, 0.5},     -- 浅红色
    dgray  = {0.18, 0.18, 0.18}, -- 深灰色
}

-- 辅助函数
local function rgba(rgb, alpha)
    return {rgb[1], rgb[2], rgb[3], alpha}
end
```

### 颜色分级

| 级别 | 命名规则 | alpha | 用途 |
|------|---------|-------|------|
| 纯色 | `white`, `cyan`, `black`, `red` | 1.0 | 主要元素 |
| 半透明 | `*_half` | 0.5 | 次要元素、选中态 |
| 淡色 | `*_fade` | 0.4 | 背景、填充 |
| 极淡 | `*_dim` | 0.2 | 弱化元素 |

### 颜色配置文件

| 文件 | 说明 |
|------|------|
| `config/colors/base.lua` | 共享基色定义 |
| `config/colors/play.lua` | 编辑/游玩区域颜色 |
| `config/colors/menu.lua` | 菜单界面颜色 |
| `config/colors/editTool.lua` | 编辑工具栏颜色 |
| `config/colors/demo.lua` | 演示模式颜色 |

### 使用方式

```lua
-- 在场景中加载
play.colors = require 'config.colors.play'

-- 使用颜色
love.graphics.setColor(play.colors.white_half)
love.graphics.setColor(play.colors.eventInDemo[eventType])  -- 动态 key
```

---

## 快捷键系统

### 定义快捷键 (`src/objects/meta.lua`)

```lua
meta_key = {
    __index = {
        play = {'space'},           -- 播放/暂停
        undo = {'ctrl','z'},        -- 撤销
        redoing = {'ctrl','y'},     -- 重做
        copy = {'ctrl','c'},        -- 复制
        paste = {'ctrl','v'},       -- 粘贴
        delete = {'delete'},        -- 删除
        -- ...
    }
}
```

### 使用快捷键

```lua
local input = require("src.utils.input")

-- 检测快捷键是否按下
if input('undo') then
    -- 执行撤销
end
```

### 自定义快捷键

用户配置文件：`users/key.json`

```json
{
    "play_pause": ["space"],
    "undo": ["lctrl", "z"],
    "redo": ["lctrl", "y"]
}
```

---

## 目录结构

```
daikumi editor/
├── main.lua                        -- 入口文件，全局变量初始化
├── isRequire.lua                   -- 模块加载器
├── conf.lua                        -- LOVE2D 配置
├── config/
│   ├── colors/                     -- 颜色配置
│   │   ├── base.lua                -- 共享基色
│   │   ├── play.lua                -- 编辑区颜色
│   │   ├── menu.lua                -- 菜单颜色
│   │   ├── editTool.lua            -- 工具栏颜色
│   │   └── demo.lua                -- 演示颜色
│   └── layouts/                    -- 布局配置
│       ├── play.lua
│       └── menu.lua
├── src/
│   ├── utils/                      -- 基础工具
│   │   ├── room.lua                -- 对象/容器/组/房间系统
│   │   ├── beat.lua                -- 节拍计算
│   │   ├── event.lua               -- 事件处理
│   │   ├── note.lua                -- 音符处理
│   │   ├── track.lua               -- 轨道坐标转换
│   │   ├── table.lua               -- 表工具函数
│   │   ├── input.lua               -- 快捷键管理
│   │   ├── plugin.lua              -- 插件管理器
│   │   ├── window.lua              -- 窗口管理
│   │   ├── save.lua                -- 保存功能
│   │   ├── log.lua                 -- 日志系统
│   │   ├── file.lua                -- 文件工具
│   │   ├── pass.lua                -- 空函数占位
│   │   ├── string.lua              -- 字符串工具
│   │   ├── math.lua                -- 数学工具
│   │   └── bezier.lua              -- 贝塞尔曲线
│   ├── services/                   -- 服务层
│   │   ├── chartService.lua        -- 谱面数据服务
│   │   ├── coordinateService.lua   -- 坐标转换服务
│   │   └── audioService.lua        -- 音频服务
│   ├── objects/                    -- 业务逻辑
│   │   ├── meta.lua                -- 数据模型定义
│   │   ├── messageBox.lua          -- 消息提示框
│   │   ├── i18n.lua                -- 国际化
│   │   ├── allImage.lua            -- 图片资源
│   │   ├── ui.lua                  -- UI 工具
│   │   ├── play/                   -- 编辑区组件
│   │   │   ├── ctrl.lua            -- 编辑控制
│   │   │   ├── redo.lua            -- 撤销/重做
│   │   │   ├── denomPlay.lua       -- 分度线
│   │   │   ├── demoInEdit.lua      -- 编辑区演示
│   │   │   ├── demoPlay.lua        -- 游玩区渲染
│   │   │   └── slider.lua          -- 进度条
│   │   ├── menu/                   -- 菜单组件
│   │   │   ├── select_music.lua    -- 歌曲选择
│   │   │   ├── select_chart.lua    -- 谱面选择
│   │   │   └── FFT.lua             -- FFT 频谱
│   │   └── sidebar/                -- 侧边栏组件
│   │       └── settings.lua        -- 设置面板
│   ├── plugins/                    -- 插件
│   │   ├── init.lua                -- 插件加载器
│   │   ├── equalizer.lua           -- 均衡器
│   │   ├── to_takana.lua           -- Takana 转谱
│   │   ├── fft.lua                 -- FFT 频谱
│   │   ├── hit.lua                 -- 打击效果
│   │   └── directEventEditing.lua  -- 直观事件编辑
│   └── rooms/                      -- 场景
│       ├── play.lua                -- 编辑/游玩场景
│       ├── menu.lua                -- 菜单场景
│       ├── editTool.lua            -- 编辑工具栏
│       ├── demo.lua                -- 演示场景
│       ├── sidebar.lua             -- 侧边栏
│       └── start.lua               -- 启动画面
├── assets/                         -- 资源文件
│   ├── sound/                      -- 音效
│   └── image/                      -- 图片
├── i18n/                           -- 国际化文件
├── users/                          -- 用户数据（运行时生成）
│   ├── settings.json               -- 用户设置
│   ├── key.json                    -- 快捷键配置
│   ├── chart/                      -- 谱面文件
│   ├── log/                        -- 日志
│   ├── export/                     -- 导出文件
│   ├── auto_save/                  -- 自动保存
│   └── ui/                         -- 自定义 UI
├── USER_GUIDE.md                   -- 用户指南
└── DEVELOPER_GUIDE.md              -- 开发者文档（本文件）
```

---

## 常见开发任务

### 添加新的音符类型

1. 在 `src/objects/meta.lua` 的 `isNoteType()` 中添加类型判断
2. 在 `src/utils/note.lua` 的 `note:place()` 中添加放置逻辑
3. 在 `src/objects/play/demoInEdit.lua` 中添加渲染逻辑
4. 在 `src/objects/play/demoPlay.lua` 中添加游玩区渲染
5. 更新 `src/objects/play/redo.lua` 的撤销/重做支持

### 添加新的事件类型

1. 在 `src/objects/meta.lua` 的 `event_type` 表中添加类型
2. 在 `src/objects/meta.lua` 的 `trackSequence` 表中添加位置映射
3. 在 `src/utils/event.lua` 的 `event:get()` 中添加值计算
4. 在 `src/rooms/play.lua` 的 event 渲染循环中添加显示
5. 在 `src/objects/sidebar/` 中添加编辑 UI

### 添加新的场景

1. 在 `src/rooms/` 下创建新文件
2. 使用 `room:new()` 或 `group:new()` 创建场景对象
3. 实现生命周期方法（load, update, draw, keypressed 等）
4. 在 `isRequire.lua` 的第 8 层添加 require
5. 在主场景中添加切换逻辑

### 添加新的服务

1. 在 `src/services/` 下创建新文件
2. 定义服务表和方法
3. 在 `main.lua` 中 require 并添加到 PluginManager 的 ctx 中
4. 插件可通过 `ctx.服务名` 访问

---

*本文档最后更新：2026-08-19*
