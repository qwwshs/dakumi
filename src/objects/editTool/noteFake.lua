local noteFake = object:new('noteFake')

noteFake.v = 0
noteFake.value = false
noteFake.type = 'switch'
noteFake.text = 'note fake'

function noteFake:update(dt)
    if self.value then
        self.v = 1
    else 
        self.v = 0
    end
end

function noteFake:to(v)
    self.value = v
    if self.value then
        self.v = 1
    else 
        self.v = 0
    end
end


return noteFake