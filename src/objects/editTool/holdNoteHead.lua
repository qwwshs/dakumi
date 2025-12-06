local holdNoteHead = object:new('holdNoteHead')

holdNoteHead.v = 0
holdNoteHead.value = true --为了适应之前的谱面格式 所以用了两套变量 而且Nui的开关是反的
holdNoteHead.type = 'switch'
holdNoteHead.text = 'note head'

function holdNoteHead:update(dt)
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end

return holdNoteHead