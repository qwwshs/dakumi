---
name: dakumi-editor
description: Dakumi Editor 项目上下文 Skill（LÖVE2D 11.4 + LuaJIT 谱面编辑器，中文注释）。只要涉及本项目的代码修改、调试、测试、架构理解，或用户提到 dakumi/谱面/chart.json/波形/drawSample/beat/BPM/音符/事件/轨道/标签页/菜单/设置/快捷键/时间轴/offset/demoInEdit/rooms/tabs/nuklear 等概念，都应先加载本技能，再动手。
---

# Dakumi Editor 项目指南

## 1. 项目概览

- 用途：节奏谱面（chart）可视化编辑器，支持多图层/多轨道/事件（BEZIER 等）、波形图、标签页多窗口、Nuklear 菜单。
- 运行平台：Windows + LÖVE2D **11.4**（LuaJIT = **Lua 5.1** 语义）。入口 `main.lua`，当前版本 `DAKUMI._VERSION = "0.6.0"`。
- 设计分辨率 1600×900（`WINDOW.w/h`），窗口按 `WINDOW.scale = min(nowW/1600, nowH/900)` 缩放并补黑边；`src/utils/window.lua` 负责坐标变换。
- 代码与注释全部为**中文**，文件为 **UTF-8 + CRLF**（Windows Git Bash 下勿破坏换行编码）。
- 用户谱面数据在 `users/chart/<歌曲>/`，已被 `.gitignore` 忽略（`users/` 整目录不入库）。

## 2. 快速启动与测试

```bash
# 运行编辑器（把 . 当作游戏目录）
"/c/Program Files/LOVE/love.exe" "."

# 已入库的自动检查与回归
python scripts/run_tests.py --syntax
python scripts/check_boundaries.py
python scripts/run_tests.py
python scripts/run_tests.py --integration --love "C:/Program Files/LOVE/love.exe"
python scripts/run_tests.py --ui --love "C:/Program Files/LOVE/love.exe"
```

## 3. 技术栈

| 组件 | 说明 |
|---|---|
| LÖVE2D 11.4 | 游戏框架；`love.sound.newSoundData` 可解码 mp3/ogg/wav，`getSample(i, ch)` 声道参数为 1 基（实测本机 LÖVE 11.4：ch=1..channelCount，ch=0 越界报错；采样索引是 0 基） |
| LuaJIT (Lua 5.1) | 编码时只按 5.1 写；**不要**用 Lua 5.4+/5.5 的语法或静态检查结论（见坑点 8.6） |
| Nuklear (`nuklear.dll` + `nuklear` lua) | 即时模式 GUI，用于菜单/工具栏/弹窗；`Nui = nuklear.newUI()` |
| Slab (`src/utils/Slab/`) | 另一个即时 GUI 框架（配置编辑器等） |
| dkjson (`src/utils/dkjson.lua`) | chart.json 解析/序列化 |
| nativefs (`src/utils/nativefs.lua`) | 访问 save 目录**之外**的项目文件（如 `users/chart/**`） |
| moonshine (`src/utils/moonshine`) | 菜单高斯/盒模糊后处理 |
| serpent / yaml / lovefft / luafft | 序列化、解析、FFT 插件 |
| `users/key.json` | 快捷键（如 `play = ["space"]`）；`users/settings.json` | 设置（含 `judge_line_y`、`note_height`、`wavfrom` 等） |

## 4. 目录结构

```
dakumi editor/
├── main.lua                 # 主入口：全局前缀、Nui 样式、事件循环、错误处理
├── conf.lua                 # LÖVE 配置（关键文件，修改需备份，见坑点 8.10）
├── isRequire.lua            # 十层依赖集中加载（nuklear→meta→beat→…→业务模块）
├── assets/fonts/            # 字体（LXGWNeoXiHei）
├── config/
│   ├── layouts/{play,menu,demo,editTool,sidebar,tab}.lua   # 界面矩形表（x/y/w/h/interval…）
│   └── colors/{play,menu,demo,editTool,base}.lua           # 配色表
├── src/
│   ├── utils/               # 基础库：room.lua(对象系统)、beat.lua、math.lua、table.lua、
│   │                        #   save.lua、input.lua、track.lua、event.lua、note.lua、
│   │                        #   eventBus.lua(事件总栈)、chartRecorder.lua(撤销强制记录)、clipboard.lua(剪贴板数据)、editState.lua(交互状态)、
│   │                        #   window.lua、nativefs.lua、dkjson.lua、moonshine/、Slab/…
│   ├── services/            # chartService/ 按职责装配；audioService 私有管理音频和时钟
│   ├── models/              # Note/Event 数据实体；objects 同名文件为兼容转发
│   ├── objects/             # 业务对象：meta.lua(元表)、allImage.lua(isImage)、
│   │   ├── menu/            #   menu/ui.lua(菜单按钮表)、select_music、select_chart、FFT
│   │   └── play/            #   demoInEdit.lua(编辑窗渲染，含波形)、demoPlay、note、event…
│   ├── rooms/               # 场景：start/menu/demo/edit/editTool/sidebar/play/tabs
│   └── shader/ thread/      # 着色器、线程
├── plugins/                 # 插件目录（已加 package.path 前缀；fft.lua 等）
├── i18n/                    # 多语言（i18n:get(obj.text)）
├── users/                   # 用户数据（gitignore）：chart/<歌>/、settings.json、key.json
└── .zcode/                  # 测试/验证/临时区（不入库；waveverify/ 为波形回归 harness）
```

## 5. 加载顺序（重要）

1. `main.lua`：先定义全局 `DAKUMI / beat / bg / mouse / elapsed_time / FONT / iskeyboard / WINDOW / PATH`；音频资源和时钟由 AudioService 私有持有，并把 `plugins/` 前缀加进 `package.path`。
2. `require 'isRequire'`：按十层加载全部模块（见 isRequire.lua 顶部注释），**其中 `src/objects/meta` 在第 4 层，加载期就要读 `WINDOW.w/h`（`meta.lua` 的 `meta_settings` 默认值）**。
   - **顺序坑**：模块体顶层（加载期）执行的依赖必须排在被依赖者之后——`clipboard.lua` 顶层就调 `table.copy`，必须排在 `table.lua` 之后；排错会在真实启动时报 `attempt to call field 'copy' (a nil value)`。单元测试因手动先 require 了 table 而**测不出**这类顺序错误，只有真实启动链路能暴露（2026-09-30 实测）。
3. `PluginManager = require("src.utils.plugin")` + 服务层。
4. 任何自建测试入口都要**先照抄 main.lua 的全局前缀**再 require 业务模块，否则加载期报 `attempt to index global 'WINDOW' (a nil value)`。

## 6. 编码规范

- 注释用中文，`--` 行注释；新代码沿用模块头 `--[[ ... ]]` 说明（模块名/描述/作者/依赖）。
- 缩进 4 空格；键名小写下划线；全局单例用全小写（`beat`、`settings`、`menu`），结构/常量用大写或局部化（`WAVE_CELL`、`ChartService` 局部引用）。
- 服务模块模式：`local X = {}; function X:method() ... end; return X`，调用处 `require("src.services.x")`。
- 常量放模块顶部并注释单位/含义；不要散落魔法数。
- 布局矩形统一用 `config/layouts/*.lua` 的 `{x, y, w, h, ...}` 表，避免硬编码坐标。
- 改动范围要克制：不破坏 `conf.lua`、不动 `users/` 真实谱面、不在测试里调用写盘接口。`ChartService:load()` 仅在内存迁移并建立索引；`save()` 才写盘。
- 时间/节拍单位要标明：**秒**（时间）、**拍**（beat，表 `{整数, 分子, 分母}` 如 `{2,1,4}`）、**毫秒**（chart `offset`）。

## 7. 架构设计决策

### 7.1 对象系统（room.lua）：object / container / group / room

- `object:new(__name)` 建基础对象；`container` 含子对象与子组；`group` 是不能切房间的容器；`room` 是多场景管理器。
- `room:new('menu')` 建场景并 `room:addRoom(menu)` 注册；`room:to('edit')` 切换；`room:load(name)` 只改 `__type`（当前房间）。
- **事件分发靠 `__call`**：`room('update', dt)`（对象里常见写法 `self('select_music')` / `self('load')`）按数字层由小到大调用子对象、子组和活动子 room；同层按导入顺序，默认 math.huge。自定义方法中转发位置决定子内容的执行时机。给房间加逻辑时直接 `function roomName:update(dt)`。
- 生命周期方法：`load / update / draw / keypressed / mousereleased / mousepressed / wheelmoved / textinput / resize / quit / filedropped`。
- `menu:addObject(require 'src.objects.menu.select_music')` —— 子对象常是被 require 的模块表本身。

### 7.2 全局状态 vs 服务层

- 音频资源、播放状态和时钟由 AudioService 私有持有。读取用 `getCurrentTime/getCurrentBeat/getSoundData`，控制用 `seek/pause/resume/setRate`；`music/music_data/music_play/time` 与 `beat.nowbeat/allbeat` 已移除。旧界面仍有 `settings/denom/track` 等单例，新模块不要扩大此类耦合。
- 数据访问走服务：`ChartService` 用**模块私有** chart（`setChart` 内部深拷贝+补默认字段，不自带全局 chart 变量）；`CoordinateService` 无状态只做转换。
- 跨模块**通知**走事件总栈 `eventBus`（见 7.8）：发布方只广播领域事件，订阅方自行响应，互不持有引用。
- 结论：改数据统一走 ChartService；跨实例共享的昂贵资源放模块级局部（见 7.6 波形缓存）。

### 7.3 时间与坐标模型（改前必读）

- 当前谱面拍和秒数用 `AudioService:getCurrentBeat()` / `getCurrentTime()`；总拍数与时长由资源、offset 和 BPM 表推导。
- 坐标：`yToBeat(pos) = (pos - judge_line_y) / (-denom.scale * 100) + AudioService:getCurrentBeat()`；逆变换 `toY(beat) = judge_line_y + (nowbeat - beat) * denom.scale * 100`。**1 拍 = denom.scale×100 像素**，`denom.scale = 1` 为默认。
- 判定线 `settings.judge_line_y`（默认 700）是"现在"；窗口顶部是**未来**，越靠近判定线越晚/越近。
- 音频位置 = 谱面时间 − `ChartService:getOffset()/1000`（chart `offset` 单位毫秒，Antithesis 为 −163，表示音频比谱面早 163ms）。
- BPM 列表支持恒速与渐变（`linear_ramp`），`beat:toTime/toBeat` 按列表分段计算；**`#bpm == 1` 有短路分支，不要假设 `bpm[2]` 存在**。
- **轨道边界**（`track.left_boundary/right_boundary/boundary_type/left_reference/right_reference`，2026-09 新增）：在 `fEvent:get()` 末尾以"区间求交"方式作用于轨道 x/w（`[lpos, rpos]` 与边界线相交后取中点/半宽，所以轨道是被压缩而不是裁剪）。`boundary_type = 'track'` 时两个 boundary 字段填**轨道号**，参考类型 `x/w/lpos/rpos` 取边界轨道的中心/宽度/左右缘；`'pos'` 时填坐标。**是否启用只看 `boundary_type`（只有 `'nil'` 不启用，用户 2026-09-13 明确）**：pos 模式两侧无条件按坐标生效，0 也是合法坐标（两侧都填 0 就是零宽贴在坐标 0 上，所以刚切到 pos 又没填值会把轨道夹没）；track 模式下填的轨道号在谱面里不存在（含默认 0 而谱面无 track 0）时该侧无从解析，跳过。夹出反向区间（自然区间与边界不相交）时轨道被压成零宽贴在最近的边界线上。`reference = 'w'` 是**有意**的特例：直接把边界轨道的宽度当坐标用（用户确认要保留，别当 bug 修）。边界轨道单独解析父链（不能沿用 `parent_tab`），存在性由 `ChartService:hasTrackData` 判断。

### 7.4 谱面数据（chart.json）

- 顶层：`bpm_list`（`{bpm, beat={i,n,d}, linear_ramp}`）、`offset`、`note`（对象数组：`track/type/beat/beat2/note_head/wipe_head/fake`，`type` ∈ note/wipe/hold）、`event`、`info`（song_name/chart_name）。
- 旧格式 `.d3` = 数据表，由 `safeInput.parseTable` 受限解析后转存 JSON；不执行其中代码。
- 工具函数有 `getFileExtension`（`src/utils/file.lua`）。
- 读取入口链（菜单）：`menu('toedit')` → `ChartService:load()` → `AudioService:prepareEditor()` → `room:to('edit')`。

### 7.5 GUI：两层并存

- **Nuklear（菜单/工具栏）**：按钮定义在 `src/objects/menu/ui.lua`（`obj.func()`），每帧 `Nui:windowBegin(...)` + `Nui:layoutRow(...)` + `Nui:button(...)` + `Nui:windowEnd()`；输入管线由 `src/services/inputRouter.lua` 统一接管 UI、弹窗和场景；鼠标释放回到按下时的归属，坐标经缩放与黑边换算。
- **Slab / 自有绘制（编辑窗口）**：`demoInEdit:draw()` 直接 `love.graphics`，显式 setColor（多标签页下会被其他实例遮罩污染颜色，画完轨道线记得 `setColor(1,1,1)`）。

### 7.6 编辑窗口 demoInEdit（多实例原型模式）

- 原型表 `demoInEdit.__index = demoInEdit`：每个**标签页窗口** = `demoInEdit:new{tabbed=true, tab=标签页数据}`，方法/图像/布局经原型共享；模块表本身是注册在 play 组的默认实例，仅 `tabs:isSingle()` 时绘制（`draw()` 守卫：`pos == nil and tabs and not tabs:isSingle()` 时返回）。
- 窗口渲染完全由实例自己完成：`demoInEdit:draw()` 的 tabbed 分支做可见性判断（完全在 play 区域外则跳过）、`setScissor` 裁剪、调 `drawEditContent`（波形/轨道/note/event/信息）、不可编辑轨道遮罩、顶部轨道标签（`tabs:tabTitle`）；`tabs:draw()` 只遍历 `tab.editView:draw()`，不再手动渲染。
- 实例字段：`self.x`（窗口左缘，`tabs:update` 每帧与 `tabs:windowX(i)` 同步；`tabs:draw` 绘制前再同步一次，覆盖 + 按钮在 update 同步循环之后新建标签页的当帧）、`self.tab`（标签页数据引用；轨道经 `tabs:getTabTrack(self.tab)` 解析，track 0 = 跟随 track.track）。
- 资源加载：`demoInEdit:load()` 由 `play:load()` 分发调用（幂等：`if self.layout then return end`），默认实例加载后标签页实例经原型共享 `ui_*` 图像与 `layout`；`self.layout = play.layout.edit`。

### 7.7 复制/粘贴与粘贴预览（plugins/ctrl.lua）

- **剪贴板**：数据本体在核心模块 **`src/utils/clipboard.lua`**（`clipboard.tab` 复制表 = `{note, event, note_tracks/event_tracks, note_tabidx/event_tabidx, type="copy"/"cut", pos="play"/"edit"/"tabs"}`、`clipboard.meta` 空白结构、`clipboard.mouse_start_pos` 框选起点、`add/sub/exist/get/convertTabsToPlay`）。ctrl 插件只承担交互（右键单选/Shift 框选/快捷键见 `meta_key`：Ctrl+C/X/V、Ctrl+B 取反、Ctrl+A+V 带 event），其 `copy_add/copy_sub/copy_exist/get_copy/convertTabsClipboardToPlay` 方法是**兼容委托**（alt 插件与测试仍按插件方法调用）。内部模块一律走 clipboard 模块，不引用 ctrl 全局。
- **粘贴变换统一定义在 `ctrl:getPasteItems(flip, all)`**：深拷贝剪贴板 → 以鼠标 beat（`beat:toNearby(yToBeat(mouse.y))`）为锚点、`first_beat` 为基准整体平移 → 非 play/tabs 来源时轨道重置为 `track.track`；跨标签页（pos=='tabs'）按 `tabs:getTabAtMouse()` 与来源 tabidx 位移并 `setTrack(tabs:getTabTrack)`。`handlePaste` 与粘贴预览共用，保证预览位置=粘贴结果（2026-09-08 重构）。
- **粘贴预览**：`ctrl:draw()` 末尾在复制表有内容时调 `drawPastePreview()`，以 50% 透明度（`setColor(1,1,1,0.5)`）画 ghost（isImage 贴图，位置跟随鼠标）；`ctrl:draw()` 里青色/白色块仅是**原位置选中标记**，别与 ghost 混淆。play 区域来源（pos=='play'）ghost 画在 demo 区各轨道 x（`play:get_all_track_pos` + `fTrack:to_play_track`），event 只在 edit 窗显示。
- **多标签页渲染顺序**：tabs 绘制完 edit 内容后发 `tabs:edit_content_drawn` 事件（事件总栈），ctrl 订阅并画框选标记与预览——tabs 不再反向调用 `ctrl:draw(true)`（2026-09-30 改）。
- 布局固定值：`play.layout.edit = {x=900, y=192, w=300, h=708, interval=60, oneTrackW=45, noteW=60}`（多轨道水平排列，间距 `interval`）。

### 7.7 波形图（drawSample）—— 本文档重点

`settings.wavfrom == 1` 时 `draw()` 调 `drawSample()`。实现三条缓存策略，改波形务必先理解：

1. **行条缓存 `rows`**：y 轴每 1px 一条"峰值带"（min/max），只依赖全局参数（`music/nowbeat/scale/judge/offset/bpmCount`），**不依赖窗口 x**，多标签页同帧共享一次计算。重建条件（`drawSample` 中）：
   `not (rows.valid and rows.pending==0 and rows.music==AudioService:getSoundData() and rows.nowbeat==AudioService:getCurrentBeat() and rows.scale==denom.scale and rows.judge==judge and rows.offset==ChartService:getOffset() and rows.bpmCount==ChartService:getBpmCount())` → `rowsRebuild()`。
2. **采样峰值单元缓存 `wav`**：音频按 `WAVE_CELL=64` 采样（约 1.45ms@44.1k）为单元，按声道存 `mn1/mx1`（声道1）、`mn2/mx2`（声道2）；`WAVE_PREFETCH_S=4` 预取视窗后；每帧**时间预算**增量构建：已覆盖 `WAVE_BUILD_MS=1.2ms`、未覆盖（首帧/跳转）`WAVE_BUILD_MS_GAP=8ms`；`AudioService:getSoundData()` 变化即 `wavReset()`。
3. **pending 机制**：`rowsRebuild` 里某行引用的单元还没建完 → `rows.pending += 1` 且该行留空；因此 `rows.pending > 0` 时每帧重建，**底部（近判定线）先出现、向上逐步补全**。静态视图空白多半是 pending 长期不为 0 或重建条件没匹配上，别直接删缓存。

绘制的行→音频区间映射：`yTop = y0+i-1`；`t1 = toTime(yToBeat(yTop)) - offset/1000`、`t0 = toTime(yToBeat(yTop+1)) - offset/1000`；`s1 = floor(t1*sr)`、`s0 = ceil(t0*sr)`；若 `s1-s0 < WAVE_CELL` 走**原始采样直读**（缩小视图如 scale=0.1 每行约 17 采样，全走这条，与单元缓存无关），否则走单元缓存。

**分色规则**（立体声）：中线 `cx = x + track_w/2`，两侧各留 1px（共 2px 深色缝）；左声道幅度 `max(|lo|,|hi|)` 蓝色 `(0.42,0.72,1)` 向**左**画，右声道 `max(|lo2|,|hi2|)` 橙色 `(1,0.6,0.32)` 向**右**画，边界夹在 `[x+3, x+track_w-3]`；单声道只有 `rows.lo/hi`，居中蓝色 `(0.45,0.75,1)`。透明度全高度统一 `WAVE_ALPHA = 0.45`（历史上曾是 6 档 `0.14 + 0.08*档位` 顶暗底亮，用户反馈整体不均匀后于 2026-09-08 改为统一值）。

### 7.8 事件总栈（eventBus，2026-09-30 新增）

`src/utils/eventBus.lua`，isRequire 第 4 层挂全局 `eventBus`。模块间解耦用：发布方只广播领域事件，订阅方自行响应，互不持有引用。API：`on(name, fn)` 返回退订函数、`off(name[, fn])`、`emit(name, ...)`（**同步**、按订阅顺序、pcall 隔离单个回调错误并写日志）、`count(name)`、`clear([name])`。事件名约定 `域:事件`。

当前事件（发布方 → 订阅方）：

- `chart:replaced` — `ChartService:setChart` → `redo:clear`
- `chart:committed` `(operation, actionKey)` — 由 `chartRecorder.commit` 在事务提交时统一广播（手势层不再手动发）→ `redo:writeRevoke`。`operation = {add={note={},event={}}, del={note={},event={}}, groups_before=?, groups_after=?, fields_before=?, fields_after=?}`（fields 见 7.10）
- `chart:group_edit_begin` / `chart:group_edit_end` `(operation, actionKey)` — 事件组编辑进出 → `redo:suspend/resume`（挂起/恢复撤销栈，挂起态在 `redo._suspended`；组内编辑写入临时栈）
- `tabs:edit_content_drawn` — tabs 绘制完多标签页 edit 内容 → ctrl 插件叠加框选标记/粘贴预览

要点：

- **ChartService 不再引用 redo 全局**（旧代码 9 处直调 + 组编辑直接换栈已全部移除）；`plugins/redo.lua` 模块加载时订阅（require 缓存保证只订阅一次；内置插件不热卸载，故不走 PluginManager 钩子清理）。
- `plugins/operationHistory.lua` 仍直连 `redo`（getHistory/jumpTo 属撤销域的查询/命令，不是谱面变更通知，**有意不解**）。
- `PluginManager:on/emit` 保留不动：那是**插件作用域**的钩子机制（带 ctx、按插件层排序），与全局事件总栈是两套东西，别混用；现全项目只有 ChartService 发 4 个插件钩子（onEventAdd 等）、无订阅者。
- 回归测试：`tests/event_bus.lua`（`python .zcode/run_lua.py tests/event_bus.lua` 直跑）。

### 7.9 依赖方向铁律：内部模块不引用外部插件（2026-09-30 确立）

`src/**`、`main.lua` 等**内部模块不得引用插件导出的全局**（`ctrl`/`redo`/`directEventEditing` 等）——插件是可选的，核心功能不能依赖可选件。依赖方向只允许**插件 → 核心**。此前 ctrl/directEventEditing 的 6 处反向引用已修，方式是"状态/数据下沉核心 + 通知走事件总栈"：

- **`src/utils/clipboard.lua`**（isRequire 第 5 层，全局 `clipboard`）：剪贴板数据与纯变换。ctrl 插件承担交互；tabs（`convertTabsToPlay`）、sidebar/events（`get`）、event_groups（组编辑时保存/恢复 `clipboard.tab`）都只依赖它。
- **`src/utils/editState.lua`**（isRequire 第 5 层，全局 `editState`）：插件写、核心读的交互状态。`demoCaptured`（directEventEditing 直观编辑模式开，play 区轨道点选让位）、`draggingEvent`（插件拖拽 event 控制点中，sidebar event 页 leave() 不记撤销）；插件在 keypressed/update 每帧同步。
- 判断一个新引用该走哪条路：**通知/渲染顺序** → eventBus 发事件；**查询/命令但属于核心域的状态** → 下沉成核心模块让插件来写；**纯撤销域内部的查询/命令**（如 operationHistory→redo）→ 允许插件间直连。

### 7.10 撤销强制记录（chartRecorder，2026-09-30 新增）

`src/utils/chartRecorder.lua`（叶子模块）+ ChartService 事务入口。**任何谱面修改都强制进撤销栈，调用方无法跳过**；唯一豁免是撤销回放与内部定位舞步（`recorder.suspend`）。

- **事务模型**：`ChartService:change(actionKey, fn)`（一个手势一条记录）、`beginChange/commitChange`（拖拽等跨帧手势，如 Gevent 页面事务）、`push/pop`（批量，现即事务）；事务外的低层增删/setter/字段修改**自动包单发事务**立即提交。
- **实体内容变更**：Note/Event 全部 setter 末尾经 `recorder.autoCommit` 拦截——图谱面（成员注册表）的对象自动快照旧值（事务内只取第一次）并累积；提交时生成 del旧+add新 记录。**谱面外副本（粘贴预览、Incoming 编辑副本）不记录**。
- **字段变更**（offset/info/preference/track/bpm_list）：`touchField` 记录前后值，操作记录新增 `fields_before/fields_after`（`{kind=,key=,value=}` 列表）；`ChartService:restoreFields` 在回放时恢复。
- **豁免区**：`ChartService:suspend(fn)` —— redo 的 applyOperation 整体包住；leave() 的非法落点回退；putEventGroup 的重命名引用循环。
- **手势接线**：Gevent:to 开页面事务 / leave 提交（**旧 leave 换对象舞步已退役**，非法落点改为 suspend 下恢复字段值）；Gevents:eventsDo、Gnote:NuiNext、chart_info/track_edit/preference 保存、alt 翻转/调整、directEventEditing 菜单全部走 change()；拖拽修改并入页面事务（不再单独发 'history.drag_event'）。
- **嵌套表直改绕过 setter**（如直接改 `getTransData()` 返回的数组）：setter 钩子拦不到，必须先 `ChartService:snapshotEntity(e)` 显式快照再改（见 directEventEditing 控制点增删）。
- **内容撤销是对象替换**：undo 恢复的是旧值副本（靠 `Event.__eq` 内容匹配删除现对象），撤销后要重新 `ChartService:getEvent(i)` 取实体，不能沿用旧引用。
- 成员注册表在 setChart/load/组编辑进出时重建；`chart_push` 缓冲区已删除（变更即时生效，chart 即实时状态）。
- **历史树（2026-09-30）**：撤销体系内部改为树，外部接口不变。
  - `redo.tree = {root, current}`，节点 `{id, parent, children, active_child, operation}`；root = 初始状态。
  - 撤销/重做只移动 `current`；**新操作不再丢弃撤销链**——它成为当前节点的活跃子节点，原来那条被撤销的链作为兄弟分支留在分叉节点的 `children` 上（即"撤销后理论上回不去的内容"，现在保留且可回去）。
  - `redo.revoke` / `redo.redo` 改为**由树重建的当前分支视图**（顺序与语义不变），既有调用方与旧测试无需改动。
  - `redo:getTreeView()` 先序（显式栈，不递归）返回整棵树 `{node, depth, status, is_fork, is_root, operation}`，status ∈ current/applied/undone/branch；`redo:jumpToNode(node)` 跨分支定位（沿 parent 退到公共祖先，再沿目标路径改写 `active_child` 前进）；`redo:isNode(node)` 判定节点归属。
  - `suspend/resume`（事件组编辑）挂起/恢复整棵树 + 计数器。
  - UI：`plugins/operationHistory.lua` 顶部 combobox 选「当前分支 / 所有分支」；**当前分支**=与撤销栈一致的按钮列表（分叉节点标 `分叉`），**所有分支**=整棵树的**树杈图**（见下）。
  - **树杈图**（2026-09-30）：每个历史节点画成圆（半径 6），**圆下方**写这一步做了什么（`状态` 标签只在非 applied 时补：`· 当前/已撤销/分支`）；连线从父节点文字底部连到子节点圆顶，被放弃的边用暗色。四种节点样式：当前=实心亮蓝、已完成=实心灰、已撤销=空心蓝、分支=空心暗灰；顶部一行图例说明这四种含义。
    - 布局：后序分配叶子槽位、父节点居中于子树 → 单链历史是一列竖直的圆，分叉处兄弟并排；`LEVEL_H=56` 为层高，`slotW = max(34,(bw-20)/叶子数)`，整块画布用 `layoutRow('dynamic', canvasH, 1)` + `widgetBounds()` + `label('')` 占位（图形画在取得的矩形上）。
    - 交互：`inputIsMousePressed('left', …)` 命中即 `redo:jumpToNode(node)`（单帧事件，不会连跳），`inputIsHovered` 只画高亮环 + 补画被省略号截断的完整名字；命中判定先与 `windowGetContentRegion()` 求交（滚出视野的节点不接受点击），视野外的文字也不画。
    - 绘制 API：`ui:circle('fill'/'line',x,y,r)`、`ui:line(x1,y1,x2,y2,…)`、`ui:text(str,x,y,w,h)`，均使用**当前 LÖVE 颜色/线宽**（先 `love.graphics.setColor/setLineWidth`）。
    - **`ui:text` 的字体坑**（见坑点 18）：C 层用 `love.graphics.getFont()` 注册字体，字体不对中文就是方块、宽度也对不上。
  - 分支不设上限，只有 `chart:replaced`（切谱面）时清空；反复"撤销后再改别的"会持续累积历史，属有意行为。
  - `redo.rev` 每帧可见的变化计数：树任何变化（writeRevoke/undo/redoOne/resetTree）都自增，面板据此缓存树视图与树杈图布局，不必每帧重算。
- 回归：`tests/enforce_undo.lua`、`tests/operation_history.lua`（分叉保留/跨分支切换/视图切换/树杈图绘制与点击）、`.zcode/historytree`（真实 Nuklear 帧内驱动面板，含抓图与点击合成）。

### 7.11 sidebar 页面刷新不变式（2026-09-30 确立）

- `sidebar:to(ty, ...)` 进入页面时：有 `to` 的调 `to(...)`；**只有 `load` 的页面（谱面信息/偏好/事件组）会自动 `load()` 从数据整体刷新**。原因：这些页面原先只在 `sidebar:load()` 广播时刷一次，撤销/重做或其它入口改了数据后，页面 widget 仍显示进入前的旧值 —— 数据其实已经撤销成功，但用户看到"编辑没被撤销"（谱面信息撤销"失效"的真实根因）。
- 页面若维护派生状态（如 chart_info 的 `self.bpmList`），`load()` 必须**整份重建**（先 `self.bpmList = {}` 再按 `getBpmCount()` 填），否则上一次进入残留的多余行会被保存写回谱面。
- 新页面只实现 `load` 即可自动获得"进入即刷新"；不要再靠 `to` 里手写赋值。
- 回归：`.zcode/sidebar_refresh/`（LÖVE 入口，直接 require 真实 `src.rooms.sidebar`，带全量 stub；`love .zcode/sidebar_refresh`，数秒自动退出，断言重新进入谱面信息页后文本/offset/BPM 列表都来自最新数据）。

## 8. 已知约束与坑点

1. **LÖVE 11.4 的 `love.filesystem.mount` 只支持 zip，不支持目录**（对任何目录路径都静默返回 false）。文件系统里只有游戏源目录 + save 目录；之前"require 能过"是 Lua 默认 loader 回退到了 `package.path`（CWD `/?.lua`）。**离屏测试方案**：`package.path = 项目根.."/?.lua;"..package.path` 加载模块；json/音频用 `io.open(绝对路径,"rb")` 读；音频再 `love.sound.newSoundData(love.filesystem.newFileData(字节, "x.mp3"))`。
2. **`love.sound.newSoundData` 第二参数不是格式字符串**（传 `"mp3"` 会报 number expected）。让 `newFileData` 的文件名带 `.mp3` 扩展名即可自动识别。
3. **`meta.lua` 加载期引用 `WINDOW.w/h`**：任何不经过 main.lua 的测试入口，必须在 `require('src/objects/meta')` 之前定义 `WINDOW = {w=1600,h=900,scale=1,nowW=1600,nowH=900,fullscreen=false}`（缺了报 `attempt to index global 'WINDOW'`）。`conf.lua` 中的身份（identity）必须唯一，重复身份会共用 save 目录。
4. **`ChartService:load()` 不写盘**，只做内存迁移、实体转换和索引构建。`save()` 才持久化，依赖选谱路径；测试不要对用户路径调用 `save`。`setChart` 返回数据状态，实体索引测试再调用 `load()`。
5. **`users/` 里是用户真实数据**（谱面/设置/截图）：测试结束后不残留文件；不要修改 `settings.json` 做实验，改动通过全局 `settings` 运行时模拟。
6. **是 LuaJIT (5.1)，不是 Lua 5.5**：用 `lua55.exe -e "assert(loadfile(...))"` 做语法检查会**误报**（5.5 把 for 循环变量当 const，如 main.lua 477 行）；只用它做纯语法粗检，结论以 LÖVE 实际运行为准。业务文件语法校验可以只对**你自己改的文件**做。
7. **进程纪律**：用户可能正开着编辑器（`love.exe` PID 不固定）。只杀**自己启动**的测试实例：先用 `cmd //c tasklist | grep -i love.exe` 列 PID，确认后按 PID 杀，绝不 `taskkill /IM love.exe /F`。测试进程建议让脚本自动退出（`love.event.quit()`），并用"启动后轮询日志+超时强杀"的看门狗兜底。
8. **Windows + Git Bash 命令行**：路径含空格与中文；`powershell -Command "..."` 里的 `$变量` 会被 bash 展开成空（单引号包住或写 .ps1）；`cmd //c` 的过滤参数带引号易被拆坏（用 `cmd //c tasklist | grep` 代替）；`ls | grep` 时含中文引号/反斜杠的路径字符串会触发 "unexpected EOF"，尽量用简化路径。
9. **大段中文注释的编辑**：Edit 工具的 `old_string` 必须与文件逐字一致（含制表符/换行）；多次失败时改用 python 按**唯一标记**字节级替换（如 `'-- 重建行条缓存'`），写回保持 UTF-8 + CRLF，别用行号拼接。
10. **`conf.lua` 高压线**：改动前先复制 `conf.lua.bak`；用字节安全方式小步修改；验证通过后恢复原状并删除 `.bak`。测试入口用**自己的**目录（如 `.zcode/waveverify/conf.lua`，identity 独立），不碰主 conf.lua。
11. **Nuklear 按钮无响应**：优先怀疑 `src/utils/inputRouter.lua` 的 UI 分发异常或错误捕获状态，或窗口 DPI/缩放坐标不匹配；渲染侧问题先加 `print`/日志，不要盲目改坐标。
12. **幅度/时间单位换算错误源**：`offset` 毫秒 vs `toTime` 秒（÷1000）；`getSample` 声道参数是 1 基（采样索引才是 0 基）；`denom.scale` 进公式是 `×100` 而不是裸值；行号 `i` 对应 `y = y0 + i - 1`（1 基）。
13. **静音/淡入音频**会体现为近判定线空白——用 `ffmpeg -i 歌曲 -af silencedetect=noise=-40dB:d=0.3 -f null -` 交叉验证"不是渲染 bug"（实测 Antithesis 前 1.22 秒完全静音）。
14. **vsync = 1（60fps）**：验证脚本按**帧号**驱动时间轴（不要按 wall-clock 假设），帧推进慢时延长帧数即可；`captureScreenshot` 异步回调依赖 thread 模块，统一用 `canvas:newImageData():encode("png")` 同步编码。
15. **恢复性 Git 状态**：项目要求 `.zcode/` 不入库、`users/` 已 gitignore；改完确认 `git status` 里只有预期文件。
16. **临时探针插件用完立刻删**：`plugins/*.lua` 是自动加载目录，探针放在那里**用户自己启动的编辑器也会执行它**（2026-09-30 实际发生：残留的探针在用户的一次启动里跑完整段脚本、改了谱面信息又清空撤销栈）。探针只在验证窗口内存在，跑完立即删除，并在交付说明里声明曾存在过；不要指望"只影响我自己的实例"。
17. **界面回显 ≠ 数据状态**：撤销"没生效"的现象要先分辨是数据层没回滚还是页面没刷新 —— 用真实启动探针（读 `ChartService:getInfoField` 之类的数据接口）与界面值分别记录，再决定改哪里。数据层正确时，问题通常在页面缓存/仅 load 不刷新。
18. **`ui:text`（以及所有自定义绘制）用的是 LÖVE 的字体/颜色，不是 Nuklear 样式**：C 层 `nk_love_draw_text` 走 `love.graphics.getFont()` + `print()`。所以调用前若不指定字体，就会用上一帧遗留的字体 —— 表现是**中文变成方块、宽度也对不上**（默认 LÖVE 字体没有 CJK），而 `ui:label`/`button` 等控件走 Nuklear 自己的字形，看起来完全正常（排查时容易误判成"图是坏的"）。修法：画之前 `love.graphics.setFont(FONT.normal)`，并按同一字体量宽（`.zcode/historytree` 早期版本正是这么踩的；该 harness 必须像 main.lua 一样把 `FONT` 定义成**全局表**，插件才拿得到）。另外 `ui:text` 每句都会在 C 层注册一次字体（`font_count`，每帧上限 1024），长列表/大树里**只画视野内的文字**，别在循环里无脑画。

## 9. 推荐工作流（改动前）

1. 明确改动模块 → 读该文件全文 + 它依赖的 `rooms/*.lua` 与 `config/layouts/*.lua`。
2. 先在 `.zcode/` 建独立测试目录（conf 独立 identity），跑起最小链路再改正式代码；波形类改动把真实谱面/音频喂进去出 PNG 人工核对。
3. 只改正式代码后重跑回归 harness；确认无 `users/` 写入、PCID 已清理、`conf.lua` 未动。
4. 改动涉及 isRequire 加载链后，验证真实启动用**探针插件法**：临时放一个 `plugins/zzbootprobe.lua`（`target='main'`，init 里 `io.open` 写标志文件 + `love.event.quit()`），启动 `love .` 后轮询标志文件出现 → 证明 isRequire→服务层→插件注册全链路走通，随后**必须删除探针**（否则编辑器一开就退）。两个实测教训（2026-09-30）：`love .` 无 `--console` 时 Lua 错误只画在错误屏上，**重定向日志为空 ≠ 启动成功**（love.exe 是 GUI 子系统，启动期 Lua 错误不进 stderr 管道）；`PATH.base`（`love.filesystem.getSourceBaseDirectory()`）返回的是源目录的**父目录**而不是项目根本身。
5. 交付时说明：改了什么、验证方式、遗留风险。

## 10. 速查表

| 诉求 | 位置 |
|---|---|
| 波形图渲染/缓存/分色 | `src/objects/play/demoInEdit.lua`（`drawSample` / `rowsRebuild` / `wavFill`） |
| 编辑窗口绘制 | 同上 `demoInEdit:draw()` |
| 谱面读写/offset/BPM | `src/services/chartService/`（`.lua` 仅兼容入口） |
| 拍↔时间 换算 | `src/utils/beat.lua` |
| 拍↔屏幕Y 换算 | `src/services/coordinateService.lua` |
| 轨道边界（boundary）计算 | `src/utils/event.lua` 的 `event:get()` 末段（轨道号存在性看 `ChartService:hasTrackData`） |
| 场景/对象/事件分发 | `src/utils/room.lua`、各 `src/rooms/*.lua` |
| 事件总栈（模块间解耦发布/订阅） | `src/utils/eventBus.lua`（订阅方示例 `plugins/redo.lua`，见 7.8） |
| 撤销强制记录/变更事务 | `src/utils/chartRecorder.lua` + `ChartService:change/beginChange/suspend`（见 7.10） |
| 历史树 / 分支切换 | `plugins/redo.lua` 的 `tree` / `getTreeView` / `jumpToNode`（见 7.10） |
| 操作历史面板（当前分支列表 / 所有分支树杈图） | `plugins/operationHistory.lua`（见 7.10） |
| Nuklear 自定义绘制（圆/线/文字、命中） | `ui:circle/line/text` + `ui:inputIsMousePressed/inputIsHovered`（单位是屏幕坐标，字体的坑见坑点 18） |
| sidebar 页面进入刷新 | `src/rooms/sidebar.lua` 的 `sidebar:to`（无 `to` 调 `load`，见 7.11） |
| 侧栏页面刷新回归 | `.zcode/sidebar_refresh/`（`love .zcode/sidebar_refresh`） |
| 剪贴板数据/纯变换 | `src/utils/clipboard.lua`（交互在 `plugins/ctrl.lua`，见 7.7/7.9） |
| 插件接管交互的状态 | `src/utils/editState.lua`（demoCaptured/draggingEvent，见 7.9） |
| 布局/配色 | `config/layouts/*`、`config/colors/*` |
| 设置默认值/元表 | `src/objects/meta.lua`（`meta_settings`） |
| 菜单按钮 | `src/objects/menu/ui.lua`、`src/rooms/menu.lua` |
| 快捷键 | `users/key.json` + `src/utils/input.lua` |
| 波形回归测试 | `.zcode/waveverify/`（`package.path` + io 直读 + canvas 同步编码） |
## 11. 文档维护约定

- 技能文档本身也会出错，不是权威参照：凡在读文档 → 对照代码/实测时发现不符或错误，**当场修正文档**，不要留到以后专门更新（例：`getSample` 声道参数一度写成"0 基"，实测 LÖVE 11.4 为 1 基、ch=0 报错，发现后立即改正）。
- 文档里的数值 / API 语义 / 换算关系要带**实测依据或版本环境**，让结论可复核，避免不可验证的断言再次误导（如"xx 是 0 基"这类凭印象的写法）。
- 每次改完代码或验证，顺手核对本文档相关段落是否仍准确（例如布局常量、函数签名、速查表路径）；有出入就同步更新。
- 交付总结中说明本次对文档做了哪些修改，便于复查。


## 12. 当前接口与文档入口（2026-10-04）

- 用户指南在 `readme/README.md`，事件组在 `readme/event_groups.md`，当前架构与接口以对照源码后的 `DEVELOPER_GUIDE.md` 为入口。旧段落若与源码不符，仍需当场修正。
- ChartService 实现在 `src/services/chartService/{init,index,transactions,lifecycle,event_groups,entities,fields,timing}.lua`，共享私有状态；模型在 `src/models`，工具由启动入口注入服务接口。
- 正常写入走 setter / 服务事务，支持字段、组与批量修改；失败事务回滚。`abortChange()` 只丢弃记录，不恢复数据。完整提交订阅 `chart:changed`，实时预览订阅 `chart:mutated`。
- 音频事件为 `audio:loaded/decoded/playing_changed/error`，解码输入先取文件快照，任务独立通道；测试入口为 `tests/audio_service.lua`、`tests/audio_service_love`。应用每帧仅推进一次 AudioService。
- 真实输入与布局回归为 `tests/editor_input_love`，不要依赖 `.zcode` 一定存在。网站在同级 `../dakumi.com/dakumi.com/doc`，`npm run docs:build` 验证。同步用户说明时保持英文配置键与中文注释。

## 13. 自动检查、服务索引与备份保留

- 全部 21 个服务文件（13 个顶层入口、8 个 ChartService 内部文件）见 `readme/服务索引.md`；新增模块必须补职责、接口和线程/生命周期边界。
- 回归入口已入库：`python scripts/run_tests.py` 自动发现根目录纯 Lua 测试；`--syntax` 仅做 LuaJIT 5.1 编译检查；`--integration --love <程序>` 跑真实音频/DSP；`--ui` 跑本机 Nuklear 回归。不要再以忽略的 `.zcode` 脚本作为唯一验证入口。
- `.github/workflows/check.yml` 在推送与 PR 时执行语法、架构边界、Luacheck 和 LÖVE 11.4 回归；Windows 任务通过仓库自带 Nuklear 运行完整编辑输入回归。
- directEventEditing/equalizer/takana/operationHistory 的 UI 必须使用初始化注入的 `ctx.ui` 和 `ctx.i18n`，不要新增全局 Nui 访问。`Nui()` 作为生命周期方法名可以保留。
- 自动保存通过 `src/utils/autoSaveRetention.lua` 清理：默认每谱面 50 份、30 天、全目录 256 MB，每谱面最近一份保护；新备份写入失败不清理。配置字段与旧文件兼容说明见 `readme/测试与备份.md`。开发测试必须使用虚拟目录，不能清理真实用户备份。
- `.gitignore` 仅放行本项目的 `SKILL.md`，其他本机技能继续忽略。本文与开发指南一起维护并纳入提交。
