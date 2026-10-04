# Dakumi Editor

![dakumi](icon.ico)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/qwwshs/dakumi)
![Love2D](https://img.shields.io/badge/Love2D-11.4-E06C75.svg)

Dakumi 是 qwwshs 使用 LÖVE 制作的 TAKUMI³ 饭制谱面编辑器。支持音符与轨道事件编辑、多标签页、事件组、波形与声纹图、操作历史、主题和外部插件。

## 下载与使用

从 [GitHub Releases](https://github.com/qwwshs/dakumi/releases) 下载并完整解压发行包，Windows 下运行 `dakumi.exe`。保留同目录的运行库与资源文件。拖入 `wav`、`mp3` 或 `ogg` 音乐会创建歌曲和空谱面；选择歌曲后可拖入 `json` / `d3` 谱面及背景图片。

用户数据在程序基础目录的 `users/` 中。更新程序前请备份整个目录，以及外部 `plugins/`、`defaultBezier.txt`。QQ 交流与反馈群：`865149292`。

## 文档入口

文档按当前源码整理；发行包若较旧，可能没有部分功能。

| 内容 | 文档 |
| --- | --- |
| 使用、导入、保存与恢复 | [文档首页](readme/README.md) |
| 编辑器操作和默认快捷键 | [编辑手册](readme/edit_manual.md) |
| 事件组的制作与放置 | [事件组](readme/event_groups.md) |
| 主题、图片与九宫格 | [主题自定义](readme/theme.md) |
| 声纹图设置与频率尺 | [声纹图](readme/spectrogram_manual.md) |
| 开发环境与回归检查 | [开发入门](DEVELOPMENT.md) |
| 分层、谱面格式、服务与通知 | [开发者指南](DEVELOPER_GUIDE.md) |
| 全部服务职责与接口 | [服务索引](readme/服务索引.md) |
| 自动检查与备份保留策略 | [测试与备份](readme/测试与备份.md) |
| 外部插件、执行层和示例 | [插件开发](plugins/README.md) |

在线指南：[dakumi.qwwshs.top](https://dakumi.qwwshs.top)。

## 从源码运行与打包

项目使用 **LÖVE 11.4 + LuaJIT（Lua 5.1）**。在项目根目录运行 `love .`。除 LÖVE 自带运行库外，还需要与系统及位数匹配的 `nuklear` 动态库。本项目的 Nuklear 绑定及 Windows 中文输入相关 SDL2 库有定制改动，普通发行库可能不包含这些能力；优先使用项目发行包配套的版本。其他平台需要自行提供相应的原生库。

打包时将以下内容放在 ZIP **根目录**，再改名为 `dakumi.love`：

```text
assets/
config/
i18n/
plugins/
src/
main.lua
conf.lua
isRequire.lua
icon.ico
```

不要打包 `users/`、`.git/`、`.zcode/` 和测试输出。发行包可另外附上 `defaultBezier.txt`；外部插件放在程序旁的 `plugins/` 中。

Windows 融合程序的命令：

```bat
copy /b love.exe+dakumi.love dakumi.exe
```

融合后仍须随包提供 LÖVE 和 Nuklear 所需动态库。macOS / Linux 可用 LÖVE 打开 `.love` 文件，但也需要适配的 Nuklear 库。

## 依赖与许可

主要依赖：[LÖVE](https://github.com/love2d/love)、[LÖVE-Nuklear](https://github.com/keharriso/love-nuklear)、[LXGW Neo XiHei](https://github.com/lxgw/LxgwNeoXiHei)、[dkjson](https://github.com/LuaDist/dkjson)、[serpent](https://github.com/pkulchenko/serpent)、[lua-yaml](https://github.com/exosite/lua-yaml)、[moonshine](https://github.com/vrld/moonshine)、[hump](https://github.com/vrld/hump)、[lovefft](https://github.com/Gennadiyev/lovefft)、[fileselect](https://github.com/bili-fule/fileselect)。单次 BPM / offset 测量参考 [qwwshs/bpm](https://github.com/qwwshs/bpm)。

项目使用 [MIT 许可](LICENSE)。第三方依赖遵循各自的许可。

元件毫秒位置调整见[偏移时值说明](readme/time_offset.md)。
