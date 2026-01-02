edit = room:new("edit")
room:addRoom(edit)

play = require 'src.rooms.play'
sidebar = require 'src.rooms.sidebar'
editTool = require 'src.rooms.editTool'
demo = require 'src.rooms.demo'

edit:addGroup(editTool)
edit:addGroup(play)
edit:addGroup(sidebar)
edit:addGroup(demo)
bezier_index = 1 --默认贝塞尔索引
easings_index = 1 --默认缓动索引
function edit:load()
    self('load')
end

function edit:update(dt)
    self('update',dt)
end

function edit:draw()
    self('draw')
end

function edit:keypressed(key)
    self('keypressed',key)
end

function edit:keyreleased(key)
    self('keyreleased',key)
end

function edit:mousepressed( x, y, button, istouch, presses )
    self('mousepressed',x, y, button)
end

function edit:mousereleased( x, y, button, istouch, presses )
    self('mousereleased',x, y, button)
end

function edit:wheelmoved(x,y)
    self('wheelmoved',x,y)
end

function edit:textinput(input)
    self('textinput',input)
end

function edit:quit()
    self('quit')
end