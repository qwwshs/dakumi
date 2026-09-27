# Dakumi 开发指南

## 目录

1. [项目概述](#项目概述)
2. [开发环境搭建](#开发环境搭建)
3. [架构设计](#架构设计)
4. [模块详解](#模块详解)
5. [开发流程](#开发流程)
6. [插件开发](#插件开发)
7. [调试与测试](#调试与测试)
8. [性能优化](#性能优化)
9. [常见问题](#常见问题)

---

## 项目概述

Dakumi 是一个基于 LOVE2D 11.4 框架开发的 TAKUMI³ 谱面编辑器。项目采用模块化设计，支持跨平台运行，具有插件扩展能力。

### 主要特性
- 跨平台支持（Windows、Linux、macOS）
- 多语言国际化支持
- 插件系统扩展
- 实时谱面预览和编辑
- 音频处理和分析
- 现代化 UI 设计

### 技术栈
- **框架**：LOVE2D 11.4
- **语言**：Lua
- **GUI**：Nuklear
- **音频**：LOVE2D Audio + LuaFFT
- **数据格式**：JSON + YAML

---

## 开发环境搭建

### 1. 安装 LOVE2D

```bash
# Windows
# 下载 LOVE2D 11.4：https://love2d.org/
# 将 love.exe 添加到 PATH 环境变量

# Linux (Ubuntu/Debian)
sudo apt-get install love

# macOS
brew install love
```

### 2. 克隆项目

```bash
git clone https://github.com/qwwshs/dakumi.git
cd dakumi
```

### 3. 安装依赖

项目依赖以下库（已包含在项目中）：
- LxgwNeoXiHei：中文字体
- dkjson：JSON 解析库
- serpent：Lua 表序列化库
- love-nuklear：Nuklear GUI 绑定
- yaml：YAML 解析库
- moonshine：后处理特效库
- hump：LOVE2D 工具库
- lovefft：FFT 音频分析库

### 4. 运行项目

```bash
# 直接运行
love .

# 或者打包后运行
love dakumi.love
```

### 5. 开发工具推荐

- **IDE**：VS Code + Lua 插件
- **调试**：LOVE2D 调试器
- **版本控制**：Git
- **代码格式化**：lua-fmt
- **静态分析**：luacheck

---

## 架构设计

### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    应用层 (Application)                   │
├─────────────────────────────────────────────────────────┤
│  场景层 (Rooms)  │  对象层 (Objects)  │  服务层 (Services)  │
├─────────────────────────────────────────────────────────┤
│                    工具层 (Utils)                        │
├─────────────────────────────────────────────────────────┤
│                    框架层 (LOVE2D)                       │
└─────────────────────────────────────────────────────────┘
```

### 模块划分

#### 1. 场景层 (src/rooms/)
- **start.lua**：启动场景，显示启动画面
- **menu.lua**：菜单场景，谱面选择和管理
- **edit.lua**：编辑场景，主编辑界面
  - **play.lua**：播放控制
  - **sidebar.lua**：侧边栏
  - **editTool.lua**：编辑工具
  - **demo.lua**：演示模式
  - **tabs.lua**：标签页管理

#### 2. 对象层 (src/objects/)
- **Note.lua**：音符对象
- **Event.lua**：事件对象
- **ui.lua**：UI 工具封装
- **messageBox.lua**：消息提示框
- **i18n.lua**：国际化模块
- **allImage.lua**：图片资源管理

#### 3. 服务层 (src/services/)
- **chartService.lua**：谱面数据管理服务
- **coordinateService.lua**：坐标转换服务
- **audioService.lua**：音频处理服务

#### 4. 工具层 (src/utils/)
- **room.lua**：房间/场景管理系统
- **beat.lua**：节拍计算模块
- **event.lua**：事件处理模块
- **note.lua**：音符处理模块
- **plugin.lua**：插件管理器
- **file.lua**：文件工具函数
- **table.lua**：表工具函数
- **string.lua**：字符串工具函数
- **math.lua**：数学工具函数
- **log.lua**：日志系统
- **save.lua**：谱面保存功能

### 数据流

```
用户输入 → 事件处理 → 业务逻辑 → 数据更新 → UI 渲染
    ↑           ↓           ↓           ↓           ↓
    └─────────反馈─────────────────────────────────────┘
```

### 生命周期

```
启动 → 加载 → 更新 → 绘制 → 事件处理 → 退出
  ↑       ↓       ↓       ↓       ↓       ↓
  └─────循环──────────────────────────────┘
```

---

## 模块详解

### 1. 房间系统 (room.lua)

房间系统实现了 object/container/group/room 四层架构：

```lua
-- 基础对象
object = {}

-- 容器（可包含子对象和子组）
container = object:new('')

-- 容器变体（用于组合多个对象）
group = container:new('')

-- 场景管理器（支持多场景切换）
room = object:new('')
```

room/group 的 `addObject(obj, layer)`、`addGroup(group, layer)`、`addRoom(room, layer)` 支持指定层。子内容统一按层执行；省略层时默认最高层，同层保持导入顺序。通过 `getLayer`/`setLayer` 查询和修改挂载层。

#### 生命周期方法
- `load()`：加载场景
- `update(dt)`：每帧更新
- `draw()`：绘制场景
- `keypressed(key)`：键盘按下
- `keyreleased(key)`：键盘释放
- `mousepressed(x, y, button)`：鼠标按下
- `mousereleased(x, y, button)`：鼠标释放
- `wheelmoved(x, y)`：鼠标滚轮
- `textinput(input)`：文本输入
- `resize(w, h)`：窗口大小变化
- `quit()`：退出

### 2. 服务层 (services/)

#### ChartService（谱面数据服务）
```lua
-- 主要功能
ChartService:setChart(data)  -- 设置谱面数据
ChartService:load()          -- 加载谱面数据
ChartService:save(filename)  -- 保存谱面数据
ChartService:getNoteCount()  -- 获取音符数量
ChartService:getEventCount() -- 获取事件数量
ChartService:getNote(index)  -- 获取指定音符
ChartService:getEvent(index) -- 获取指定事件
```

#### CoordinateService（坐标转换服务）
```lua
-- 主要功能
CoordinateService:beatToY(beat)      -- 节拍转屏幕Y坐标
CoordinateService:yToBeat(y)         -- 屏幕Y坐标转节拍
CoordinateService:xToTrack(x)        -- 屏幕X坐标转轨道
CoordinateService:trackToX(track)    -- 轨道转屏幕X坐标
```

#### AudioService（音频服务）
```lua
-- 主要功能
AudioService:loadMusic(filename)     -- 加载音乐文件
AudioService:play()                  -- 播放音乐
AudioService:pause()                 -- 暂停音乐
AudioService:stop()                  -- 停止音乐
AudioService:getWaveform()           -- 获取波形数据
AudioService:getFFT()                -- 获取FFT数据
```

### 3. 插件系统

插件入口由 `plugins/init.lua` 在 `love.load` 中自动发现；`src/utils/plugin.lua` 负责注册、目标容器挂载、数据钩子和卸载。此时场景、服务、设置、Nui 和日志目录均已就绪。

每个插件在自己的入口中声明 `name`、`target` 和可选的 `layer`，返回描述表即可。描述表回调接收 `ctx`；复用 `object` 时对象方法接收 `self`。生命周期跟随目标 room/group 的分层分发。

完整接口、示例和限制见 [插件开发文档](plugins/README.md)。

---

## 开发流程

### 1. 添加新功能

#### 步骤 1：设计功能
- 确定功能需求
- 设计数据结构
- 设计用户界面

#### 步骤 2：实现核心逻辑
```lua
-- 在相应的模块中添加功能
function MyModule:newFunction()
    -- 实现逻辑
end
```

#### 步骤 3：集成到系统
```lua
-- 在场景或服务中调用
function edit:update(dt)
    MyModule:newFunction()
end
```

#### 步骤 4：添加 UI 支持
```lua
-- 在 UI 模块中添加界面
function MyModule:drawUI()
    if Nui:button("My Button") then
        self:newFunction()
    end
end
```

#### 步骤 5：测试和调试
- 功能测试
- 边界条件测试
- 性能测试

### 2. 修改现有功能

#### 步骤 1：理解现有代码
```lua
-- 阅读相关模块的代码
local ChartService = require("src.services.chartService")
```

#### 步骤 2：定位修改点
- 使用 IDE 的搜索功能
- 查看函数调用关系

#### 步骤 3：进行修改
- 保持代码风格一致
- 添加必要的注释
- 更新相关文档

#### 步骤 4：测试修改
- 确保修改不破坏现有功能
- 测试新功能

### 3. 修复 Bug

#### 步骤 1：重现问题
- 记录重现步骤
- 确定问题范围

#### 步骤 2：定位问题
```lua
-- 使用日志系统
log("Debug info:", variable)

-- 使用调试器
-- 设置断点，单步执行
```

#### 步骤 3：分析问题
- 检查数据流
- 检查逻辑错误
- 检查边界条件

#### 步骤 4：修复问题
- 编写修复代码
- 确保修复不引入新问题

#### 步骤 5：验证修复
- 测试修复效果
- 确保其他功能正常

---

## 插件开发

将插件保存为 `plugins/name.lua` 或 `plugins/name/init.lua`，无需编辑游戏源码或手动修改加载清单。启动时自动加载；改动后重启生效。

```lua
return {
    name = 'example',
    target = 'edit/play',
    layer = 85,
    keypressed = function(ctx, key)
        if key == 'f6' then
            messageBox:add('example')
        end
    end,
}
```

`layer` 从小到大执行，同层按导入顺序执行，省略时位于最高层。`target` 支持任意嵌套 room/group 的路径或对象引用。描述表函数使用 `function(ctx, ...)`，不要额外写隐式 `self`。

详见 [插件开发文档](plugins/README.md)，其中包含完整示例、容器路径表、核心层号、对象模式、数据钩子覆盖范围、禁用/卸载与资源访问。

---

## 调试与测试

### 1. 日志系统

```lua
-- 基本日志
log("普通信息")
log("调试信息:", variable)
log("错误信息:", error_message)

-- 日志文件位置
-- users/log/YYYY MM DD.log
```

### 2. 调试工具

#### LOVE2D 调试器
```lua
-- 在代码中设置断点
function love.update(dt)
    -- 设置断点
    if condition then
        love.event.quit()
    end
end
```

#### 打印调试
```lua
-- 打印变量
print("变量值:", variable)
print("表内容:", serpent.block(table))

-- 打印调用栈
print(debug.traceback())
```

### 3. 性能分析

```lua
-- 测量函数执行时间
local startTime = love.timer.getTime()
-- 执行代码
local endTime = love.timer.getTime()
local duration = endTime - startTime
log("执行时间:", duration)
```

### 4. 测试策略

#### 单元测试
```lua
-- 测试函数
function testTableCopy()
    local original = {1, 2, 3, nested = {4, 5}}
    local copy = table.copy(original)
    
    -- 验证复制正确
    assert(copy[1] == 1)
    assert(copy[2] == 2)
    assert(copy[3] == 3)
    assert(copy.nested[1] == 4)
    assert(copy.nested[2] == 5)
    
    -- 验证是深拷贝
    copy[1] = 10
    assert(original[1] == 1)
    
    print("table.copy 测试通过")
end
```

#### 集成测试
```lua
-- 测试完整流程
function testChartService()
    local ChartService = require("src.services.chartService")
    
    -- 创建测试数据
    local testData = {
        info = {song_name = "测试"},
        note = {},
        event = {},
        bpm_list = {{bpm = 120, beat = 0}}
    }
    
    -- 测试设置谱面
    ChartService:setChart(testData)
    assert(ChartService:getSongName() == "测试")
    
    -- 测试添加音符
    local note = {track = 1, beat = 0, type = "note"}
    ChartService:addNote(note)
    assert(ChartService:getNoteCount() == 1)
    
    print("ChartService 测试通过")
end
```

---

## 性能优化

### 1. 常见性能问题

#### 频繁的表创建
```lua
-- 不好的做法
function update(dt)
    local temp = {}  -- 每帧创建新表
    -- 使用 temp
end

-- 好的做法
local temp = {}  -- 预分配
function update(dt)
    -- 重用 temp
end
```

#### 频繁的字符串操作
```lua
-- 不好的做法
function draw()
    local text = "分数: " .. score .. " 连击: " .. combo
    love.graphics.print(text, 10, 10)
end

-- 好的做法
local textBuffer = {}
function draw()
    textBuffer[1] = "分数: "
    textBuffer[2] = score
    textBuffer[3] = " 连击: "
    textBuffer[4] = combo
    love.graphics.print(table.concat(textBuffer), 10, 10)
end
```

### 2. 优化技巧

#### 使用局部变量
```lua
-- 全局变量访问慢
function update(dt)
    local x = love.mouse.getX()  -- 全局函数调用
end

-- 局部变量访问快
local getX = love.mouse.getX
function update(dt)
    local x = getX()  -- 局部函数调用
end
```

#### 避免重复计算
```lua
-- 不好的做法
function draw()
    local scale = math.min(windowWidth / 1600, windowHeight / 900)
    -- 使用 scale
end

-- 好的做法
local scale = 1
function resize(w, h)
    scale = math.min(w / 1600, h / 900)
end

function draw()
    -- 使用 scale
end
```

#### 使用对象池
```lua
-- 对象池实现
local NotePool = {}
NotePool.pool = {}
NotePool.active = {}

function NotePool:create()
    local note
    if #self.pool > 0 then
        note = table.remove(self.pool)
    else
        note = Note.new()
    end
    table.insert(self.active, note)
    return note
end

function NotePool:release(note)
    for i, n in ipairs(self.active) do
        if n == note then
            table.remove(self.active, i)
            table.insert(self.pool, note)
            return
        end
    end
end
```

### 3. 性能监控

```lua
-- 性能监控器
local PerformanceMonitor = {}
PerformanceMonitor.fps = 0
PerformanceMonitor.frameTime = 0
PerformanceMonitor.memoryUsage = 0

function PerformanceMonitor:update(dt)
    self.frameTime = dt
    self.fps = 1 / dt
    self.memoryUsage = collectgarbage("count")
end

function PerformanceMonitor:draw()
    love.graphics.print(string.format("FPS: %.1f", self.fps), 10, 10)
    love.graphics.print(string.format("帧时间: %.3f ms", self.frameTime * 1000), 10, 30)
    love.graphics.print(string.format("内存: %.1f MB", self.memoryUsage / 1024), 10, 50)
end
```

---

## 常见问题

### 1. 中文输入法问题

**问题**：在某些系统上中文输入法无法正常工作

**解决方案**：
- 使用修改版的 SDL2.dll
- 确保系统输入法支持 SDL2
- 尝试切换输入法

### 2. 音频播放问题

**问题**：音频播放卡顿或无法播放

**解决方案**：
- 检查音频文件格式
- 调整音频缓冲区大小
- 检查系统音频驱动

### 3. 内存泄漏问题

**问题**：程序运行时间长后内存占用持续增加

**解决方案**：
- 检查是否有未释放的资源
- 使用对象池减少对象创建
- 定期调用 `collectgarbage("collect")`

### 4. 性能问题

**问题**：程序运行缓慢

**解决方案**：
- 使用性能分析工具定位瓶颈
- 优化频繁调用的函数
- 减少不必要的计算

### 5. 跨平台兼容性问题

**问题**：在不同平台上表现不一致

**解决方案**：
- 使用平台特定的代码路径
- 测试所有目标平台
- 处理平台差异

---

## 贡献指南

### 1. 代码风格

- 使用 4 空格缩进
- 使用小写字母和下划线命名变量
- 使用驼峰命名法命名函数
- 添加详细的注释
- 保持函数简短（不超过 50 行）

### 2. 提交规范

```
<类型>(<范围>): <描述>

[可选正文]

[可选脚注]
```

类型：
- `feat`：新功能
- `fix`：修复 bug
- `docs`：文档更新
- `style`：代码格式调整
- `refactor`：代码重构
- `test`：测试相关
- `chore`：构建/工具相关

### 3. Pull Request 流程

1. Fork 项目
2. 创建功能分支
3. 提交更改
4. 推送到分支
5. 创建 Pull Request
6. 等待代码审查

### 4. 问题报告

使用 GitHub Issues 报告问题，包含：
- 问题描述
- 重现步骤
- 预期行为
- 实际行为
- 环境信息
- 截图或日志

---

## 资源链接

- [LOVE2D 官网](https://love2d.org/)
- [LOVE2D 文档](https://love2d.org/wiki)
- [Lua 5.1 参考手册](https://www.lua.org/manual/5.1/)
- [Nuklear GUI](https://github.com/keharriso/love-nuklear)
- [Moonshine 后处理](https://github.com/vrld/moonshine)

---

## 版本历史

### v0.5.0c
- 完善插件系统
- 优化性能
- 修复已知 bug

### v0.4.0
- 添加国际化支持
- 优化 UI 界面
- 添加音频分析功能

### v0.3.0
- 添加插件系统
- 优化数据结构
- 添加更多编辑工具

### v0.2.0
- 添加多轨道支持
- 优化事件系统
- 添加自动保存

### v0.1.0
- 初始版本
- 基本编辑功能
- 谱面保存/加载

---

## 许可证

MIT License

Copyright (c) 2025 qwwshs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
