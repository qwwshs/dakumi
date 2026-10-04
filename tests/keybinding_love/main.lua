-- 只用内存中的键位文件验证录入、确认、取消和运行时组合键判断。
local root = love.filesystem.getSource():gsub('[/\\]tests[/\\]keybinding_love[/\\]?$', '')
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path
require('src.utils.table')
dkjson = require('src.utils.dkjson')
meta_key = {__index = {copy = {'ctrl', 'c'}, play = {'space'}, undo = {'ctrl', 'z'}}}
PATH = {base = root, usersPath = {key = 'users/'}}
iskeyboard = {ctrl = false, alt = false, shift = false}
log = function() end
save = function() end
local writes = {}
nativefs = {
    mount = function() return true end,
    unmount = function() return true end,
    read = function() return '{"copy":["ctrl","c"],"play":["space"]}' end,
    write = function(path, data)
        writes[#writes + 1] = {path = path, data = data}
        return true
    end,
}

local input = require('src.utils.input')
input:init({fs=nativefs, json=dkjson, keyboard=iskeyboard, defaults=meta_key.__index, path='users/key.json'})
local capture = require('src.services.keyCapture')
local function run()
    assert(input:getBinding('undo')[2] == 'z', 'default key was not filled')
    assert(capture:begin('copy'))
    assert(capture:keypressed('lctrl', false))
    assert(capture:keypressed('lshift', false))
    assert(capture:keypressed('x', false))
    assert(capture:keypressed('x', true))
    capture:keyreleased('x')
    assert(not capture:isReady(), 'saved before all keys released')
    capture:keyreleased('lctrl')
    assert(not capture:isReady())
    capture:keyreleased('lshift')
    assert(capture:isReady() and capture:getDisplay() == 'Ctrl + Shift + X')
    assert(input:getBinding('copy')[2] == 'c' and #writes == 0, 'binding changed before confirmation')
    assert(capture:confirm())
    assert(not capture:isActive() and #writes == 1 and writes[1].path == 'users/key.json')
    local stored = dkjson.decode(writes[1].data)
    assert(stored.copy[1] == 'ctrl' and stored.copy[2] == 'shift' and stored.copy[3] == 'x')
    assert(stored.play[1] == 'space' and stored.undo[2] == 'z', 'unrelated keys were lost')

    iskeyboard.ctrl, iskeyboard.lctrl = true, true
    iskeyboard.shift, iskeyboard.lshift = true, true
    iskeyboard.x = true
    assert(input('copy'), 'new combination did not take effect')
    iskeyboard.c = true
    assert(not input('copy'), 'extra pressed key matched shortcut')
    iskeyboard.c = false
    iskeyboard.shift, iskeyboard.lshift = false, false
    assert(not input('copy'), 'incomplete combination matched shortcut')

    assert(capture:begin('play'))
    capture:keypressed('tab', false)
    capture:keyreleased('tab')
    capture:cancel()
    assert(input:getBinding('play')[1] == 'space' and #writes == 1, 'cancel changed binding')
    nativefs.write = function() return false, 'disk error' end
    assert(capture:begin('play'))
    capture:keypressed('tab', false)
    capture:keyreleased('tab')
    assert(not capture:confirm() and capture:isActive())
    assert(input:getBinding('play')[1] == 'space', 'failed save changed runtime binding')
    capture:cancel()
    nativefs.write = function() error('write exception') end
    assert(capture:begin('play'))
    capture:keypressed('tab', false)
    capture:keyreleased('tab')
    assert(not capture:confirm() and capture:isActive())
    assert(input:getBinding('play')[1] == 'space', 'write exception changed runtime binding')
    capture:cancel()
    print('PASS: combination capture, full release, confirmation, persistence, cancellation and failure')
end

function love.load()
    local ok, err = xpcall(run, debug.traceback)
    if not ok then print(err) end
    love.event.quit(ok and 0 or 1)
end
