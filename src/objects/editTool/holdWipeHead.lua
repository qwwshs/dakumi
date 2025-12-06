local holdWipeHead = object:new('holdWipeHead')

holdWipeHead.v = 0
holdWipeHead.value = true --Nui的开关是反的
holdWipeHead.type = 'switch'
holdWipeHead.text = 'wipe head'

function holdWipeHead:update(dt)
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end

function holdWipeHead:to(v)
    self.value = v
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end


return holdWipeHead