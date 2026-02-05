local holdWipeHead = object:new('holdWipeHead')

holdWipeHead.v = 0
holdWipeHead.value = false
holdWipeHead.type = 'switch'
holdWipeHead.text = 'wipe head'

function holdWipeHead:update(dt)
    if self.value then
        self.v = 1
    else 
        self.v = 0
    end
end

function holdWipeHead:to(v)
    self.value = v
    if self.value then
        self.v = 1
    else 
        self.v = 0
    end
end


return holdWipeHead