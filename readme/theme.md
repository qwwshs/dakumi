# 自定义主题

在游戏目录的 `users/ui` 文件夹里新建 `theme.yml`，就能修改界面颜色、图标颜色和音符图片的拉伸方式。如果还没有这个文件夹，先启动一次游戏。文件请保存为 UTF-8 编码；修改后重新启动游戏才会生效。

下面的例子可以直接复制。**配置名和值都用英文填写**；每行末尾由 `#` 开始的中文是说明，不会影响设置。`dark` 是夜间模式，`light` 是日间模式；游戏设置中的昼夜切换会自动选用对应的颜色。不想修改的部分可以删掉，剩余部分会使用游戏原来的颜色。

```yaml
colors: # 界面配色
  dark: # 夜间模式
    nuklear: # 文字、按钮等普通界面
      text: "#FFFFFF" # 文字颜色
      button: "#202830" # 按钮颜色
      button hover: "#34485C" # 鼠标移到按钮上时的颜色
    play: # 播放画面和编辑画面
      cyan: "#33C8E8" # 选中内容时的青色标记
      eventInDemo: # 演示画面中各类事件的颜色
        x: "#33C8E8" # X 事件的颜色
    tabs: # 标签页
      activeTab: "#3D4652" # 当前打开的标签颜色
      laneOn: ["#388CD9", "#2A6FB5", "#1E6F9F"] # 轨道按钮选中时，平常／鼠标移上／按下的颜色
    editor: # 编辑画面的背景
      canvas: "#20242B" # edit 区背景
      demo_background: "#080A0E" # demo 区背景
    background: "#080A0E" # 整个窗口的底色
  light: # 日间模式
    nuklear: # 文字、按钮等普通界面
      text: "#25282C" # 文字颜色
      button: "#E4E7EB" # 按钮颜色
    tabs: # 标签页
      info_background: "#E0E5EB" # 标签页下方信息框的底色
      info_border: "#AAB4C0" # 信息框的边框颜色
    editor: # 编辑画面的背景
      canvas: "#60666F" # edit 区背景
      demo_background: "#101318" # demo 区背景
    background: "#EEF0F5" # 整个窗口的底色

ui_images: # 工具栏图标颜色
  dark: # 夜间模式
    default: "#F7F7F7" # 所有图标的默认颜色
  light: # 日间模式
    default: "#25282C" # 所有图标的默认颜色
    save: "#2468AC" # 保存图标单独使用的颜色

judge_line: # 判定线颜色
  dark: # 夜间模式
    inner: "#00B3B3" # demo 区判定线内部
    outer: "#FFFFFF" # demo 区判定线外框
    edit: "#FFFFFF" # edit 区判定线
  light: # 日间模式
    inner: "#1E7997" # demo 区判定线内部
    outer: "#FFFFFF" # demo 区判定线外框
    edit: "#EEF4FF" # edit 区判定线

note_slices: # 音符图片的九宫格拉伸
  note: # 普通 note 图片
    left: 12 # 从原图左边量 12 像素，确定左切线
    right: 12 # 从原图右边量 12 像素，确定右切线
    top: 4 # 从原图上边量 4 像素，确定上切线
    bottom: 4 # 从原图下边量 4 像素，确定下切线
    scale_x: center # 横向选择中间缩放，左右两边保持原宽度
    scale_y: center # 纵向选择中间缩放，上下两边保持原高度
  wipe: # wipe 图片，可与普通 note 不同
    left: 10 # 从原图左边量 10 像素
    right: 10 # 从原图右边量 10 像素
    top: 4 # 从原图上边量 4 像素
    bottom: 4 # 从原图下边量 4 像素
    scale_x: sides # 横向选择两边缩放，中间保持原宽度
    scale_y: center # 纵向选择中间缩放
  hold: # 长条音符的头、身、尾共用这组设置
    left: 8 # 从原图左边量 8 像素
    right: 8 # 从原图右边量 8 像素
    top: 6 # 从原图上边量 6 像素
    bottom: 6 # 从原图下边量 6 像素
    scale_x: center # 横向选择中间缩放
    scale_y: center # 纵向选择中间缩放
```

## 颜色怎么填

颜色使用带引号的 `"#RRGGBB"`，也就是选色工具常给出的 `#` 开头六位颜色码。例如 `"#FF0000"` 是红色，`"#000000"` 是黑色。想要半透明，可以在末尾再加两位：`"#FF000080"` 是半透明红色。只改某一个颜色时，不必复制整份例子。

## 配置名对应的位置

表中的英文是需要照写的配置名。`edit` 区是放置音符的编辑区域，`demo` 区是播放预览的区域。

| 配置名 | 会改变的地方 |
| --- | --- |
| `colors.dark`、`colors.light` | 分别填写夜间和日间的颜色。 |
| `nuklear` | 普通界面的文字、窗口、按钮、输入框等。例子里的 `text` 是文字，`button` 是按钮。 |
| `play` | 播放画面和编辑画面的线条、选中标记等。还可填写 `white`（白色线条）、`red`（假音符标记）、`eventInDemo.w`（W 事件颜色）等。 |
| `demo`、`menu`、`edit_tool` | 分别是演示画面的分数和连击、选歌界面、上方编辑工具栏。例如 `demo.combo` 是连击数字，`menu.dgray` 是菜单底色，`edit_tool.slider` 是滑块底色。 |
| `tabs` | 标签页。`tab` 是未选中的标签，`activeTab` 是当前标签，`info_background` 是信息框底色。`close`、`laneOn`、`laneOff`、`plus` 需要按“平常、鼠标移上、按下”的顺序填写三种颜色。 |
| `editor.canvas`、`editor.demo_background` | 分别是 edit 区和 demo 区的背景。`colors` 下的 `background` 是整个窗口的底色。 |
| `ui_images` | 工具栏图标。`default` 改所有图标，也能用 `save` 只改保存图标。还可用 `play`（播放）、`pause`（暂停）、`up`/`down`（上下箭头）、`close`（关闭）、`add`/`sub`（加减）、`isbreak`（断开）、`github` 分别设置。 |
| `judge_line` | 判定线。`inner` 是 demo 区判定线内部，`outer` 是外框，`edit` 是 edit 区判定线。 |
| `note_slices` | 音符图片的九宫格设置。`note`、`wipe`、`hold` 可以分别填写。 |

## 中间缩放和两边缩放

音符变宽或变高时，整张图片一起拉伸可能把图案拉扁。九宫格用四个数把原图分成九块，再决定拉伸中间还是两边。`left`、`right`、`top`、`bottom` 都按**原图的像素**填写：分别表示从左、右、上、下边缘向内量多少像素。

| 配置名和值 | 图片会怎样变化 |
| --- | --- |
| `scale_x: center` | **横向中间缩放**：音符变宽时，左边和右边保持原来的宽度，只把中间拉宽。 |
| `scale_x: sides` | **横向两边缩放**：音符变宽时，中间保持原来的宽度，左边和右边一起拉宽。 |
| `scale_y: center` | **纵向中间缩放**：音符变高时，上边和下边保持原来的高度，只把中间拉高。 |
| `scale_y: sides` | **纵向两边缩放**：音符变高时，中间保持原来的高度，上边和下边一起拉高。 |

横向和纵向可以分别选择。例如 `scale_x: sides` 配 `scale_y: center`，表示宽度增加时拉伸左右两边，高度增加时拉伸中间。假设图片宽 100 像素，`left` 和 `right` 都填 20，那么中间宽 60。音符变成 200 像素宽时，中间缩放会变成 **20＋160＋20**，两边缩放会变成 **70＋60＋70**。

`hold` 的设置会一起用于长条音符的头、身、尾。想分别调整时，可以再填写 `hold_head`、`hold_body`、`hold_tail`；没单独写的部分继续使用 `hold` 的设置。左右两边的数加起来必须小于原图宽度，上下同理；数值填错时会回到整张图片拉伸。没有填写九宫格的图片也会照旧显示。

想换图片，可以把 `note.png`、`wipe.png`、`holdHead.png`、`holdBody.png`、`holdTail.png` 放进 `users/ui/`。四个切线数值要按自己图片的实际大小填写。设置会用于 edit 区、demo 区和粘贴预览。
