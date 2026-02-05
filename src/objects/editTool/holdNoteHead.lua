local holdNoteHead = object:new('holdNoteHead')

holdNoteHead.v = 0
holdNoteHead.value = false
holdNoteHead.type = 'switch'
holdNoteHead.text = 'note head'

function holdNoteHead:update(dt)
    if self.value then
        self.v = 1
    else 
        self.v = 0
    end
end

function holdNoteHead:to(v)
    self.value = v
    if self.value then
        self.v = 1
    else 
        self.v = 0
    end
    log(self.value)
end

return holdNoteHead