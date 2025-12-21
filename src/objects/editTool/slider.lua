local slider = object:new('slider')
local layout = require 'config.layouts.editTool'
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
    love.graphics.setColor(0.15,0.15,0.15,0.7)
    love.graphics.rectangle('fill',self.x,self.y,self.w,self.h) -- 框
    love.graphics.setColor(1,1,1,1)

    local local_tab = {1} --用来计算密度的
    for i = 1 ,100 do
        local_tab[i] = 1
    end
    --全谱平均note密度表示 分成100部分
    for i = 1, #chart.note do
        local pos = math.floor(beat:toTime(chart.bpm_list,beat:get(chart.note[i].beat)) / time.alltime * 100)
        if not local_tab[pos] then --超界
            local_tab[pos] = 1 
        end

        local_tab[pos] = local_tab[pos] + 1
    end
    --换算成相对高度
    local max =local_tab[1]
    local min =  local_tab[1]
    for i = 1, 100 do
        if max < local_tab[i] then
            max = local_tab[i]
        end
        if local_tab[i] < min then
            min = local_tab[i]
        end
    end
    if max == min then max = min + 1 end
    for i = 1, 100, 1 do
        local max_h = self.w
        local density_ratio = (local_tab[i]-min) / (max - min) --密度比例
        love.graphics.setColor(density_ratio * 1,1 - density_ratio * 1,1 - density_ratio * 1,1)
        love.graphics.rectangle("fill",self.x,self.y+ self.h - self.h / 100 * i,density_ratio * max_h,self.h / 100)
    end

    love.graphics.setColor(1,1,1,0.5)
    love.graphics.rectangle('line',self.x,self.y,self.w,self.h) -- 框
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle('fill',self.x,self.now_y,self.w,4) --现在所在位置点 
    if slider.down then
        love.graphics.setColor(1,1,1,1) 
        love.graphics.print(i18n:get("nowtime")..":"..math.roundToPrecision(time.nowtime,100).."\n"..
        i18n:get("beat")..":"..math.roundToPrecision(beat.nowbeat,100),self.x+self.w,self.now_y)
    end

end
function slider:update(dt)
    self.now_y = -(time.nowtime / time.alltime * self.h) + self.y + self.h
    local y1 = mouse.y
    if  y1 < self.y then y1 = self.y  end ---限制范围
    if y1 > self.y + self.h then  y1 = self.y + self.h  end
    if slider.down  then
        music_play = false
        self.now_y = y1
        time.nowtime = -(self.now_y-self.y - self.h) / self.h  * time.alltime
        beat.nowbeat = beat:toBeat(chart.bpm_list,time.nowtime)
    end
end
function slider:mousepressed(x1,y1)
    if not (math.intersect(y1,y1,self.y - 10,self.y + self.h + 10) and math.intersect(x1,x1,self.x-10,self.x+self.w+10)) then --加减10是为了更好抓取
        return
    end
    slider.down = true
    music_play = false
end
function slider:mousereleased(x1,y1)
    self.down = false
end

return slider