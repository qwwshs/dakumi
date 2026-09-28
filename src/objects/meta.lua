--[[
    模块名: meta
    描述: 谱面数据模型定义（纯数据常量，不包含任何 chart 操作方法）
    作者: qwwshs
    依赖: 无

    本模块定义了谱面编辑器的核心数据结构（元表）：
    - meta_key: 快捷键配置
    - meta_chart: 谱面数据格式（__index 作为默认字段模板，由 ChartService:setChart 的 table.fill 使用）
    - meta_event: 事件数据格式
    - meta_note: 音符数据格式
    - meta_bpm: BPM 数据格式
    - meta_track: 轨道定义格式
    - meta_extra_chart_track: extra_chart 单轨道索引结构
    - meta_settings: 用户设置格式

    chart 的操作方法（update/load/push/pop/add/delete）已移入 src/services/chartService.lua
]]

-- ============================================================
-- 快捷键配置元表
-- ============================================================
meta_key = {
    __index = {
    placeNote = {'q'},                -- 放置 note
    placeWipe = {'w'},                -- 放置 wipe（滑条）
    placeHold = {'e'},                -- 放置 hold（长条）
    placeEvent = {'e'},               -- 放置 event
    delete = {'d'},                   -- 删除 note 或 event
    demo = {'tab'},                   -- 预览或关闭预览
    play = {'space'},                 -- 播放或暂停
    trackUp = {'right'},              -- 轨道加1
    trackDown = {'left'},             -- 轨道减1
    denomUp = {'up'},                 -- 节拍分度+1
    denomDown = {'down'},             -- 节拍分度-1
    directEventEditing = {'capslock'}, -- event 直观编辑模式

    select = {'shift'},               -- 框选确认
    copy = {'ctrl','c'},              -- 复制
    paste = {'ctrl','v'},             -- 粘贴
    pasteAll = {'ctrl','a','v'},      -- 粘贴（包括 event）
    flipPasteAll = {'ctrl','a','b'},  -- 取反 event 粘贴（包括 event）
    flipPaste = {'ctrl','b'},         -- 取反 event 粘贴
    cut = {'ctrl','x'},               -- 剪切
    accelerate = {'ctrl'},            -- 滚动加速

    deleteSelect = {'ctrl','d'},      -- 删除所选
    deleteAllSelect = {'ctrl','a','d'}, -- 删除所选（包括 event）
    undo = {'ctrl','z'},              -- 撤销
    redoing = {'ctrl','y'},           -- 重做
    save = {'ctrl','s'},              -- 保存

    flipEvent = {'alt','b'},          -- 翻转 event 数值
    cutEventOrHold = {'alt','c'},     -- 裁切 hold 或 event
    dragHead = {'alt','z'},           -- 拖头
    dragTail = {'alt','x'},           -- 拖尾
    adjustEventValue = {'alt','t'},   -- 调整 event 数值
    flipUpsideDownEvent = {'alt','u'}, -- 上下翻转 event
    }
}

-- ============================================================
-- 谱面数据元表
-- ============================================================
meta_chart = {
    __index = {
        bpm_list = {
            { beat = { 0, 0, 1 }, bpm = 120 },  -- BPM 列表，每项包含 beat 和 bpm
        },
        note = {},          -- 音符列表
        event = {},         -- 事件列表
        effect = {},        -- 效果列表
        offset = 0,         -- 音频偏移量（毫秒）
        info = {            -- 谱面信息
            song_name = [[]],   -- 歌曲名
            chart_name = [[]],  -- 谱面名
            chartor = [[]],     -- 谱师
            artist = [[]],      -- 作者
        },
        preference = {      -- 偏好设置
            x_offset = 0,       -- x 偏移
            event_scale = 100,  -- event 缩放
        },
        track = {},         -- 轨道定义表
        version = 1         -- 谱面格式版本
    }
}

-- ============================================================
-- 事件数据元表
-- ============================================================
meta_event = {
    __index = {
        beat = { 0, 0, 1 },    -- 起始 beat {整数, 分子, 分母}
        beat2 = { 0, 0, 1 },   -- 结束 beat
        track = 1,             -- 所属轨道 ID
        type = 'x',            -- 事件类型: "x", "w", "lpos", "rpos"
        from = 1,              -- 起始值
        to = 1,                -- 结束值
        trans = {              -- 过渡参数
            trans = {0,0,1,1}, -- 贝塞尔控制点
            type = 'bezier',   -- 过渡类型: "bezier" 或 "easings"
            easings = 1        -- 缓动函数索引
        },
    }
}

-- ============================================================
-- 音符数据元表
-- ============================================================
meta_note = {
    __index = {
        beat = { 0, 0, 1 },    -- 音符 beat 位置
        track = 1,             -- 所属轨道 ID
        type = 'note',         -- 音符类型: "note", "hold", "wipe"
        fake = 0,              -- 是否为假音符 (0=否, 1=是)
    }
}

-- ============================================================
-- BPM 数据元表
-- ============================================================
meta_bpm = {
    __index = {
        beat = { 0, 0, 1 },    -- BPM 变化的 beat 位置
        bpm = 120,             -- BPM 值
        linear_ramp = 0        -- 线性变化模式 (0=突变, 1=线性渐变)
    }
}

-- ============================================================
-- 轨道定义元表
-- ============================================================
meta_track = {
    __index = {
        name = '',                 -- 轨道名称
        w0thenShow = 0,           -- w=0 时是否显示
        type = 'xw',              -- 轨道类型
        parent = 0,               -- 父轨道 ID (0=无父轨道)
        scale_with_parent = 0,    -- 是否跟随父轨道缩放 (0=否, 1=是)
        zindex = 0,                --层级
        left_boundary = 0,            -- 左边界（track 模式填轨道号，0 即轨道 0；pos 模式填坐标，0 是合法坐标）
        right_boundary = 0,           -- 右边界（同上；是否启用只看 boundary_type，'nil' 才不启用）
        boundary_type = 'nil',        -- 边界类型: "nil", “track”,'pos'
        left_reference = 'x',        -- 左边界参考类型: "x", "w", "lpos","rpos"
        right_reference = 'x',       -- 右边界参考类型: "x", "w", "lpos","rpos"
    }
}

--- extra_chart 中单个轨道的数据结构
meta_extra_chart_track = {
    x = {},      -- x 类型事件列表
    w = {},      -- w 类型事件列表
    lpos = {},   -- lpos 类型事件列表
    rpos = {},   -- rpos 类型事件列表
    note = {}    -- 音符列表
}

--- 事件类型列表（有序）
event_type = {'x','w','lpos','rpos'}

--- edit 区域每个轨道类型的顺序和位置映射
-- 用于确定鼠标点击所在的轨道类型
trackSequence = {
    'note','x','w','lpos','rpos',  -- 有序列表
    note = 1,    -- note 类型的索引
    x = 2,       -- x 类型的索引
    w = 3,       -- w 类型的索引
    lpos = 4,    -- lpos 类型的索引
    rpos = 5,    -- rpos 类型的索引
}

--- 获取指定类型在 edit 区域的 x 坐标范围
-- @tparam string istype 类型名 ("note", "x", "w", "lpos", "rpos")
-- @treturn number x1 起始 x 坐标
-- @treturn number x2 结束 x 坐标
function trackSequence:getRange(istype)
    if not self[istype] then
        love.window.showMessageBox("debug", "getRange:"..istype, "info")
    end
    return play.layout.edit.x + play.layout.edit.interval * (self[istype]-1),
        play.layout.edit.x + play.layout.edit.interval * (self[istype])
end

--- 根据 x 坐标获取所在的轨道类型
-- @tparam number x 屏幕 x 坐标
-- @treturn string|nil 类型名，如果不在任何轨道范围内返回 nil
function trackSequence:getType(x)
    for i, v in pairs(self) do
        if type(i) == 'string' and type(v) == 'number' then
            local x1, x2 = self:getRange(i)
            if x >= x1 and x < x2 then
                return i
            end
        end
    end
end

-- ============================================================
-- 用户设置元表
-- ============================================================
meta_settings = {
    __index = {
        judge_line_y = 700,             -- 判定线 Y 坐标
        music_volume = 100,             -- 音乐音量 (0-100)
        hit_volume = 100,               -- 打击音效音量 (0-100)
        beep_volume = 100,                 --提示音效音量 (0-100)
        hit = 0,                        -- 打击音效类型
        hit_sound = 0,                  -- 打击音效索引
        hit_time = 0.5,                 -- 打击音效持续时间
        hit_light_time = 0.5,           -- 打击光效持续时间
        track_w_scale = 8,              -- 轨道宽度缩放
        angle = 30,                     -- 角度
        language = "zh-CN",             -- 语言设置
        default_trans_type = 'easings', -- 默认过渡类型
        contact_roller = 1,             -- 鼠标滚动系数
        note_height = 75,               -- 音符高度
        bg_alpha = 50,                  -- 背景透明度 (0-100)
        denom_alpha = 70,               -- 分度线透明度 (0-100)
        window_width = WINDOW.w,        -- 窗口宽度
        window_height = WINDOW.h,       -- 窗口高度
        auto_save = 1,                  -- 自动保存间隔（分钟）
        wavfrom = 1,                    -- 是否显示波形图
        paste_preview_alpha = 0.75,     -- 粘贴预览透明度
        theme = 'dark'                  -- 界面主题：dark / light
    }
}
