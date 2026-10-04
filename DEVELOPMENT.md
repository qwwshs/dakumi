# Dakumi 开发入门

本页介绍运行、定位代码和验证改动。架构、数据与服务接口见 [开发者指南](DEVELOPER_GUIDE.md)，扩展功能见 [插件开发](plugins/README.md)。文档按当前源码维护，不是旧发行包的接口承诺。

## 运行环境

- LÖVE **11.4**，使用 LuaJIT / Lua 5.1 语义。
- 配套的 Nuklear 原生库；Windows 中文输入使用定制 SDL2。仅安装普通 LÖVE 不能保证所有界面能力可用。
- 源码自带的 Lua 库在 `src/utils/`，不需要照旧指南逐项用 LuaRocks 安装。

在项目根目录启动：

```powershell
& 'C:/Program Files/LOVE/love.exe' .
```

运行库位置随安装环境调整。完整打包所需文件见 [README](README.md#从源码运行与打包)。用户文件位于程序基础目录的 `users/`；测试请使用独立目录和身份，不修改真实用户数据。

## 从哪里开始读

| 要改的内容 | 主要入口 |
| --- | --- |
| 启动和依赖装配 | `main.lua`、`isRequire.lua` |
| 输入路由、鼠标坐标、UI 占用 | `src/services/inputRouter.lua`、`src/utils/window.lua` |
| 场景切换、执行层 | `src/utils/room.lua`、`src/rooms/` |
| 谱面读写与事务 | `src/services/chartService/init.lua` 及同目录子模块 |
| 音符 / 事件实体 | `src/models/Note.lua`、`src/models/Event.lua` |
| 轨道与事件组数值 | `src/utils/event.lua` |
| 播放、定位、音频资源 | `src/services/audioService.lua` |
| 波形与声纹图 | `src/objects/play/demoInEdit.lua`、`src/services/spectrogramService.lua`、`src/thread/`、`src/shader/` |
| 单次 BPM / offset 测量 | `src/services/bpmMeasureService.lua`、`src/services/bpmAnalyzer.lua` |
| 撤销、历史树、剪贴板交互 | `plugins/redo.lua`、`plugins/operationHistory.lua`、`plugins/ctrl.lua` |
| 侧边栏和键位录制 | `src/rooms/sidebar.lua`、`src/objects/sidebar/`、`src/services/keyCapture.lua` |
| 主题与音符九宫格 | `src/services/themeService.lua`、`src/utils/nineSlice.lua` |

## 开发约定

界面和插件调用服务，服务使用数据模型和基础工具。下层不能 require 上层；需要访问能力时，由 `isRequire.lua` 装配并注入接口。`src/objects/Note.lua` / `Event.lua` 是旧路径兼容入口，实际模型在 `src/models/`。

谱面修改通过 `ChartService` 和实体 setter，整次操作用 `change(actionKey, fn)` 或配对的 `beginChange/commitChange`。写入方提交中文可读说明或 i18n 键，让撤销和操作历史能解释发生了什么。不要直接修改 `_data` 或内部表，也不要用 `suspend` 跳过正常用户操作的撤销记录。

播放状态只由 AudioService 持有，使用 `seek/pause/resume/setRate`；不创建 `music/time/beat.nowbeat` 等旧全局。应用每帧只推进一次音频服务。

注释和说明用中文，配置字段及 API 名保留英文。沿用 UTF-8、现有换行与 4 空格缩进。布局和颜色优先复用 `config/` 与主题服务。

## 回归检查

纯 Lua 测试在根目录使用 LuaJIT，例如：

```powershell
luajit tests/layer_dependencies.lua
luajit tests/plugin_system.lua
luajit tests/event_bus.lua
luajit tests/event_groups.lua
luajit tests/transaction_errors.lua
luajit tests/audio_service.lua
```

若电脑只有 LÖVE，使用下面的独立 LÖVE 测试入口；不要改主 `conf.lua` 来临时测试。

```powershell
& 'C:/Program Files/LOVE/lovec.exe' tests/editor_input_love
& 'C:/Program Files/LOVE/lovec.exe' tests/audio_service_love
& 'C:/Program Files/LOVE/lovec.exe' tests/chart_change_love
& 'C:/Program Files/LOVE/lovec.exe' tests/spectrogram_love
& 'C:/Program Files/LOVE/lovec.exe' tests/bpm_love
```

`lovec.exe` 是 Windows 控制台入口，便于查看结果；其他平台使用 `love`。按改动选择相关测试，无需每次全部运行。`.zcode/` 是忽略的临时工作区，其中的验证脚本不保证存在于干净检出中。

保存相关改动要检查返回值与失败路径；UI 改动要在真实 Nuklear 下检查点击和滚轮；音频改动要核对 offset、变速、片段首尾和换歌后的资源释放。进程验证只关闭本次启动的测试实例。

## 文档维护

用户操作更新到 `readme/`，接口与架构更新到 `DEVELOPER_GUIDE.md`，插件相关内容更新到 `plugins/README.md`。网站是同级目录 `../dakumi.com/` 中的 VitePress 项目，页面在 `dakumi.com/doc/`；同步指南时保留英文配置名和中文解释，构建命令为 `npm run docs:build`。历史更新日志保留原版本段落，当前开发变化另列，不把开发分支当成已经发布的版本。
