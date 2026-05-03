local comboAndScore = object:new('comboAndScore') --连击与分数显示
comboAndScore.scoreLayout = require 'config.layouts.demo'.score
comboAndScore.comboLayout = require 'config.layouts.demo'.score.combo
comboAndScore.combo = '0'
comboAndScore.score = '0000000'
comboAndScore.numtab = {}
for i = 0,11 do
    comboAndScore.numtab[i] = love.graphics.newImage("assets/img/font-combo-"..i..".png")
end
comboAndScore.numtab.w,comboAndScore.numtab.h = comboAndScore.numtab[0]:getDimensions()



local combo = 0
local allTrueNote = 0
local previous_frame_beat = 0 -- 上一帧的节拍
local previous_frame_starting_point = 1 -- 上一帧的遍历起点

function comboAndScore:opened()
    combo = 0
    allTrueNote = 0
    previous_frame_beat = 0
    previous_frame_starting_point = 1

    --算真note数量
    for i, n in ipairs(chart.note) do
        local _,w = fEvent:get(n.track,beat:get(n.beat))
        if n.fake == 0 and w ~= 0 then
            allTrueNote = allTrueNote + 1
        end
    end
end

function comboAndScore:update(dt)
    if previous_frame_beat == beat.nowbeat then
        return
    end
    previous_frame_beat = beat.nowbeat
    for i = math.max(previous_frame_starting_point,1),#chart.note do
        local n = chart.note[i]
        local _,w = fEvent:get(n.track,beat:get(n.beat))
        if beat:get(n.beat) < beat.nowbeat and n.fake == 0 and w ~= 0 then
            combo = combo + 1
        end
        if beat:get(n.beat) > beat.nowbeat then
            previous_frame_starting_point = i
            break
        end
    end
    self.score = tostring(math.min(math.floor(1000000 * combo / allTrueNote), 1000000))
    self.combo = tostring(math.min(combo, allTrueNote))
    --补0
    while #self.score < 7 do
        self.score = '0' .. self.score
    end
end

function comboAndScore:draw()
    local scale = comboAndScore.scoreLayout.size* 1 / self.numtab.w
    local interval = comboAndScore.scoreLayout.size
    love.graphics.setColor(demo.colors.combo)
    local v
    local img
    local x
    for i = 1,#self.combo do
        v = string.sub(self.combo,i,i)
        if #v < 1 then break end
        img = self.numtab[tonumber(v)]
        x = self.comboLayout.x + (i - #self.combo / 2) * interval - comboAndScore.scoreLayout.size --love2d图片位置不是以中点算的
        love.graphics.draw(img,x,settings.judge_line_y + self.comboLayout.y,0,scale,scale)
    end
    love.graphics.setColor(demo.colors.score)
    for i = 1,#self.score do
        v = string.sub(self.score,i,i)
        if #v < 1 then break end
        img = self.numtab[tonumber(v)]
        x = self.scoreLayout.x + (i - #self.score / 2) * interval - comboAndScore.scoreLayout.size --love2d图片位置不是以中点算的
        love.graphics.draw(img,x,settings.judge_line_y + self.scoreLayout.y,0,scale,scale)
    end

end

return comboAndScore