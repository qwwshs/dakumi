"""生成文档示意图：python readme/images/generate_diagrams.py（需要 Pillow）。"""
from pathlib import Path
import math
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
FONT = Path('C:/Windows/Fonts/msyh.ttc')
BOLD = Path('C:/Windows/Fonts/msyhbd.ttc')
INK = '#182C44'
MUTED = '#52667C'
BLUE = '#245FCC'
TEAL = '#087F79'
PURPLE = '#7155B7'


class Figure:
    def __init__(self, title, subtitle, height):
        self.image = Image.new('RGB', (1280, height), '#F7F9FC')
        self.draw = ImageDraw.Draw(self.image)
        self.text(48, 30, title, 36, bold=True)
        self.text(48, 83, subtitle, 23, MUTED)

    def text(self, x, y, text, size=26, color=INK, bold=False, center=False):
        font = ImageFont.truetype(str(BOLD if bold else FONT), size)
        width = self.draw.textlength(text, font=font)
        if center:
            x -= width / 2
        assert x >= 0 and x + width <= self.image.width - 10, (text, x, width)
        assert y >= 0 and y + size <= self.image.height, text
        self.draw.text((x, y), text, font=font, fill=color)

    def box(self, x, y, w, h, fill, border=None, radius=12):
        self.draw.rounded_rectangle((x, y, x + w, y + h), radius, fill, border, width=2)

    def line(self, points, color=MUTED, width=2):
        self.draw.line(points, fill=color, width=width)

    def arrow(self, x0, y0, x1, y1, color=BLUE, width=3):
        self.line([(x0, y0), (x1, y1)], color, width)
        a = math.atan2(y1 - y0, x1 - x0)
        p = [(x1, y1)]
        for da in (-0.5, 0.5):
            p.append((x1 - 13 * math.cos(a + da), y1 - 13 * math.sin(a + da)))
        self.draw.polygon(p, fill=color)

    def save(self, name):
        self.image.save(OUT / name, optimize=True)


def editor():
    f = Figure('编辑界面：先认清这几个区域', '结构示意；按钮样式与比例做了简化，非软件截图。', 810)
    f.box(48, 132, 895, 66, '#DFEAFE', '#B4CAEE')
    f.text(68, 151, '① 工具栏', 27, BLUE, True)
    f.text(258, 153, '保存  /  播放  /  分度  /  缩放  /  轨道', 25)
    f.box(48, 205, 895, 56, '#EAE4F6', '#D6C7EC')
    f.text(68, 219, '标签页：选择轨道，开关 note / x / w / lpos / rpos', 25, PURPLE)
    f.box(48, 270, 570, 349, '#E8F5F3', '#9DCFC9')
    f.text(70, 289, '② 预览区 demo', 29, TEAL, True)
    for x in (100, 210, 320, 430, 540):
        f.line([(x, 342), (x, 567)], '#AFD3CD')
    f.box(160, 378, 104, 15, '#39A79F', radius=3)
    f.box(369, 439, 101, 15, '#39A79F', radius=3)
    f.box(260, 487, 97, 76, '#91CEC6', radius=3)
    f.line([(72, 566), (595, 566)], TEAL, 5)
    f.text(79, 579, '判定线：当前播放位置', 23, TEAL)
    f.box(634, 270, 309, 349, '#EEF2FA', '#BCCBE4')
    f.text(650, 286, '③ 编辑区 edit', 28, BLUE, True)
    f.text(650, 334, 'note   x   w   lpos   rpos', 23)
    for i in range(6):
        f.line([(649 + i * 55, 377), (649 + i * 55, 556)], '#B9C8DF')
    f.box(658, 417, 35, 18, '#6091DE', radius=3)
    f.box(714, 390, 37, 120, '#C6B5E4', radius=3)
    f.text(650, 577, '滚轮移动节拍', 24, BLUE)
    f.box(964, 132, 268, 487, '#FFFFFF', '#CBD5E1')
    f.text(983, 153, '④ 侧边栏', 29, bold=True)
    for i, label in enumerate(('谱面信息', '偏好', '轨道', '设置', '事件组', '操作历史')):
        f.box(981, 216 + i * 55, 232, 43, '#F1F4F9')
        f.text(1001, 225 + i * 55, label, 25)
    f.text(983, 567, '点对象后编辑属性', 23, MUTED)
    f.box(48, 651, 1184, 113, '#FFFFFF', '#DDE5EE')
    f.text(70, 670, '音符栏：Q 放 note，W 放 wipe，按两次 E 放 hold。', 26)
    f.text(70, 714, '事件栏：按两次 E 放事件；按两次 T 放事件组引用。', 26)
    f.save('editor-layout.png')


def groups():
    f = Figure('事件组：同一动作可以放到不同时间', '示例：组内 2～6 拍 → 谱面 10～18 拍；默认偏好，from = 20、to = 80。', 780)
    f.box(48, 131, 1184, 224, '#FFFFFF', '#DDE5EE')
    f.text(73, 147, '组内原动作', 27, PURPLE, True)
    f.line([(300, 210), (1130, 210)], '#C6B7E4', 4)
    for x, beat in ((300, '2 拍'), (715, '4 拍'), (1130, '6 拍')):
        f.line([(x, 200), (x, 220)], PURPLE, 4)
        f.text(x, 225, beat, 25, center=True)
    f.text(73, 282, '组内位置', 25)
    for x, value in ((300, '0'), (715, '50'), (1130, '100')):
        f.text(x, 282, value, 27, PURPLE, True, center=True)
    f.arrow(715, 355, 715, 403)
    f.text(770, 359, '时长伸缩，数值映射', 25, BLUE)
    f.box(48, 407, 1184, 213, '#FFFFFF', '#DDE5EE')
    f.text(73, 425, '放入谱面', 27, BLUE, True)
    f.line([(300, 485), (1130, 485)], '#ADC4EA', 4)
    for x, beat in ((300, '10 拍'), (715, '14 拍'), (1130, '18 拍')):
        f.line([(x, 475), (x, 495)], BLUE, 4)
        f.text(x, 500, beat, 25, center=True)
    f.text(73, 556, '实例位置', 25)
    for x, value in ((300, '20'), (715, '50'), (1130, '80')):
        f.text(x, 556, value, 27, BLUE, True, center=True)
    f.box(48, 646, 1184, 91, '#FFF0EB', '#F0C6B7')
    f.text(72, 658, '同轨道的 10～18 拍：不能重叠放其他事件或事件组。', 26, '#943F26', True)
    f.text(72, 698, '音符和其他轨道不受影响；18 拍处可以接下一段事件。', 24, '#943F26')
    f.save('event-group-placement.png')


def spectrogram():
    f = Figure('声纹图：横向看频率，纵向看时间', '读图示意，线条代表声音的持续频率；不是实际音乐分析结果。', 880)
    f.box(48, 132, 1184, 77, '#FFFFFF', '#DDE5EE')
    f.text(68, 151, '低频', 26, bold=True)
    f.arrow(176, 171, 1055, 171)
    f.text(1120, 151, '高频', 26, bold=True)
    f.box(176, 230, 674, 414, '#131C30', radius=8)
    for y in (310, 390, 470, 550):
        f.line([(176, y), (850, y)], '#344361')
    # 理想持续音的等间距谐波用于示意；明确标注本图采用均匀 Hz 刻度。
    for x, width, color in ((270, 11, '#FDD477'), (375, 8, '#F8844C'), (480, 6, '#DA524E'), (585, 4, '#B85379')):
        f.box(x, 264, width, 318, color, radius=2)
    f.box(661, 409, 117, 8, '#F6A762', radius=3)
    f.text(908, 273, '持续音及泛音', 27, PURPLE, True)
    f.arrow(904, 321, 598, 330, PURPLE)
    f.text(908, 354, '同一时间段', 24, MUTED)
    f.text(908, 391, '占据多个频率位置', 24, MUTED)
    f.text(908, 461, '短促声音', 27, TEAL, True)
    f.arrow(904, 495, 790, 416, TEAL)
    f.text(908, 526, '在时间方向较短', 24, MUTED)
    f.arrow(110, 611, 110, 258, MUTED)
    f.text(60, 221, '更晚', 25, MUTED)
    f.text(60, 624, '现在', 25, MUTED)
    f.line([(176, 644), (850, 644)], '#4FC1BD', 4)
    f.text(176, 660, '判定线', 23, TEAL)
    f.text(383, 660, '图中使用均匀 Hz 刻度', 23, MUTED)
    for i in range(220):
        u = i / 219
        if u < 0.5:
            t = u * 2
            color = (int(22 + 185*t), int(29 + 30*t), int(49 + 34*t))
        else:
            t = (u - 0.5) * 2
            color = (int(207 + 48*t), int(59 + 149*t), int(83 - 11*t))
        f.draw.rectangle((680 + i*2, 728, 681 + i*2, 756), fill=color)
    f.text(72, 719, '颜色表示强弱', 26, bold=True)
    f.text(534, 721, '弱', 26)
    f.text(1151, 721, '强', 26)
    f.text(72, 804, '音名尺按音阶排布；找鼓点起止时，结合波形或使用短窗口。', 25, MUTED)
    f.save('spectrogram-reading.png')


def slices():
    f = Figure('九宫格：中间缩放，还是两边缩放？', '横向示例：原图宽 100，left = 20、right = 20；拉伸后宽 200。', 740)
    colors = ('#D9E8FF', '#DCEFEA', '#D9E8FF')

    def strip(y, widths, numbers, caption):
        x = 355
        for w, n, color in zip(widths, numbers, colors):
            f.box(x, y, w, 103, color, '#A9BFD4', radius=0)
            for ly in (y + 20, y + 83):
                f.line([(x, ly), (x + w, ly)], '#A9BFD4')
            f.text(x + w/2, y + 32, str(n), 27, center=True)
            x += w
        f.text(355, y + 117, caption, 23, MUTED)

    f.text(48, 169, '原图', 29, bold=True)
    f.text(48, 212, '20 + 60 + 20', 25, MUTED)
    strip(150, (84, 252, 84), (20, 60, 20), '四条切线把图分成九块，数值按原图像素填写。')
    f.text(48, 346, '中间缩放', 29, TEAL, True)
    f.text(48, 391, 'scale_x: center', 24, TEAL)
    strip(328, (84, 672, 84), (20, 160, 20), '左右保持 20，只把中间从 60 拉到 160。')
    f.text(48, 526, '两边缩放', 29, BLUE, True)
    f.text(48, 571, 'scale_x: sides', 24, BLUE)
    strip(508, (294, 252, 294), (70, 60, 70), '中间保持 60，左右两边各从 20 拉到 70。')
    f.text(48, 691, '纵向同理：scale_y 决定拉伸中间，还是上下两边。', 25, MUTED)
    f.save('note-nine-slice.png')


if __name__ == '__main__':
    for make in (editor, groups, spectrogram, slices):
        make()
    print('Generated four documentation figures.')
