messageBox = object:new('messageBox')
messageBox.message = {} -- 消息列表

function messageBox:draw()
    for i = 1,#self.message do
        local alpha = 0.75 - 0.75 * easings.out_cubic((elapsed_time-self.message[i].st) /3) --透明度
        local y = 300 +  (#self.message - i) * 35
        local w = love.graphics.getFont():getWidth(self.message[i].text) + 10
        love.graphics.setColor(0.3,0.3,0.3,alpha)  -- 背景板
        love.graphics.rectangle("fill",0,y,w,25)
        love.graphics.setColor(1,1,1,alpha)
        love.graphics.rectangle("line",0,y,w,25)

        love.graphics.setColor(1,1,1,alpha)  --文字
        love.graphics.printf(self.message[i].text,0,y,w,'center')
    end
end
function messageBox:add(mess) -- 增加信息
    table.insert(self.message,{text = i18n:get(tostring(mess)),st = elapsed_time,alpha = 100})
    for i = 1,#self.message do
        if self.message[i] and elapsed_time - self.message[i].st >= 3 then --时间超过三秒
            table.remove(self.message,i)
        end
    end
    
end