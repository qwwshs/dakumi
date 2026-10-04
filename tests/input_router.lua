-- LuaJIT 5.1：无窗口、无文件系统、无应用全局变量的输入消费回归。
local Router = require('src.services.inputRouter')
local calls, consumed, errors = {}, {}, {}
local active = {uiWheelmoved=function() calls[#calls+1]='uiWheel' end,
    inputBeforeUI=function(_, method, x) return method=='mousepressed' and x==12 end}
local root = setmetatable({__type='test', getRoom=function() return active end},
    {__call=function(_, method, ...) calls[#calls+1]={method, ...} end})
local ui = {}
for _, method in ipairs({'keypressed','keyreleased','mousepressed','mousereleased','mousemoved','wheelmoved','textinput'}) do
    ui[method] = function() if consumed[method]=='error' then error('UI failure') end; return consumed[method] end
end
local capture = {active=false,isActive=function(self) return self.active end,
    keypressed=function(self,key) self.pressed=key end,
    keyreleased=function(self,key) self.released=key end,
    cancel=function(self) self.active=false end}
local keyboard, mouse, uiKeyboard = {}, {}, {}
local router = Router.new({ui=ui,root=root,capture=capture,keyboard=keyboard,mouse=mouse,uiKeyboard=uiKeyboard,
    window={w=100,h=100,scale=2,nowW=240,nowH=200},
    report=function(...) errors[#errors+1]={...} end})
local function reset() calls={} end
router:dispatch('keypressed','lctrl','lctrl',false)
router:dispatch('keypressed','rctrl','rctrl',false)
router:dispatch('keyreleased','lctrl','lctrl')
assert(keyboard.ctrl and keyboard.rctrl and not keyboard.lctrl)
router:dispatch('keyreleased','rctrl','rctrl'); assert(not keyboard.ctrl)
reset(); consumed.keypressed=true
router:dispatch('keypressed','s','s',false)
assert(uiKeyboard.s and not keyboard.s,'UI key state was mixed with editor shortcuts')
router:dispatch('keyreleased','s','s'); assert(not uiKeyboard.s)
assert(#calls==0 and not keyboard.s,'UI consumed key leaked into shortcut state')
consumed.keypressed=false
router:dispatch('keypressed','kp1','kp1',false)
consumed.keyreleased=true;router:dispatch('keyreleased','kp1','kp1')
assert(calls[1][2]=='1' and calls[2][2]=='1' and not keyboard.kp1)
reset();router:dispatch('mousepressed',60,40,1,false)
assert(mouse.x==20 and mouse.y==20 and calls[1][2]==20,'wrong letterbox coordinates')
consumed.mousemoved=true;consumed.mousereleased=true
router:dispatch('mousemoved',80,60,20,20,false)
router:dispatch('mousereleased',100,80,1,false)
assert(calls[2][1]=='mousemoved' and calls[2][4]==10)
assert(calls[3][1]=='mousereleased' and calls[3][2]==40 and calls[3][3]==40)
assert(not mouse.down,'drag remained held')
reset();consumed.mousepressed=true
router:dispatch('mousepressed',60,40,1,false);router:dispatch('mousereleased',60,40,1,false)
assert(#calls==0,'UI click leaked to chart')
reset();router:dispatch('mousepressed',44,40,1,false);router:dispatch('mousereleased',44,40,1,false)
assert(#calls==0,'priority control leaked')
reset();consumed.wheelmoved=true;router:dispatch('wheelmoved',0,-1)
assert(#calls==1 and calls[1]=='uiWheel')
reset();consumed.wheelmoved=false;router:dispatch('wheelmoved',0,-1)
assert(calls[1][1]=='wheelmoved')
reset();consumed.textinput=true;router:dispatch('textinput','a');assert(#calls==0)
capture.active=true;router:dispatch('keypressed','x','x',false)
router:dispatch('keyreleased','x','x');router:dispatch('wheelmoved',0,-1)
assert(capture.pressed=='x' and capture.released=='x' and #calls==0 and not keyboard.x)
capture.active=false;consumed.keypressed='error';router:dispatch('keypressed','z','z',false)
assert(#errors==1 and #calls==0 and not keyboard.z)
consumed.keypressed=false;consumed.mousepressed=false
router:dispatch('keypressed','lshift','lshift',false)
router:dispatch('mousepressed',60,40,1,false)
router:dispatch('focus',false)
assert(not keyboard.shift and not mouse.down and next(router.keys)==nil)
assert(calls[#calls][1]=='mousereleased','focus loss did not end scene drag')
print('PASS: input consumption, modal capture, modifier state, drag ownership, coordinates, errors and focus loss')
