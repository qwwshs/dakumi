# 导入 Takana 谱面

在选曲界面拖入以下任一种文件：

JSON 会先按 Dakumi 原生谱面结构（`note`、`event`、`bpm_list` 及字段合法性）检测。通过时使用原生入口；不通过才交给导入插件审核。核心不检查 Takana 的 `components`，该格式判断只由 Takana 插件执行。

- `.t3pkg`：按 ZIP 读取工程，导入谱面、音频和可选封面。
- `.t3proj`：读取同目录的工程文件，文件名称遵循项目配置。
- `.json` / `.editing.json`：导入这张具体难度谱面，并尝试读取同目录的工程配置、偏好、歌曲信息、音频和封面。

工程和压缩包优先选择 `preference.yaml` 的 `difficulty`；该难度不存在时，从 Normal 到 Ravage 选择首张可用谱面。相同难度同时有编辑版和发布版时，优先 `.editing.json`。要导入其他难度，直接拖入对应 JSON。

所有元件的时间从 Takana 毫秒转换为拍，再吸附到最近的 **1/256 拍**。过短的 Hold 至少保留 1/256 拍；轨道结束后以零宽事件隐藏。轨道的横坐标按 Takana 游戏边界 `-4.5…4.5` 映射到 Dakumi 默认位置 `0…100`。

缺少 `preference.yaml` 或没有 `bpmList` 时，使用 **120 BPM**，不从歌曲信息中的 `bpmDisplay` 推断。`bpmList` 的键以毫秒解释。Takana 的歌曲偏移转换为 Dakumi 毫秒偏移时取反。

导入结果显式设置 `jump_unit = "ms"`、`jump_mode = "current"`。L/R 轨道使用 `start_lpos/start_rpos`，X/W 轨道使用 `start_x/start_w`；从第 0 拍开始的首段常值改存为初始属性，运动段仍保留 event。开始时间晚于第 0 拍的轨道初始为零宽，出现和结束隐藏的事件继续保留，避免提前显示或结束后残留。

支持 v2/v3 嵌套物件、Tap、Slide、Hold、假音符、L/R 和 X/W 轨道、缓动缩写与两种编号、三次贝塞尔和图层顺序。Takana 的 In/Out 与数学缓动方向相反，导入时对应转换。缺少内置对应项、截取后的曲线及超调贝塞尔保存为 `custom_trans` 定义。

事件直观编辑的右键“切换过渡类型”已支持 `bezier → easings → custom → bezier`；`custom` 是事件字段中的类型名，`custom_trans` 是谱面的自定义曲线定义表。“下一种/上一种曲线”可切换自定义定义，切换可撤销。

导入通过现有插件入口保存为 Dakumi JSON；源工程与源压缩包不修改。压缩包可在根目录放工程文件，也可外包一层目录；多工程压缩包需分别导入。导入一次只选择一张难度谱面。

格式参照 [TAKANA³ 使用说明书](https://blog.senolytics.top/2025/01/28/takana-cubic-instruction/)。自动验证见 `tests/takana_import.lua` 和 `tests/takana_import_love`。
