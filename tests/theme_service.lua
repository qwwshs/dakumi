-- 主题配置回归：解析 YAML、切换昼夜配色，不读写 users 目录。
local source = [[
colors:
  dark:
    nuklear:
      text: "#EAEAEA"
    play:
      white: "#10203080"
      eventInDemo:
        x: "#112233"
    tabs:
      button: ["#112233", "#223344"]
      info_background: "#334455"
    editor:
      canvas: "#123456"
    background: "#010203"
  light:
    nuklear:
      text: "#222222"
ui_images:
  dark:
    default: "#F0F0F0"
  light:
    default: "#202020"
    save: "#2468AC"
judge_line:
  dark:
    inner: "#00CCDD"
    outer: "#FFFFFF"
    edit: "#AABBCC"
note_slices:
  note:
    left: 4
    right: 5
    top: 2
    bottom: 2
    scale_x: sides
    scale_y: center
  hold:
    left: 3
    right: 3
    top: 1
    bottom: 1
    scale_x: center
    scale_y: sides
]]

nativefs = {read = function(path)
    assert(path == 'users/ui/theme.yml')
    return source
end}
local theme = require('src.services.themeService')
local function near(actual, expected)
    assert(math.abs(actual - expected) < 0.00001, tostring(actual) .. ' ~= ' .. tostring(expected))
end

assert(theme:load('users/ui/theme.yml'))
assert(theme:nuklearColors('dark', {text = '#FFFFFF', button = '#000000'}).text == '#EAEAEA')
assert(theme:nuklearColors('dark', {text = '#FFFFFF', button = '#000000'}).button == '#000000')
near(theme:iconColor('light', 'save')[1], 0x24 / 255)
near(theme:iconColor('light', 'play')[1], 0x20 / 255)
near(theme:judgeColor('dark', 'inner')[2], 0xCC / 255)
near(theme:editorColor('dark', 'canvas')[3], 0x56 / 255)
near(theme:backgroundColor('dark')[1], 1 / 255)
assert(theme:slice('note').scale_x == 'sides')
assert(theme:slice('hold_body').scale_y == 'sides')
assert(theme:slice('wipe') == nil)

local colors = {white = {1, 1, 1, 1}, eventInDemo = {x = {1, 1, 1, 1}}}
theme:restoreColors(colors, 'test')
theme:overrideColorTable(colors, 'play', 'dark')
near(colors.white[1], 0x10 / 255)
near(colors.white[4], 0x80 / 255)
near(colors.eventInDemo.x[2], 0x22 / 255)
theme:restoreColors(colors, 'test')
assert(colors.white[1] == 1 and colors.eventInDemo.x[2] == 1)

local tabs = theme:tabColors('dark', {button = {'#000000', '#FFFFFF'}, bar = {0, 0, 0, 1}})
assert(tabs.button[1] == '#112233' and tabs.button[2] == '#223344')
assert(tabs.info_background == '#334455')

local guide = assert(io.open('readme/theme.md', 'rb'))
local markdown = guide:read('*a')
guide:close()
local example = assert(markdown:match('```yaml%s*(.-)%s*```'))
nativefs.read = function() return example end
assert(theme:load('users/ui/theme.yml'))
assert(theme.data.colors.dark.nuklear['button hover'] == '#34485C')
assert(theme:slice('wipe').scale_x == 'sides')
assert(theme:slice('wipe').left == 10)
assert(theme:iconColor('light', 'save')[1] > 0)

nativefs.read = function() return 'colors: [broken' end
assert(not theme:load('users/ui/theme.yml'))
assert(theme:slice('note') == nil)
print('theme service PASS')
