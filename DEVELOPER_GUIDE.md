# Dakumi Editor 开发者指南

本文按当前源码整理。运行环境与检查入口见 [开发入门](DEVELOPMENT.md)，完整插件说明见 [插件开发](plugins/README.md)。

## 项目架构

依赖从界面 / 插件向下流动：

```text
界面、场景与插件：src/objects、src/rooms、plugins
                         ↓
服务：src/services（谱面、音频、坐标、主题等）
                         ↓
数据实体：src/models（Note、Event）
                         ↓
基础工具与第三方库：src/utils
```

**分层规则：下层模块不可引用上层模块，也不能以延迟 require 绕过。** 需要向上访问业务能力时，通过装配入口传入接口。依赖层次与 room/group 的绘制层是两回事。

`isRequire.lua` 加载工具、模型和服务，注入 event/note/track 所需的谱面与坐标接口，再创建界面和场景；`main.lua` 初始化 UI、主题及插件上下文，`love.load` 自动发现插件。`src/utils/event.lua`、`note.lua`、`track.lua` 不直接 require ChartService。服务使用 `src/models/Note.lua` / `Event.lua`；`src/objects/` 的同名文件只向下转发，兼容旧路径。

旧界面仍有 `settings`、`play`、`sidebar`、`track` 等运行时单例；新模块不要继续增加全局耦合。谱面、索引、播放时钟和音频资源已有私有服务状态。

## 谱面格式

磁盘文件是 JSON。下面用 Lua 表展示字段，便于加中文注释，不能直接当作 JSON 保存。

```lua
{
    version = 1,                         -- 谱面格式版本，不是软件版本
    info = {song_name = '', chart_name = '', chartor = '', artist = ''},
    offset = 0,                          -- 毫秒；音频位置 = 谱面秒数 - offset / 1000
    preference = {x_offset = 0, event_scale = 100}, -- 默认坐标以 100 为一整份
    bpm_list = {{beat = {0, 0, 1}, bpm = 120, linear_ramp = 0}},
    note = {},                           -- note / wipe / hold
    event = {},                          -- x / w / lpos / rpos / event_group
    custom_trans = {},                   -- 名称 -> Lua 函数体字符串
    event_groups = {},                   -- 名称 -> {name, event = {...}}
    track = {},                          -- 轨道定义，键为字符串编号，如 '1'
    effect = {},                         -- 演示效果
}
```

节拍格式为 `{整数, 分子, 分母}`，分母须大于 0。`{2, 1, 4}` 表示 2.25 拍。BPM 列表按节拍排序，`linear_ramp = 1` 表示向下一项线性变速。

音符具有 `type/track/beat`；hold 另有 `beat2/note_head/wipe_head`，`fake` 为 0 或 1。普通事件具有 `type/track/beat/beat2/from/to/trans`，终点晚于起点。

```lua
trans = {
    type = 'bezier',             -- 或 'easings' / 'custom'
    trans = {0.25, 0.1, 0.25, 1}, -- 两个内部控制点的 x、y；端点固定为 (0,0)、(1,1)
    easings = 1,                  -- 缓动函数索引，使用 easings 时生效
}
```

轨道字段包括 `name/w0thenShow/parent/scale_with_parent/zindex/boundary_type/left_boundary/right_boundary/left_reference/right_reference`。边界模式为 `'nil'`、`'pos'` 或 `'track'`；`pos` 填坐标，`track` 填轨道编号并选参考属性。是否启用看模式，坐标 0 本身是合法边界。

`extra_chart` 是服务私有的按轨道索引，包含 note、x、w、lpos、rpos 和 event_group 列表。使用服务查询，不直接取内部表。

### 事件组格式与计算

```lua
event_groups = {
    move = {
        name = 'move',           -- 与字典键相同
        event = {
            {type = 'x', beat = {0,0,1}, beat2 = {4,0,1}, from = 0, to = 100,
             trans = {type = 'easings', easings = 1}},
            {type = 'w', beat = {0,0,1}, beat2 = {4,0,1}, from = 20, to = 20,
             trans = {type = 'easings', easings = 1}},
        },                       -- 组内不保存轨道号，不支持嵌套组
    },
}
-- 引用放在普通 event 列表中：
event = {
    {type = 'event_group', track = 1, beat = {10,0,1}, beat2 = {18,0,1},
     event_group = 'move', from = 0, to = 100,
     flip_horizontally = 0, flip_vertically = 0},
}
```

实例时间进度 `p = clamp((拍 - 实例起点) / 实例时长, 0, 1)`。有效组取内部所有事件的最早起点 `g0` 和最晚终点 `g1`，时间翻转时 `p = 1 - p`，读取 `g0 + p * (g1 - g0)` 处的事件值。

位置类值归一化为 `(值 - x_offset) / event_scale`；w 为 `值 / event_scale`。水平翻转对 w 之外的结果取 `1 - 归一化值`，并交换 lpos/rpos 的目标属性。最后映射为 `from + (to - from) * 归一化值`。范围不强制截到 0～1，所以越界值仍可表达超出实例范围的动作。缺失或空组退化为 x 的线性变化，走替代分支时不应用组内翻转。

实例与同轨道其他普通事件 / 事件组的时间区间不能重叠，边界相接允许。通过 `canPlaceEvent` 和正常写入接口检查；不要绕过接口直接塞进内部列表。普通事件之间原有的放置检查仍由编辑工具负责。

组名为 1～128 字节的非空字符串，禁止纯空白、控制字符、斜杠及保留的元表键；不是可执行代码。组内事件要有有限数值、有效节拍和缓动配置。

## ChartService

兼容入口 `src/services/chartService.lua` 返回 `chartService/init.lua` 装配的同一个服务。所有子模块共享私有状态，不是多个独立谱面。

| 文件 | 职责 |
| --- | --- |
| `init.lua` | 状态与依赖装配 |
| `index.lua` | 轨道索引与实体登记 |
| `transactions.lua` | 事务、提交及失败回滚 |
| `lifecycle.lua` | 替换、迁移、加载、编码与保存 |
| `event_groups.lua` | 组定义、独立编辑和范围检查 |
| `custom_trans.lua` | 自定义过渡定义读写、验证与字段事务 |
| `entities.lua` | 音符与事件增删、排序 |
| `fields.lua` | 信息、偏好、轨道与 BPM 字段 |
| `timing.lua` | BPM 与拍 / 秒换算 |

```lua
local chart = require('src.services.chartService')
chart:setChart(data)                      -- 深拷贝并补默认字段，替换谱面
chart:load()                              -- 内存迁移、模型转换与索引构建；不写盘
local ok, err = chart:save('chart.json')   -- 保存当前选中谱面；检查返回值
chart:save('chart.json.auto')             -- 自动保存副本
chart:encodeJson()                        -- 当前谱面 JSON
chart:getNoteCount(); chart:getNote(i)     -- Note 实体
chart:getEventCount(); chart:getEvent(i)   -- Event 实体
chart:getBpmCount(); chart:getBpm(i)        -- BPM 项
chart:hasTrack(trackId)
chart:getTrackEventCount(trackId, kind)
chart:getTrackEvent(trackId, kind, i)
chart:getOffset(); chart:setOffset(ms)
chart:getInfoField(field); chart:setInfoField(field, value)
chart:getPreferenceField(field); chart:setPreferenceField(field, value)
chart:getTrackField(id, field); chart:setTrackField(id, field, value)
chart:ensureTrack(id)                     -- 显式创建；读取缺失字段不会创建轨道
chart:setBpmList(list); chart:sortBpmList()
chart:toBeat(seconds); chart:toTime(beatValue)
```

`getNote/getEvent` 返回已登记实体，修改要用 setter。其内部数据不是公开写入接口；读取快照用 `copy/toTable`。缺失索引与轨道定义是不同概念，定义存在性可用 `hasTrackData`。

### 事务、撤销与失败

```lua
local Note = require('src.models.Note')
chart:change('history.add_note', function()
    chart:add(Note.new({type = 'note', track = 1, beat = {4,0,1}}))
end)
-- 修改已有实体也自动登记，不只记录增删：
chart:change('移动音符', function()
    chart:getNote(1):setBeat({8,0,1})
end)
```

`change(actionKey, fn)` 把本次写入合成一条操作，已有事务时归入外层。无实际变化不提交历史；执行异常会恢复记录过的实体、字段与索引，并继续抛出错误。

跨帧拖拽使用 `beginChange()` 与 `commitChange(actionKey)` 配对；批量增删可用 `push()` 与 `pop(actionKey)`，期间数据即时生效。`abortChange()` 只丢弃记录，不负责恢复数据，不能当作回滚按钮。`suspend(fn)` 仅用于内部恢复等豁免场景；正常插件编辑不要用它跳过记录。提交说明由发起方传入 i18n 键或可读文字，内置说明在 `i18n/zh-CN.lua`、`i18n/en.lua`。

`plugins/redo.lua` 维护历史树；撤销后创建新操作会保留原分支。操作历史可在“当前分支”和“所有分支”间切换，跳转通过撤销 / 重做恢复到目标节点。涉及对象的时间范围取修改前后所有起点 / 终点的最小与最大值。切换谱面清空；事件组编辑使用独立历史，退出后恢复主谱面历史并记录组变更。

手动保存失败返回 `false, error`；已经成功编码 JSON 时，系统弹窗提供复制到剪贴板的补救选项。自动保存失败仅记日志。调用方只有保存成功才显示成功消息或播放提示音。

### 事件组接口

```lua
chart:getEventGroupNames()                    -- 排序后的名称列表
chart:getEventGroup(name)                     -- 独立快照
chart:putEventGroup(name, definition, oldName, actionKey) -- 新建 / 更新 / 改名
chart:deleteEventGroup(name)
chart:beginEventGroupEdit(name)
chart:isEditingEventGroup()                   -- 当前名称或 nil
chart:syncEventGroupEdit()                    -- 保存前同步
chart:finishEventGroupEdit()
chart:canPlaceEvent(candidate, ignored)
```

独立编辑暂时切换服务的当前谱面与索引，原谱面保留。不要在插件里缓存跨换谱、跨撤销的实体引用而不更新。

## 事件通知

`src/utils/eventBus.lua` 提供同步通知：`on(name, fn)` 返回退订函数，`off/emit/count` 用于管理与发送。单个订阅回调错误被隔离并记录，不阻断其余回调。总栈发布顺序按订阅顺序，不按插件绘制层重排。

插件通常订阅 `ctx.eventBus`：

| 通知 | 用途 |
| --- | --- |
| `chart:changed` | 提交、撤销 / 重做、换谱、加载及事件组上下文变更后的完整读取 |
| `chart:mutated` | 实际写入后的实时预览；事务可能尚未完成 |
| `chart:committed` | 操作记录及说明，供撤销插件接收 |
| `chart:replaced` | 换谱时清理缓存与历史 |
| `chart:group_edit_begin/end` | 挂起 / 恢复事件组相关状态 |
| `audio:loaded/decoded` | 换歌 / 分析数据就绪 |
| `audio:playing_changed/error` | 播放状态 / 加载或解码错误 |

`chart:changed` 的参数含 `kind`，有操作时含 `operation/actionKey`，组变更可能含 `group`。`replace` 在 `load` 之前，需要实体和索引时等待 `load`。失败回滚会发 `kind='rollback'`。`chart:mutated` 按具体写入发送，撤销 / 重做不逐项重放它；完整变化种类和订阅示例见 [插件文档](plugins/README.md#7-数据钩子与谱面操作)。

旧 `onNoteAdd/onNoteDelete/onEventAdd/onEventDelete` 是插件管理器钩子，只覆盖普通 `add/delete`，不能替代所有谱面修改通知。卸载插件必须退订，回调中无条件再次改同一数据可能造成循环。

## AudioService 与坐标

AudioService 私有持有 Source、SoundData、时间、播放状态、速度、音量、效果与解码任务，不代理旧全局。应用入口注入谱面、事件总栈与 LÖVE 后端；`AudioService.new(options)` 可创建隔离测试实例。

```lua
local audio = require('src.services.audioService')
audio:load(path, {preview = true})           -- 菜单预览并后台解码
audio:prepareEditor()                       -- 准备分析数据、暂停并定位到谱面起点
audio:pause(); audio:resume(); audio:stop()  -- stop 同时将位置归零
audio:seek(seconds, {pause = true})
audio:setCurrentBeat(beatValue)
audio:setRate(1); audio:setVolume(0.5)
audio:setEffect(name, parameters)           -- false 关闭效果
audio:getCurrentTime(); audio:getAudioTime()
audio:getCurrentBeat(); audio:getAllBeat()
audio:getDuration(); audio:getRawDuration()
audio:getSoundData(); audio:isLoading(); audio:isPlaying()
audio:unload()
```

`getCurrentTime` 是谱面秒数；音频秒数由 offset 换算，当前 / 总节拍由 BPM 表推导。`update(dt)` 每帧只由应用推进一次。原生 `getSource()` 供兼容读取，控制播放仍通过服务。`music/music_data/music_play/time` 及 `beat.nowbeat/allbeat` 已移除。详细时间边界、异步数据和资源释放见 [音频服务](readme/音频服务.md)。

CoordinateService 提供 `toY/yToBeat`、`trackToScreen/screenToTrackX`、`getEventValue` 等转换。每拍像素随 `denom.scale * 100` 变化，当前拍来自音频服务；offset 单位是毫秒，其他音频时间是秒。

## 输入、容器与执行顺序

`src/services/inputRouter.lua` 统一缩放 / 黑边坐标、按下与释放、UI 捕获和改键弹窗输入；窗口失焦清理状态。空透明 Nuklear 窗口也可能抢滚轮，不要用整片窗口包住编辑区。进度条与普通编辑滚轮由场景处理，侧栏滚动仅在对应区域补偿。详见 [输入与依赖](readme/输入与依赖.md)。

`object/container/group/room` 在 `src/utils/room.lua`。`addObject/addGroup/addRoom(child, layer)` 统一排序：数字从小到大，同层按导入顺序，省略层号为 `math.huge`；非活动 room 不执行。`setLayer/getLayer` 修改或查询挂载层，每个容器独立排序。

自定义方法通过 `self('update', dt)` 等转发子内容，转发位置决定执行时机；未定义的方法自动下传。一次分发用快照，新对象下次执行，删除的对象立即跳过，改层下次生效。容器层不能拆分父方法自身的绘制，也不能让插件越过全局最后绘制的 Nuklear。

当前编辑场景为 play 10、demo 20、editTool 30、tabs 40、sidebar 50。希望高于标签页绘制的插件可挂 `target='edit', layer=45`。任意路径查找用 `root:findContainer('edit/sidebar/event')`；完整挂载规则见 [插件文档](plugins/README.md#4-层与执行顺序)。

## 主题、键位与安全输入

ThemeService 读取 `users/ui/theme.yml`，分别应用 dark / light 配色、图标颜色、判定线与音符九宫格。默认颜色位于 `config/colors/`，UI 布局位于 `config/layouts/`。主题配置用英文键，说明和行尾注释用中文；完整可复制例子见 [主题说明](readme/theme.md)。

默认快捷键在 `src/objects/meta.lua` 的 `meta_key`，用户覆盖在 `users/key.json`。动作名必须使用实际字段，例如：

```json
{
  "play": ["space"],
  "undo": ["ctrl", "z"],
  "redoing": ["ctrl", "y"],
  "placeEventGroup": ["t"]
}
```

设置中的改键入口录制组合键，松开后确认并保存。业务通过 `input('undo')` 等查询，不绕过弹窗输入捕获。

`safeInput` 解析受限算式和数据表，不执行任意 Lua。用户公式可用基本算术、常用数学函数、当前轨道值与 `r()`；`function x^2` 是批量变换的算式前缀。旧 d3、语言及贝塞尔预设仅接受数据，不能指导用户写系统命令或可执行 Lua。

## 服务索引与自动检查

完整模块职责与接口见 [服务索引](readme/服务索引.md)。检查入口、CI 与自动保存保留策略见 [测试与备份](readme/测试与备份.md)。

## 元件时间偏移

Note（note/wipe/hold）、Event（含 event_group 实例）支持可选正数字段 `time_offset`，单位毫秒。未设置时省略，读取返回 0；setter 只接受有限正数或用于清除的 nil。`getBeat/getBeat2` 是基础节拍表，`getBeatValue/getBeat2Value` 是偏移后的实际节拍数。不要将实际节拍写回基础字段而保留同一偏移，否则会重复移动。

`src/utils/timeOffset.lua` 接收 ChartService 注入的时间接口，在秒数上相加再换回节拍；模型仅依赖该工具。偏移与 BPM 变化需重排实际时间索引；事件组内部快照和归一化也包含偏移。用户操作与完整接口见[偏移时值](readme/time_offset.md)，回归入口为 `tests/time_offset.lua` 及 `tests/editor_input_love`。


### 自定义 Lua 过渡

`custom_trans` 是谱面级 `{name = source}` 字典；对象引用采用 `trans={type='custom',custom=name}`。`src/utils/customTransition.lua` 为叶子执行器，仅依赖 Lua/LuaJIT 原生接口；ChartService 在装配时注入脚本读取函数，工具不反向 require 服务。

- `ChartService:getCustomTrans(name)` / `getCustomTransNames()`：读取定义，事件组编辑时读取主谱面。
- `putCustomTrans(name, source)` / `deleteCustomTrans(name)`：验证并通过事务写入字段，触发 `chart:mutated` 和提交事件，支持撤销重做。
- `customTransition.evaluate(name,t)`：输入夹到 0–1，返回有限数值；失败时返回 t 和错误原因。
- `customTransition.validate(source)`：编译并在多个 t 下检查；保存不会执行文件、模块或系统操作。

函数体在只读环境中运行，仅提供数学方法和少量基础函数。用户函数关闭 JIT 后，通过调试计数钩子限制指令并检查新增内存，退出时还原原钩子和字符串元表。脚本按名称与内容缓存，出错后停止执行；编辑脚本内容后重新编译。原生 `bezier` / `easings` 和编辑器其他模块继续使用原有 JIT。

普通事件、组内事件与 effect 通过同一执行器插值；effect 积分缓存监听谱面变化，因此修改脚本也会重建位置计算。回归见 `tests/custom_trans.lua`、`tests/direct_event_editing.lua` 和 `tests/editor_input_love`。用户用法见[自定义过渡](readme/custom_trans.md)。
