local holdNoteHead = object:new('holdNoteHead')

holdNoteHead.v = 0
holdNoteHead.value = true --Nui的开关是反的
holdNoteHead.type = 'switch'
holdNoteHead.text = 'note head'

function holdNoteHead:update(dt)
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end

function holdNoteHead:to(v)
    self.value = v
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
    log(self.value)
end

return holdNoteHead