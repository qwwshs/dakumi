-- 鼠标光标管理
-- 提供 push/pop 模式，用于临时切换光标样式
-- 用法:
--   cursor:set('hand')   -- 切换到手型
--   cursor:pop()          -- 恢复之前的光标

local cursor = {}
setmetatable(cursor, cursor)

local cursor_stack = {}
local cursors = nil

function cursor:set(style)
    if cursors == nil then
        cursors = {}
        cursors.arrow    = love.mouse.getSystemCursor('arrow')
        cursors.hand     = love.mouse.getSystemCursor('hand')
        cursors.ibeam    = love.mouse.getSystemCursor('ibeam')
        cursors.sizewe   = love.mouse.getSystemCursor('sizewe')
        cursors.sizens   = love.mouse.getSystemCursor('sizens')
        cursors.sizenesw = love.mouse.getSystemCursor('sizenesw')
        cursors.sizenwse = love.mouse.getSystemCursor('sizenwse')
        cursors.crosshair = love.mouse.getSystemCursor('crosshair')
    end

    local current = love.mouse.getCursor()
    if current then
        -- 获取当前光标类型名
        for name, c in pairs(cursors) do
            if c == current then
                table.insert(cursor_stack, name)
                break
            end
        end
    else
        table.insert(cursor_stack, 'arrow')
    end

    local new_cursor = cursors[style]
    if new_cursor then
        love.mouse.setCursor(new_cursor)
    end
end

function cursor:pop()
    local prev = table.remove(cursor_stack)
    if prev then
        local c = cursors[prev]
        if c then
            love.mouse.setCursor(c)
        end
    else
        
    end
end

return cursor