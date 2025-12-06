local holdWipeHead = object:new('holdWipeHead')

holdWipeHead.v = 0
holdWipeHead.value = true --为了适应之前的谱面格式 所以用了两套变量 而且Nui的开关是反的
holdWipeHead.type = 'switch'
holdWipeHead.text = 'wipe head'

function holdWipeHead:update(dt)
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end

return holdWipeHead