local room = require("src.utils.room").room
local edit = room:new("edit")
_G.edit = edit
local SpectrogramRuler = require('src.services.spectrogramRuler')

local play = require 'src.rooms.play'
_G.play = play
local sidebar = require 'src.rooms.sidebar'
_G.sidebar = sidebar
local editTool = require 'src.rooms.editTool'
_G.editTool = editTool
local demo = require 'src.rooms.demo'
_G.demo = demo
local tabs = require 'src.rooms.tabs'
_G.tabs = tabs

transIndex = {
    bezier = 1, --默认贝塞尔索引
    easings = 1 --默认缓动索引
}
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

-- 特殊控件的优先命中属于场景，输入路由不依赖 tabs。
function edit:inputBeforeUI(method, x, y, button)
    if demo.open then return false end
    if method == 'mousepressed' then return tabs:handleRulerToggleClick(x, y, button) end
    if method == 'keypressed' and tabs:isRenaming() then
        tabs:keypressed(x)
        return true
    end
end

-- UI 消费滚轮后仅通知侧栏，保留列表滚动补偿，不广播到编辑轨道。
function edit:uiWheelmoved(x, y)
    sidebar:wheelmoved(x, y)
end

function edit:mousepressed( x, y, button, istouch, presses )
    if SpectrogramRuler:contains(x, y) then return end
    self('mousepressed',x, y, button)
end

function edit:mousereleased( x, y, button, istouch, presses )
    self('mousereleased',x, y, button)
end

function edit:wheelmoved(x,y)
    if SpectrogramRuler:wheelmoved(x,y) then return end
    self('wheelmoved',x,y)
end

function edit:textinput(input)
    self('textinput',input)
end

function edit:settings()
    self('settings')
end

function edit:resize(w, h)
    self('resize',w,h)
end

function edit:quit()
    self('quit')
end


edit:addGroup(play, 10)
edit:addGroup(demo, 20)
edit:addGroup(editTool, 30)
edit:addGroup(tabs, 40)
edit:addGroup(sidebar, 50)

room:addRoom(edit, 0)

return edit
