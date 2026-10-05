local AudioService = require('src.services.audioService')
--轨道渲染
local ChartService = require("src.services.chartService")
local NoteSkin = require("src.services.noteSkin")
local EffectService = require('src.services.effectService')
local ThemeService = require("src.services.themeService")
local demoPlay = object:new("demoPlay")
local layout = require 'config.layouts.play'.demo
local trackZindex = {} --轨道层级
demoPlay.sw = 1
demoPlay.sh = 1
demoPlay.ex = 0
demoPlay.ey = 0

demoPlay.ui = {}
demoPlay.ui.note = isImage.note2
demoPlay.ui.wipe = isImage.wipe2
demoPlay.ui.hold = isImage.hold_head2
demoPlay.ui.holdBody = isImage.hold_body2
demoPlay.ui.holdTail = isImage.hold_tail2
local skinNames = {
    ['note.png'] = {'note', 'note'},
    ['wipe.png'] = {'wipe', 'wipe'},
    ['holdHead.png'] = {'hold', 'hold_head'},
    ['holdBody.png'] = {'holdBody', 'hold_body'},
    ['holdTail.png'] = {'holdTail', 'hold_tail'},
}
local ui_tab = nativefs.getDirectoryItems(PATH.usersPath.ui) --得到文件夹下的所有文件
if ui_tab and #ui_tab > 0 then
    nativefs.mount(PATH.base)
    for i = 1, #ui_tab do
        local v = ui_tab[i]
        local names = skinNames[v]
        if names then
            local ok, image = pcall(love.graphics.newImage, PATH.usersPath.ui .. v)
            if ok then
                demoPlay.ui[names[1]] = image
                isImage[names[2]] = image -- edit 区、预览与 demo 区共用自定义图片
            end
        end
    end
    nativefs.unmount()
end

local to3d_shader = love.graphics.newShader('src/shader/3d.glsl')


to3d_shader:send("rectangle", layout.x, layout.y, layout.w, layout.h)
to3d_shader:send("tanAngle", math.tan(10 / 180 * math.pi)) --透视强度

function demoPlay:Setup(x, y, w, h)
    local sw = w / layout.w
    local sh = h / layout.h
    self.ex = x
    self.ey = y
    self.sw = sw
    self.sh = sh
    to3d_shader:send("rectangle", (WINDOW.nowW - WINDOW.scale * WINDOW.w) / 2, (WINDOW.nowH - WINDOW.scale * WINDOW.h) /
    2, self.sw * layout.w * WINDOW.scale, self.sh * layout.h * WINDOW.scale)
    to3d_shader:send("tanAngle", math.tan(settings.angle / 180 * math.pi)) --透视强度
    to3d_shader:send("judge", (settings.judge_line_y - layout.y) / h)
end

-- demo 逐个判断实际显示时间，不缓存数组下标。
-- 插件增删、跨帧编辑与偏移重排期间，谱面列表未必保持时间顺序。
function demoPlay:resetTraversal()
end

function demoPlay:draw()
    local sw = self.sw
    local sh = self.sh
    local ex = self.ex
    local ey = self.ey

    local judgePos = settings.judge_line_y * sh
    local all_track_pos = play:get_all_track_pos()

    -- 绘制使用本帧已经计算过位置的轨道快照；侧栏在 update 后可能刚创建初始值轨道。
    local all_track = {}
    for id in pairs(all_track_pos) do all_track[#all_track + 1] = id end
    table.sort(all_track)

    if next(all_track_pos) == nil then --没有轨道
        return
    end

    if demo.open then love.graphics.setShader(to3d_shader) end
    love.graphics.push()
    love.graphics.translate(ex, ey)



    for i = 1, #all_track do                                      --轨道底板绘制
        local effect = play:get_effect(all_track[i])
        love.graphics.setColor(0, 0, 0, 0.5 * effect.track_alpha / 100)
        local x, w = all_track_pos[all_track[i]].track_x, all_track_pos[all_track[i]].track_w
        x = x * sw
        w = w * sw
        if w ~= 0 then
            love.graphics.rectangle("fill", x, 0, w, judgePos * sh)
        end
    end

    for i = 1, #all_track do --轨道侧线绘制
        local effect = play:get_effect(all_track[i])
        local track_w0thenShow = ChartService:getTrackField(all_track[i], 'w0thenShow')
        local track_name = ChartService:getTrackField(all_track[i], 'name')

        local x, w = all_track_pos[all_track[i]].track_x, all_track_pos[all_track[i]].track_w
        x = x * sw
        w = w * sw
        if track.track == all_track[i] and (not demo.open) then      --选择到的底板
            love.graphics.setColor(play.colors.white_dim)
            love.graphics.rectangle("fill", x, 0, w, WINDOW.h)
        end
        if w ~= 0 then
            love.graphics.setColor(1, 1, 1, effect.track_line_alpha / 100)  --侧线
            love.graphics.rectangle("line", x, 0, w, WINDOW.h)
        elseif w == 0 and track_w0thenShow == 1 then
            love.graphics.setColor(1, 1, 1, effect.track_line_alpha / 100)  --侧线
            love.graphics.rectangle("line", x, 0, 0.01, WINDOW.h)
        end
        if not demo.open then
            love.graphics.setColor(play.colors.white)        --轨道编号 与名称
            if track.track == all_track[i] then
                love.graphics.setColor(play.colors.cyan)     --轨道编号
            end
            local str = ""
            if track_name ~= '' then
                str = "(" .. track_name .. ")"
            end
            love.graphics.printf(all_track[i] .. str, x, judgePos - 20, 100, "center")
        end
    end

    --游玩区域侧线
    love.graphics.setColor(play.colors.white_half)
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    local x, w = fTrack:to_play_track(-x_offset, 0.002 * event_scale)
    x = x * sw
    w = w * sw
    love.graphics.rectangle("fill", x, 0, w, WINDOW.h)
    x, w = fTrack:to_play_track(-x_offset + event_scale, 0.002 * event_scale)
    x = x * sw
    w = w * sw
    love.graphics.rectangle("fill", x, 0, w, WINDOW.h)

    love.graphics.setColor(play.colors.white) --游玩区域侧线(外侧)
    x, w = fTrack:to_play_track(-x_offset - 0.01 * event_scale, 0.005 * event_scale)
    x = x * sw
    w = w * sw
    love.graphics.rectangle("fill", x, 0, w, WINDOW.h)
    x, w = fTrack:to_play_track(-x_offset + 1.01 * event_scale, 0.005 * event_scale)
    x = x * sw
    w = w * sw
    love.graphics.rectangle("fill", x, 0, w, WINDOW.h)
    
    trackZindex = {} --清空轨道层级
    local temptab = {}
    --按zindex分组轨道
    for i = 1, #all_track do
        local zindex = ChartService:getTrackField(all_track[i], 'zindex')
        if not temptab[zindex] then
            temptab[zindex] = {}
        end
        temptab[zindex][#temptab[zindex] + 1] = all_track[i]
    end
    --按照层级大小顺序再排到trackZindex
    local sorted_keys = {}
    for k in pairs(temptab) do
        table.insert(sorted_keys, k)
    end
    table.sort(sorted_keys)
    for _, zindex in ipairs(sorted_keys) do
        trackZindex[zindex] = temptab[zindex]
    end
    --记录轨道所属层级,note按此分组渲染
    local track_zindex = {}
    for _, zindex in ipairs(sorted_keys) do
        local tracks = trackZindex[zindex]
        for _, trackId in ipairs(tracks) do
            track_zindex[trackId] = zindex
        end
    end

    local note_h = settings.note_height * sh                 --25 * denom.scale
    local noteBeat = 0
    local noteBeat2 = 0

    local isnote
    local x, w, y, y2

    --展示侧note渲染
    local spacing = 20 * sw --note和track的间距

    -- 按谱面列表顺序收集可见音符；每个音符的偏移仅影响自身的可见性。
    local note_layers = {}
    local motion = demo.open and EffectService:createMotion(all_track) or nil
    local nowBeat = AudioService:getCurrentBeat()
    local function noteY(trackId, target)
        return settings.judge_line_y - (motion and motion:distance(trackId,nowBeat,target) or target-nowBeat)*denom.scale*100
    end
    for i = 1, ChartService:getNoteCount() do
        isnote = ChartService:getNote(i)
        noteBeat = isnote:getBeatValue()
        local beat2 = isnote:getBeat2()
        noteBeat2 = beat2 and isnote:getBeat2Value() or noteBeat
        local trackId = isnote:getTrack()
        y = noteY(trackId,noteBeat)
        y2 = y
        if isnote:isHold() then
            y2 = noteY(trackId,noteBeat2)
        end
        y = y * sh
        y2 = y2 * sh
        -- 判定依据真实时间，不能用 scroll/jump 改变后的坐标提前隐藏音符。
        -- 长条直到尾部判定才移除；反向下落也按整个 demo 高度判断可见性。
        if isnote:isHold() and noteBeat <= nowBeat and noteBeat2 >= nowBeat then y=judgePos end
        local top=math.min(y,y2)-note_h
        local bottom=math.max(y,y2)+ (isnote:isHold() and note_h or 0)
        if noteBeat2 >= nowBeat and math.intersect(0, layout.h*sh, top, bottom) then
            local zindex = track_zindex[trackId] or 0
            if not note_layers[zindex] then
                note_layers[zindex] = {}
            end
            local layer = note_layers[zindex]
            layer[#layer + 1] = {isnote = isnote, y = y, y2 = y2}
        end
    end

    --按层级从低到高绘制note
    for _, zindex in ipairs(sorted_keys) do
        local layer = note_layers[zindex]
        if layer then
            for j = 1, #layer do
                isnote = layer[j].isnote
                y = layer[j].y
                y2 = layer[j].y2
                local trackId = isnote:getTrack()
                local effect = play:get_effect(trackId)
                love.graphics.setColor(1, 1, 1, effect.note_alpha / 100)
                x, w = all_track_pos[trackId].track_x, all_track_pos[trackId].track_w
                x = x * sw
                w = w * sw

                x = x + w / 2
                if math.abs(w) > spacing * 2 then   --增加间隙
                    w = w - spacing * w / math.abs(w)
                elseif math.abs(w) <= spacing * 2 and math.abs(w) > spacing then
                    w = spacing * w / math.abs(w)
                end
                x = x - w / 2
                if isnote:isHold() and isnote:getBeatValue() <= nowBeat and isnote:getBeat2Value() > nowBeat then y = judgePos end     --hold头保持在线上

                if not isnote:isHold() then
                    NoteSkin.draw(isnote:getType(), self.ui[isnote:getType()], x, y - note_h,
                        w, note_h, effect.note_rotate)
                else                                                                                                                                  --hold
                    NoteSkin.draw('hold_head', self.ui.hold, x, y - note_h, w, note_h)
                    NoteSkin.draw('hold_body', self.ui.holdBody, x, y2 + note_h, w, y - y2 - note_h * 2)
                    NoteSkin.draw('hold_tail', self.ui.holdTail, x, y2, w, note_h)
                    if isnote:getNoteHead() == 1 then
                        NoteSkin.draw('note', self.ui.note, x, y - note_h, w, note_h, effect.note_rotate)
                    end
                    if isnote:getWipeHead() == 1 then
                        NoteSkin.draw('wipe', self.ui.wipe, x, y - note_h, w, note_h, effect.note_rotate)
                    end
                end
            end
        end
    end

    -- 判定线下方也允许绘制尚未判定的音符，不再添加遮挡板。
    local start_x = fTrack:to_play_track(-x_offset, 0) * sw
    local end_x = fTrack:to_play_track(-x_offset + event_scale, 0) * sw

    --进度条
    local progress_bar = fTrack:to_play_track(-x_offset + event_scale * 0.2, 0) * sw
    love.graphics.setColor(play.colors.white)
    love.graphics.rectangle("fill", start_x + (end_x - start_x) / 2 - (progress_bar * AudioService:getCurrentTime() / AudioService:getDuration()) / 2,
        judgePos + 30, AudioService:getCurrentTime() / AudioService:getDuration() * progress_bar, 5)

    love.graphics.rectangle("fill", start_x + (end_x - start_x) / 2 - progress_bar / 2, judgePos + 29, 1, 7)
    love.graphics.rectangle("fill", start_x + (end_x - start_x) / 2 + progress_bar / 2, judgePos + 29, 1, 7)

    --判定线
    love.graphics.setColor(ThemeService:judgeColor(settings.theme, 'inner') or play.colors.dcyan) --判定线内部
    love.graphics.rectangle("fill", start_x, judgePos - 5, end_x - start_x, 10)


    love.graphics.setColor(ThemeService:judgeColor(settings.theme, 'outer') or play.colors.white) --判定线外框

    love.graphics.rectangle("line", start_x, judgePos - 8, end_x - start_x, 16) --8是为了对其中心
    love.graphics.pop()
    if demo.open then love.graphics.setShader() end
end

function demoPlay:settings()
    to3d_shader:send("tanAngle", math.tan(settings.angle / 180 * math.pi)) --透视强度
    to3d_shader:send("judge", (settings.judge_line_y - layout.y) / layout.h / self.sh)
end

function demoPlay:resize(w, h)
    --shader需要原始坐标
    print(w, h)
    to3d_shader:send("rectangle", (WINDOW.nowW - WINDOW.scale * WINDOW.w) / 2, (WINDOW.nowH - WINDOW.scale * WINDOW.h) /
    2, self.sw * layout.w * WINDOW.scale, self.sh * layout.h * WINDOW.scale)
end

return demoPlay
