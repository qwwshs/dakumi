local AudioService = require('src.services.audioService')
local play = group:new('play')
local ChartService = require("src.services.chartService")
local CoordinateService = require("src.services.coordinateService")
local ThemeService = require("src.services.themeService")
local editState = require("src.utils.editState") -- 插件接管交互的状态（核心持有）
play.now_all_track_pos = {} --现在所有轨道的属性
local EffectService = require('src.services.effectService')
play.effect = {} -- 按轨道编号保存当前效果
play.layout = require 'config.layouts.play'
play.colors = require 'config.colors.play'
function play:get_all_track_pos()
    return play.now_all_track_pos
end

function play:get_effect(trackId)
    return self.effect[trackId] or EffectService:defaults()
end

function play:get_init_effect()
    return EffectService:defaults()
end

function play:load()
    self('load')
end

function play:mouseInPlay()
    return math.intersect(mouse.x, mouse.x, self.layout.x, self.layout.x + self.layout.w) and
        math.intersect(mouse.y, mouse.y, self.layout.y, self.layout.y + self.layout.h)
end

function play:mouseInEdit()
    return math.intersect(mouse.x, mouse.x, self.layout.edit.x, self.layout.edit.x + self.layout.edit.w) and
        math.intersect(mouse.y, mouse.y, self.layout.edit.y, self.layout.edit.y + self.layout.edit.h)
end

function play:mouseInDemo()
    return math.intersect(mouse.x, mouse.x, self.layout.demo.x, self.layout.demo.x + self.layout.demo.w) and
        math.intersect(mouse.y, mouse.y, self.layout.demo.y, self.layout.demo.y + self.layout.demo.h)
end

function play:update(dt)

    self('update', dt)
    play.now_all_track_pos = {}
    local all_track = fTrack:track_get_all_track()
    play.effect = EffectService:calculate(all_track, AudioService:getCurrentBeat())
    for i = 1, #all_track do
        local x, w = fEvent:get(all_track[i], AudioService:getCurrentBeat())
        local track_x, track_w = fTrack:to_play_track(x, w)
        play.now_all_track_pos[all_track[i]] = { x = x, w = w, track_x = track_x, track_w = track_w }
    end
end

function play:draw()
    if demo.open then
        return
    end
    -- 主题可单独指定 demo 底色；未配置时日间沿用黑底。
    local demoColor = ThemeService:editorColor(settings.theme, 'demo_background')
    if demoColor or settings.theme == 'light' then
        love.graphics.setColor(demoColor or {0, 0, 0, 1})
        love.graphics.rectangle('fill', self.layout.demo.x, self.layout.demo.y,
            self.layout.demo.w, self.layout.demo.h)
    end
    love.graphics.setColor(1, 1, 1, settings.bg_alpha / 100)

    if bg then -- 背景存在就显示
        --图像范围限制函数
        local function myStencilFunction()
            love.graphics.rectangle("fill", self.layout.demo.x, self.layout.demo.y, self.layout.demo.x +
                self.layout.demo.w, self.layout.demo.h)
        end

        love.graphics.stencil(myStencilFunction, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        local bg_width, bg_height = bg:getDimensions() -- 得到宽高
        local bg_scale_h = 1 / bg_height * WINDOW.h
        local bg_scale_w = 1 / bg_height * WINDOW.h / (WINDOW.scale / WINDOW.scale)
        if demo.open then
            bg_scale_h = 1 / bg_height * WINDOW.h
            bg_scale_w = 1 / bg_height * WINDOW.h / (WINDOW.scale / WINDOW.scale) / (1 / (self.layout.demo.w / WINDOW.w))
        end

        love.graphics.draw(bg, self.layout.x + self.layout.w / 2 - (bg_width * bg_scale_w) / 2, 0, 0, bg_scale_w,
            bg_scale_h) --居中显示

        love.graphics.setStencilTest()
    end


    self('draw')

    love.graphics.setColor(1, 1, 1) --总 note event 数
    local str = 'note: ' .. ChartService:getNoteCount() .. '  event: ' .. ChartService:getEventCount()
    love.graphics.printf(str, self.layout.demo.x, settings.judge_line_y + 60, self.layout.demo.w, "center")

    if ChartService:isEditingEffect() then return end
    --event渲染 于demo侧
    for _, eventType in pairs(event_property_type) do
        love.graphics.setColor(self.colors.eventInDemo[eventType])
        if not ChartService:hasTrack(track.track) then
            break
        end
        local eventCount = ChartService:getTrackEventCount(track.track, eventType)
        for i = eventCount, 1, -1 do
            local isevent = ChartService:getTrackEvent(track.track, eventType, i)
            local y = CoordinateService:toY(isevent:getBeatValue())
            local y2 = CoordinateService:toY(isevent:getBeat2Value())
            if not (y2 > WINDOW.h or y < 0) then
                -- beizer曲线
                for k = 1, 100 do
                    local nowx = fTrack:to_play_track_x(isevent:getFrom()) +
                        fEvent:getTrans(isevent, k / 100) *
                        (fTrack:to_play_track_x(isevent:getTo()) - fTrack:to_play_track_x(isevent:getFrom()))
                    local nowy = y + (y2 - y) * k / 100
                    love.graphics.rectangle("fill", nowx, nowy - (y2 - y) / 100, 5, (y2 - y) / 100) --减去一个 (y2 - y)/10是为了与头对齐
                end
            elseif y2 > WINDOW.h then
                break
            end
        end
    end

    --栅栏绘制
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    local track_start_x = fTrack:to_play_track(-x_offset, 0)
    local track_end_x = fTrack:to_play_track(-x_offset + event_scale, 0)
    local track_width = track_end_x - track_start_x

    love.graphics.setColor(self.colors.white_half)
    for i = 1, track.fence do
        love.graphics.rectangle("fill", track_start_x + track_width / track.fence * i, self.layout.demo.y,
            2, self.layout.demo.h)
    end
    if track_width / track.fence * fTrack:track_get_near_fence() < track_width then
        love.graphics.setColor(self.colors.cyan_bright)
        love.graphics.rectangle("fill", track_start_x + track_width / track.fence * fTrack:track_get_near_fence(),
            self.layout.demo.y, 2, self.layout.demo.h)
    end
end

function play:keypressed(key)
    if not math.intersect(mouse.x, mouse.x, self.layout.x, self.layout.x + self.layout.w) then --限制范围
        return
    end
    if tabs and tabs:isRenaming() then --重命名时按键只交给标签页
        return
    end
    self('keypressed', key)
end

function play:wheelmoved(x, y)
    if not math.intersect(mouse.x, mouse.x, self.layout.x, self.layout.x + self.layout.w) then --限制范围
        return
    end
    self('wheelmoved', x, y)
end

function play:mousepressed(x, y, button, istouch, presses)
    --限制范围（包含标签条与拖动条）
    if not self:mouseInPlay() then
        return
    end
    self('mousepressed', x, y, button, istouch, presses)

    
    if self:mouseInDemo() and love.mouse.isDown(1) and not editState.demoCaptured and tabs:isSingle() then -- 选择轨道 在demo区域
        messageBox:add("track click")
        local local_track = {}
        for i = 1, ChartService:getEventCount() do                                   --点击轨道进入轨道的编辑事件
            local e = ChartService:getEvent(i)
            if not table.find(local_track, e:getTrack()) then --不存在 记录
                local track_x, track_w = fEvent:get(e:getTrack(), AudioService:getCurrentBeat())
                track_x, track_w = fTrack:to_play_track(track_x, track_w)
                if math.intersect(x, x, track_x, track_w + track_x) then
                    local_track[#local_track + 1] = e:getTrack()
                end
            end
            if e:getBeatValue() > AudioService:getCurrentBeat() then
                break
            end
        end
        for i = 1, #local_track do
            if local_track[i] == track.track then --这么写的意义是为了多轨道重叠的时候能顺利的选到全部轨道
                if i + 1 <= #local_track then
                    track:to('track', local_track[i + 1])
                    break
                else
                    track:to('track', local_track[1])
                    break
                end
            elseif not table.find(local_track, track.track) then --没点到当前轨道
                track:to('track', local_track[i])
                break
            end
        end
    end
end

function play:mousereleased(x, y, button, istouch, presses)
    if not self:mouseInPlay() then --限制范围
        return
    end
    self('mousereleased', x, y, button, istouch, presses)
end

function play:settings()
    self('settings')
end

-- 核心对象留出层间隔，插件可在任意两层之间插入。
play:addObject(require 'src.objects.play.note', 10)
play:addObject(require 'src.objects.play.event', 20)
play:addObject(require 'src.objects.play.demoPlay', 30)
play:addObject(require 'src.objects.play.demoInEdit', 40)
play:addObject(require 'src.objects.play.denomPlay', 50)
play:addObject(require 'src.objects.play.demoNowX', 60)
play:addObject(require 'src.objects.play.slider', 80)
hit = require 'src.objects.play.hit'
play:addObject(hit, 120)
return play
