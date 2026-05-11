local slider = object:new('slider')
local layout = require 'config.layouts.play'
slider.now_y = layout.slider.y + layout.slider.h --现在所在y位置
slider.x = layout.slider.x
slider.y = layout.slider.y
slider.r = layout.slider.r
slider.w = layout.slider.w
slider.h = layout.slider.h
slider.down = false

function slider:draw()
    if demo.open then
        return
    end
    love.graphics.setColor(editTool.colors.slider)
    love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

    love.graphics.setColor(editTool.colors.sliderLine)
    love.graphics.rectangle('line', self.x, self.y, self.w, self.h) -- 框
    love.graphics.setColor(editTool.colors.progress)
    love.graphics.rectangle('fill', self.x, self.now_y, self.w, 4) --现在所在位置点
end

function slider:update(dt)
    self.now_y = -(time.nowtime / time.alltime * self.h) + self.y + self.h
    local y1 = mouse.y
    if y1 < self.y then y1 = self.y end   ---限制范围
    if y1 > self.y + self.h then y1 = self.y + self.h end
    if slider.down then
        music_play = false
        self.now_y = y1
        time.nowtime = -(self.now_y - self.y - self.h) / self.h * time.alltime
        beat.nowbeat = beat:toBeat(chart.bpm_list, time.nowtime)
        if Nui:windowBegin("slider", self.x, self.y,0,0) then
            Nui:tooltip("nowtime" .. ":" .. math.roundToPrecision(time.nowtime, 100) .. " " .. "beat" .. ":" .. math.roundToPrecision(beat.nowbeat, 100))
        end
        Nui:windowEnd()
    end
end

function slider:mousepressed(x1, y1)
    if not (math.intersect(y1, y1, self.y - 10, self.y + self.h + 10) and math.intersect(x1, x1, self.x - 10, self.x + self.w + 10)) then --加减10是为了更好抓取
        return
    end
    slider.down = true
    music_play = false
end

function slider:mousereleased(x1, y1)
    self.down = false
end

return slider
