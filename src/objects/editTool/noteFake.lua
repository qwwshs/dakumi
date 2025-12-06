local noteFake = object:new('noteFake')

noteFake.v = 0
noteFake.value = true --为了适应之前的谱面格式 所以用了两套变量 而且Nui的开关是反的
noteFake.type = 'switch'
noteFake.text = 'note fake'

function noteFake:update(dt)
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end

function noteFake:to(v)
    self.value = v
    if self.value then
        self.v = 0
    else 
        self.v = 1
    end
end


return noteFake