# Dakumi 插件开发

适用环境：LÖVE 11.4、LuaJIT（Lua 5.1 语义）。插件入口、目标容器和执行层都在插件目录内声明，无需修改 `main.lua`、`isRequire.lua` 或场景文件。

## 1. 安装与自动加载

支持两种形式：

```text
plugins/
├── init.lua                 # 编辑器提供的自动加载器
├── note_counter.lua         # 单文件插件
└── my_tool/
    ├── init.lua             # 文件夹插件的唯一入口
    ├── helper.lua           # 辅助模块，不单独加载
    └── icon.png
```

启动时自动扫描顶层 `.lua` 文件和子目录的 `init.lua`，按入口相对路径的字典顺序加载。跳过顶层 `init.lua`、以下划线开头的文件/目录及没有入口的目录。插件文件返回一个描述表，由加载器统一注册，不要在入口中再调用 `register`。

源码运行时扫描游戏源目录中的 `plugins/`；运行 `.love` 包或融合后的程序时，同时扫描程序基础目录中的外部 `plugins/` 和包内目录。相同相对入口路径优先使用外部版本。所有插件的 `name` 必须唯一：不同入口使用同名 `name` 会被拒绝并记录日志。

新增、删除和编辑文件后重启编辑器生效。当前没有热重载。描述表的 `enabled = false` 可以禁用注册，但入口文件本身仍会执行；需要完全不执行时，可把入口文件或插件目录改成以下划线开头的名称。

插件语法错误、入口异常和初始化异常会记录到日志，其他插件继续加载。运行时的插件回调错误也会记录并隔离。

## 2. 可直接使用的单文件插件

将以下代码保存为 `plugins/note_counter.lua`，启动后进入编辑界面，按 F6 切换音符数量显示：

```lua
local visible = true

return {
    name = 'note_counter',
    version = '1.0.0',
    description = '在编辑界面显示音符数量',
    target = 'edit',
    layer = 45,

    keypressed = function(ctx, key)
        if key == 'f6' then visible = not visible end
    end,

    draw = function(ctx)
        if not visible then return end
        love.graphics.push('all')
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print('Notes: ' .. ctx.chart:getNoteCount(), 24, 210)
        love.graphics.pop()
    end,
}
```

描述表中的函数使用 **`function(ctx, ...)`**，第一个参数是上下文。不要写成 `function plugin:update(ctx, dt)`，那样会多出一个 `self` 参数。

## 3. 选择任意 room/group

`target` 可以是从根场景开始的路径，也可以直接是一个 room/group 对象。路径可省略开头的 `main/`。省略 `target` 时挂载到根容器 `main`。

| target | 位置 |
|---|---|
| `main` | 根容器，所有场景均参与分发 |
| `start` | 启动画面 |
| `menu` | 选曲和选谱菜单 |
| `edit` | 整个编辑场景 |
| `edit/play` | 编辑区和轨道预览 |
| `edit/demo` | 演示模式 |
| `edit/editTool` | 编辑工具栏 |
| `edit/tabs` | 标签页管理器 |
| `edit/sidebar` | 侧边栏 |
| `edit/sidebar/event` | 单事件属性 group |
| `edit/sidebar/track edit` | 轨道属性 group，名称中的空格保留 |

路径逐级查询 `rooms` 和 `groups`，所以新增的嵌套 room/group 也可定位。只写 `play` 不会进行全局同名搜索，应写 `edit/play`。

直接引用容器时可写 `target = play`，也可以使用 `ctx.root:findContainer('edit/play')` 查找。插件也可以在 `init(ctx)` 中创建自己的 group，再挂到已有容器；在 `destroy(ctx)` 中删除自己添加的 group。

侧边栏现有的「操作历史」「均衡器」「takana」就是这种插件：分别位于 `plugins/operationHistory.lua`、`plugins/equalizer/init.lua`、`plugins/takana/init.lua`。它们在 `init(ctx)` 中把页面 group 加到 `edit/sidebar`，并把导航对象加到侧边栏首页的 `nil` group；在 `destroy(ctx)` 中移除。首页会在「设置」下方调用这些导航对象的 `Nui` 方法。导航对象可用层号调整顺序：目前操作历史为 10、均衡器为 20、takana 为 30。

插件沿用目标容器的事件分发规则。例如 `edit/play` 的按键受鼠标区域检查影响，`edit/demo` 的更新和绘制仅在演示模式打开时执行。侧边栏的子 group 原本每帧都会收到 `update`，并非只分发给当前属性页；只想在某页运行时，要自行判断 `sidebar:room_type('event')`。

注册到目标容器不会自动调用目标本身的 `load`，也不会自动切换场景。插件的 `init` 负责一次性初始化，`load` 跟随目标场景的加载转发。

## 4. 层与执行顺序

room/group 的子对象、子 group、活动子 room 使用同一套层顺序：

1. 数字层号从小到大执行，支持负数和小数。
2. 同层按导入顺序执行。
3. 不指定层时放在最高层 `container.TOP_LAYER`，其值为 `math.huge`，在所有有限数字层之后执行。同属最高层的对象仍保持导入顺序。
4. 每个容器独立排序。父容器中的整个 group 占一个位置，然后在 group 内执行它的子对象。
5. 非活动子 room 不参与分发。

绘制时后执行的内容通常会覆盖先执行的内容。层顺序同时适用于 `update`、输入事件和其他被转发的方法。

```lua
local panel = group:new('panel')
local background = {draw = function(self) end}
local overlay = {draw = function(self) end}

panel:addObject(background, -10)
panel:addObject(overlay)              -- 最高层
edit:addGroup(panel, 35)

panel:setLayer(background, 5)         -- 修改挂载层，不改变同层的原始导入顺序
print(panel:getLayer(background))     -- 5
panel:setLayer(background)            -- 移到最高层
edit:deleteGroup(panel)
```

接口：`addObject(object, layer)`、`addGroup(group, layer)`、`addRoom(room, layer)`，均支持省略 `layer`。删除接口支持名称或对象引用。兼容原有 `objects`、`groups`、`getObject`、`getGroup` 等接口，但请通过增删接口修改列表，避免绕过层索引。

`container.layers` 是当前层表，结构为 `[layer] = {挂载记录, ...}`，每条记录含 `child/kind/layer/order/alive`。它用于检查状态；修改请使用 `setLayer`。层属于父容器中的挂载关系，同一个对象在两个不同容器中可以有不同层。

一次分发使用顺序快照。回调中新挂载的对象从下一次分发开始执行；被删除的对象在当前分发剩余部分立即跳过；修改层号在下一次分发中生效。

自定义 room/group 方法内用 `self('update', dt)`、`self('draw')` 等转发子内容，具体转发位置决定子内容在该方法内部的执行时机。未定义某个方法的容器会自动向下转发。层控制容器内部的子内容顺序，不拆分父方法自身的代码。

编辑场景的默认层：

| 容器 | 子内容与层号 |
|---|---|
| `main` | 活动场景 0 |
| `edit` | play 10、demo 20、editTool 30、tabs 40、sidebar 50 |
| `menu` | select_music 10、select_chart 20、fft 30 |
| `edit/play` | note 10、event 20、demoPlay 30、demoInEdit 40、denomPlay 50、demoNowX 60、slider 80、redo 90、alt 100、ctrl 110、hit 120、directEventEditing 130 |

例如 `target='edit/play', layer=85` 在 slider 之后、redo 之前执行；要在整个标签页绘制之后执行，可选择 `target='edit', layer=45`。

## 5. 上下文和回调

| ctx 字段 | 内容 |
|---|---|
| `root` | 根 room，通过 `findContainer` 查找容器 |
| `chart` | ChartService：谱面读写、索引查询 |
| `coord` | CoordinateService：坐标与节拍转换 |
| `audio` | AudioService：加载、播放、暂停、定位、速度、音量及只读音频数据 |
| `beat` | 节拍模块 |
| `settings` | 当前全局设置表 |
| `i18n` | 国际化对象 |
| `ui` | Nuklear 实例 Nui |
| `input` | 快捷键查询对象 |
| `eventBus` | 谱面和音频变化的发布 / 订阅接口 |
| `WINDOW` / `PATH` | 窗口与路径配置 |

这些字段在插件开始注册时已就绪。谱面此时可能尚未加载，不要在 `init` 中假设存在音符、事件或音乐。

音频操作统一使用 `ctx.audio`。读取播放位置用 `getCurrentTime()/getCurrentBeat()`，暂停用 `pause()`，定位用 `seek(seconds, {pause=true})`，读取波形数据用 `getSoundData()`。不要再使用已移除的 `music/music_data/music_play/time` 全局或 `ctx.beat.nowbeat/allbeat`，也不要在插件中再次推进播放时钟或直接控制音频源。时长和总节拍由资源、offset 和 BPM 表推导，不再提供独立的时长/总节拍写入接口。

插件可通过 `ctx.eventBus:on('audio:decoded', callback)` 获知分析数据就绪，通过 `audio:loaded`、`audio:playing_changed`、`audio:error` 读取换歌、播放状态和错误通知；注销时调用返回的退订函数。详细说明见 [音频服务](../readme/音频服务.md)。

描述表支持：

```lua
init = function(ctx) end,                    -- 注册时一次
destroy = function(ctx) end,                 -- 注销时一次
load = function(ctx, ...) end,               -- 目标容器加载时
update = function(ctx, dt) end,
draw = function(ctx) end,
keypressed = function(ctx, key, ...) end,
keyreleased = function(ctx, key, ...) end,
mousepressed = function(ctx, x, y, button, ...) end,
mousereleased = function(ctx, x, y, button, ...) end,
wheelmoved = function(ctx, x, y) end,
textinput = function(ctx, text) end,
resize = function(ctx, w, h) end,
quit = function(ctx) end,
```

其他方法也可以定义，目标容器调用 `self('方法名', ...)` 时会分发。参数以目标实际转发的参数为准，一些现有场景只转发按键名称或鼠标坐标和按钮。返回值不用于阻止其他对象接收事件。

Nuklear 控件应在 `update` 内创建，使用 `ctx.ui`；自绘内容放在 `draw`。`windowEnd` 必须与 `windowBegin` 配对，即使 `windowBegin` 返回 false 也要调用。

## 6. 复用现有对象

已有 `object:new` 模块可以保留冒号方法，只需附加 `plugin` 注册信息：

```lua
local tool = object:new('my_tool')

function tool:update(dt)
    -- self 是 tool，参数不额外包含 ctx
end

tool.plugin = {
    name = 'my_tool',
    target = 'edit/play',
    layer = 85,
    init = function(ctx) tool.ctx = ctx end,
    destroy = function(ctx) tool.ctx = nil end,
}

return tool
```

也可以直接返回 `{name=..., target=..., layer=..., object=tool}`。提供 `object` 时，场景方法调用 `tool:method(...)`；描述表的 `init/destroy/hooks` 仍使用 `function(ctx, ...)`。两种方法不要混写。

内置插件使用 `export` 保留 `redo/ctrl/directEventEditing` 的旧全局引用；普通插件通常不需要导出全局变量。管理器通过代理挂载对象，`target:getObject(name)` 得到的是代理；原对象可通过 `PluginManager:getPlugin(name).object` 获取。

## 7. 数据钩子与谱面操作

```lua
hooks = {
    onNoteAdd = function(ctx, note) end,
    onNoteDelete = function(ctx, note) end,
    onEventAdd = function(ctx, event) end,
    onEventDelete = function(ctx, event) end,
}
```

数据钩子独立于场景是否可见，并按插件的层号、监听注册顺序执行。可以用 `PluginManager:emit('自定义事件', ...)` 广播自定义钩子。不要在增删钩子中无条件再次执行同一种增删操作，以免递归触发。

当前上述四种钩子由普通 `ChartService:add/delete` 触发。批量操作中若逐项调用 `add/delete`，仍会逐项触发；`push/pop` 自身没有整批钩子。撤销重做、直接 `addNote/deleteNote/addEvent/deleteEvent`、对象字段 setter、整谱加载不会触发这些钩子。它们还不是“所有谱面变化通知”。

要跟踪所有谱面变化，请订阅全局 `eventBus` 的 `chart:changed`。插件上下文提供 `ctx.eventBus`；`init` 中订阅、`destroy` 中退订。回调在谱面更新后同步运行，此时可用 `ctx.chart` 读取最新数据。一次批量编辑在提交时通知一次；无实际变化的提交不通知。事件组编辑会在切换上下文和同步组定义时通知。

```lua
local unsubscribe
return {
    name = 'chart_observer', target = 'main',
    init = function(ctx)
        unsubscribe = ctx.eventBus:on('chart:changed', function(change)
            print(change.kind, ctx.chart:getNoteCount(), ctx.chart:getEventCount())
            -- change.operation 含 add/del 的 note、event，以及修改前后的字段/事件组。
        end)
    end,
    destroy = function()
        if unsubscribe then unsubscribe(); unsubscribe = nil end
    end,
}
```

`change.kind` 可为 `commit`（新增、删除、修改和批量提交）、`undo`、`redo`、`replace`（换谱）、`load`（换谱后的对象和索引就绪）、`group_edit_begin`、`group_sync`、`group_edit_end`、`group_definitions`、`rollback`（失败事务恢复）。有操作记录时提供 `change.operation` 和 `change.actionKey`；事件组相关变化带 `change.group`。`replace` 会先于 `load`，需要读取 Note/Event 对象时以 `load` 为准。回调参数用于读取，不要修改操作记录；需要编辑谱面时使用 `ctx.chart` 的方法。

如果插件要在拖拽中逐次响应，则订阅 `chart:mutated`。它在每次实际写入后触发，`kind` 为 `note_added/deleted/updated`、`event_added/deleted/updated`、`field_updated`、`group_updated/deleted`、`group_definitions_updated` 或 `track_created`；根据情况提供 `entity`、`field`、`key`、`method`、`before`、`after`、`group`。这时一组批量操作可能仍在进行，适合刷新实时预览；需要完整、稳定的最终结果时订阅 `chart:changed`。撤销和重做只发一次 `chart:changed`，不会逐项重放 `chart:mutated`。同样要在插件卸载时退订。

插件修改音符或事件时使用对象的 `set...` 方法，修改谱面字段时使用 `ctx.chart` 的设置方法。不要直接写对象的 `_data`、BPM 列表或内部嵌套表；这样的写入无法可靠地发出通知，也无法保证撤销记录完整。

添加数据请创建 Note/Event 对象并调用服务：

```lua
local Note = require('src.models.Note')
ctx.chart:add(Note.new({type = 'note', track = 1, beat = {4, 0, 1}}), 'history.add_note')
```

批量操作优先使用 `ctx.chart:change('移动音符', function() ... end)`，异常会回滚已登记写入；也可使用 `push()` / `pop('移动音符')` 配对。跨帧拖拽用 `beginChange()` / `commitChange('移动音符')`。已登记实体的 setter 和谱面字段修改同样记录历史，一次事务形成一条记录。`abortChange()` 只清除记录，不会恢复数据。普通添加和删除也可在 `add(对象, '移动音符')`、`delete(对象, '移动音符')` 的第二个参数填写操作说明。说明由发起操作的代码提供。内置操作的说明已写在 `i18n/zh-CN.lua` 和 `i18n/en.lua`；外部插件可直接传可读文字，或在自己的 `init(ctx)` 中给 `ctx.i18n.language['zh-CN']`、`ctx.i18n.language['en']` 添加自己的翻译键，无需修改编辑器文件。若没有提交说明，会显示「其他操作」。空批量操作不会写入历史。

历史中的节拍范围由改动前后所有 note/event 的起点和终点决定；点击记录可跳到那一步。撤销后创建新操作会保留原来的历史分支；操作历史的“所有分支”可查看树杈图并跳转。切换谱面会清空历史，历史不写入谱面文件。需要直接写入快照的插件可调用 `redo:writeRevoke(操作表, nil, '移动音符')`。`ChartService:load()` 只在内存中迁移旧格式并建立索引，不写入文件。保存请显式调用 `ChartService:save()`。查询轨道字段不会创建轨道，缺失字段返回默认值；创建请使用 `ensureTrack()`，修改请使用 `setTrackField()`。

## 8. 管理与资源

```lua
PluginManager:getPluginNames()             -- 名称列表
PluginManager:getPlugin('my_tool')          -- 描述表
PluginManager:setLayer('my_tool', 95)       -- 修改挂载层和钩子顺序
PluginManager:unregister('my_tool')         -- 移除挂载、钩子并调用 destroy
```

需要运行时手动注册时才调用 `PluginManager:register(descriptor)`。它返回 `true`，或 `false, reason`。初始化失败会撤销管理器建立的挂载和钩子，并调用 `destroy`；插件自己创建的线程、资源和额外挂载，应在 `destroy` 中清理。

普通生命周期已由 room/group 分发，**不要再每帧调用 `PluginManager:callAll('update'/'draw', ...)`**，否则会重复执行。`callAll` 仅用于确有需要的手动广播；通常用自定义钩子更明确。

加载器会给描述表添加 `path`，表示该入口所在目录。文件夹插件可通过 `require('plugins.my_tool.helper')` 加载辅助模块。包内资源用 LÖVE 文件接口，外部绝对路径资源用 `nativefs.read/newFileData`。插件共享编辑器的 Lua 环境，没有独立沙箱。

排查加载问题时查看 `PluginManager.loadResult.loaded/errors` 和用户日志；确认入口没有以下划线开头、`name` 唯一、`target` 路径正确。只声明 `target` 和回调即可，无需手动向场景 `addObject`，否则可能重复执行。

## 9. 回归验证

项目根目录运行 `luajit tests/plugin_system.lua`，验证层顺序、嵌套容器、动态增删、插件注册/卸载、钩子及自动发现。测试使用内存文件系统替身，不读写用户谱面。真实编辑器输入与界面验证运行 `love tests/editor_input_love`，谱面通知运行 `love tests/chart_change_love`，音频资源验证运行 `love tests/audio_service_love`。`.zcode/` 中的探针是本地临时文件，不作为干净检出中的测试入口。

### 内置插件 UI 上下文

`directEventEditing`、`equalizer`、`takana` 和 `operationHistory` 均通过初始化收到的 `ctx.ui` 绘制，并通过 `ctx.i18n` 取得界面文字。对象式插件在 `.plugin.init(ctx)` 保存上下文，卸载时释放引用；声明 `function panel:Nui()` 仍是容器生命周期方法名，不代表读取全局 UI。辅助计算与其他历史业务依赖按现有接口使用。
