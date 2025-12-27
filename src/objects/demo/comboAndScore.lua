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
function comboAndScore:update(dt)
    --计算
    local combo = 0
    local allTrueNote = 0
    for i = 1,#chart.note do
        local n = chart.note[i]
        if n.fake == 0 then
            allTrueNote = allTrueNote + 1
            if beat:get(n.beat) <= beat.nowbeat and n.fake == 0 then
                combo = combo + 1
            end
        end
    end
    self.score = tostring(math.floor(1000000 * combo / allTrueNote))
    self.combo = tostring(combo)
    --补0
    while #self.score < 7 do
        self.score = '0' .. self.score
    end
end

function comboAndScore:draw()
    local scale = comboAndScore.scoreLayout.size* 1 / self.numtab.w
    local interval = comboAndScore.scoreLayout.size
    setColor(demo.colors.combo)
    for i = 1,#self.combo do
        local v = string.sub(self.combo,i,i)
        if #v < 1 then break end
        local img = self.numtab[tonumber(v)]
        local x = self.comboLayout.x + (i - #self.combo / 2) * interval - comboAndScore.scoreLayout.size --love2d图片位置不是以中点算的
        love.graphics.draw(img,x,settings.judge_line_y + self.comboLayout.y,0,scale,scale)
    end
    setColor(demo.colors.score)
    for i = 1,#self.score do
        local v = string.sub(self.score,i,i)
        if #v < 1 then break end
        local img = self.numtab[tonumber(v)]
        local x = self.scoreLayout.x + (i - #self.score / 2) * interval - comboAndScore.scoreLayout.size --love2d图片位置不是以中点算的
        love.graphics.draw(img,x,settings.judge_line_y + self.scoreLayout.y,0,scale,scale)
    end

end

return comboAndScore