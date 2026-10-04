-- 输入入口只依赖构造时传入的服务，可在没有全局变量、窗口和文件系统时测试。
local Router = {}
Router.__index = Router
local Coordinate = require('src.services.coordinateService')
local aliases = {lctrl='ctrl', rctrl='ctrl', lalt='alt', ralt='alt', lshift='shift', rshift='shift'}
local function sceneKey(key)
    if key:match('^kp%d$') then return key:sub(3) end
    return key
end
function Router.new(options)
    assert(options.ui and options.root and options.keyboard and options.mouse and options.window)
    return setmetatable({services=options, keys={}, buttons={}, physical={}}, Router)
end
function Router:ui(method, ...)
    local ui = self.services.ui
    if not ui[method] then return false end
    local ok, consumed = pcall(ui[method], ui, ...)
    if not ok then
        if self.services.report then self.services.report('input UI error', method, consumed) end
        return true -- UI 出错时不把同一事件误送成谱面编辑操作。
    end
    return consumed == true
end
function Router:scene(method, ...)
    local root = self.services.root
    return root(method, ...)
end
function Router:activeScene()
    local root = self.services.root
    return root:getRoom(root.__type)
end
function Router:setKey(key, down, target)
    local keyboard = target or self.services.keyboard
    keyboard[key] = down
    local alias = aliases[key]
    if alias then
        keyboard[alias] = false
        for physical, normalized in pairs(aliases) do
            if normalized == alias and keyboard[physical] then keyboard[alias] = true end
        end
    end
end
function Router:pointer(x, y)
    local s = self.services
    x, y = Coordinate:screenToGame(x, y, s.window)
    s.mouse.x, s.mouse.y = x, y
    return x, y
end
function Router:dispatch(method, ...)
    local s, args = self.services, {...}
    local modal = s.capture and s.capture:isActive()
    if modal and not self.wasModal then
        for key in pairs(self.keys) do
            self:setKey(key, false)
            self:scene('keyreleased', sceneKey(key))
        end
        self.keys = {}
    end
    self.wasModal = modal
    if method == 'focus' then
        if args[1] == false then
            for key in pairs(self.physical) do self:ui('keyreleased', key) end
            for key in pairs(self.keys) do self:setKey(key, false); self:scene('keyreleased', sceneKey(key)) end
            for button, owner in pairs(self.buttons) do
                local window = s.window
                local screenX = s.mouse.x * window.scale + (window.nowW-window.w*window.scale)/2
                local screenY = s.mouse.y * window.scale + (window.nowH-window.h*window.scale)/2
                if owner ~= 'control' then self:ui('mousereleased', screenX, screenY, button) end
                if owner == 'scene' then self:scene('mousereleased', s.mouse.x, s.mouse.y, button) end
            end
            for key in pairs(s.keyboard) do s.keyboard[key] = false end
            self.keys, self.buttons, self.physical = {}, {}, {}
            if s.uiKeyboard then for key in pairs(s.uiKeyboard) do s.uiKeyboard[key] = false end end
            s.mouse.down = false
            if modal then s.capture:cancel() end
        end
        return
    elseif method == 'keypressed' then
        local key = args[1]
        self.physical[key] = true
        if modal then s.capture:keypressed(key, args[3]); return true end
        if s.uiKeyboard then self:setKey(key, true, s.uiKeyboard) end
        local consumed = self:ui(method, ...)
        local scene = self:activeScene()
        if scene and scene.inputBeforeUI and scene:inputBeforeUI(method, key, args[2], args[3]) then return true end
        if consumed then return true end
        self.keys[key] = true
        self:setKey(key, true)
        self:scene(method, sceneKey(key), args[2], args[3])
    elseif method == 'keyreleased' then
        local key, owned = args[1], self.keys[args[1]]
        self.physical[key], self.keys[key] = nil, nil
        if s.uiKeyboard then self:setKey(key, false, s.uiKeyboard) end
        self:setKey(key, false) -- UI 或弹窗消费释放事件也不能留下卡住的按键。
        local consumed = self:ui(method, ...)
        if modal then s.capture:keyreleased(key); return true end
        if owned then self:scene(method, sceneKey(key), args[2]) end
        return consumed
    elseif method == 'mousepressed' then
        local x, y = self:pointer(args[1], args[2])
        local button, scene = args[3], self:activeScene()
        if not modal and scene and scene.inputBeforeUI and scene:inputBeforeUI(method, x, y, button) then
            self.buttons[button] = 'control'
            s.mouse.down = true
            return true
        end
        local consumed = self:ui(method, ...)
        self.buttons[button] = (modal or consumed) and 'ui' or 'scene'
        s.mouse.down = true
        if not modal and not consumed then self:scene(method, x, y, button, args[4], args[5]) end
        return consumed or modal
    elseif method == 'mousereleased' then
        local x, y = self:pointer(args[1], args[2])
        local button, owner = args[3], self.buttons[args[3]]
        self.buttons[button] = nil
        s.mouse.down = next(self.buttons) ~= nil
        local consumed = owner == 'control' or self:ui(method, ...)
        if owner == 'scene' and not modal then self:scene(method, x, y, button, args[4], args[5]) end
        return consumed or modal
    elseif method == 'mousemoved' then
        local x, y = self:pointer(args[1], args[2])
        local consumed = self:ui(method, ...)
        local dragging = false
        for _, owner in pairs(self.buttons) do if owner == 'scene' then dragging = true end end
        if not modal and (dragging or not consumed) then
            self:scene(method, x, y, args[3]/s.window.scale, args[4]/s.window.scale, args[5])
        end
        return consumed or modal
    elseif method == 'wheelmoved' then
        if modal then return true end
        local consumed = self:ui(method, ...)
        if consumed then
            local scene = self:activeScene()
            if scene and scene.uiWheelmoved then scene:uiWheelmoved(...) end
        else self:scene(method, ...) end
        return consumed
    elseif method == 'textinput' then
        if modal then return true end
        if self:ui(method, ...) then return true end
        self:scene(method, ...)
    end
end
return Router
