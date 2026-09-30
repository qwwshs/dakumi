--[[
    模块名: eventBus
    描述: 事件总栈 —— 全局事件发布/订阅中心（pub/sub）。模块间通过具名事件解耦：
          发布方只广播"发生了什么"，订阅方自行响应，双方互不持有引用。
    作者: qwwshs
    依赖: 无（log 为运行时全局，仅用于记录订阅回调的错误）

    事件命名约定: '域:事件'，如 'chart:committed'。
    分发语义: emit 同步、按订阅顺序逐个调用；单个回调出错被 pcall 捕获并写日志，
              不影响其余订阅者；回调中再次订阅/退订是安全的（基于分发前快照）。

    当前事件清单:
      chart:replaced         ()                     整张谱面被替换（选谱/导入）
      chart:committed        (operation, actionKey) 一组已提交的谱面变更，operation 形如
                                                    {add={note={},event={}}, del={note={},event={}},
                                                     groups_before=?, groups_after=?}
      chart:group_edit_begin ()                     进入事件组编辑（订阅方应挂起自身状态）
      chart:group_edit_end   (operation, actionKey) 退出事件组编辑（订阅方恢复状态并处理记录）
]]

local eventBus = {}

--- 事件名 -> 订阅列表（{fn = 订阅函数, order = 订阅序}）
local listeners = {}
local sequence = 0

--- 订阅事件
-- @tparam string name 事件名
-- @tparam function fn 回调，参数为 emit 时传入的事件数据
-- @treturn function|nil 退订函数（调用即取消订阅）
function eventBus:on(name, fn)
    if type(name) ~= 'string' or type(fn) ~= 'function' then return nil end
    local list = listeners[name] or {}
    listeners[name] = list
    sequence = sequence + 1
    list[#list + 1] = {fn = fn, order = sequence}
    return function() eventBus:off(name, fn) end
end

--- 退订
-- off(name, fn) 取消该事件上的指定回调；off(name) 取消该事件的全部回调
-- @treturn boolean 是否有订阅被移除
function eventBus:off(name, fn)
    local list = listeners[name]
    if not list then return false end
    if fn == nil then
        listeners[name] = nil
        return true
    end
    for i, item in ipairs(list) do
        if item.fn == fn then
            table.remove(list, i)
            return true
        end
    end
    return false
end

--- 发布事件（同步、按订阅顺序分发）
-- @treturn boolean 是否存在订阅者
function eventBus:emit(name, ...)
    local list = listeners[name]
    if not list or #list == 0 then return false end
    local snapshot = {}
    for i, item in ipairs(list) do snapshot[i] = item end
    for _, item in ipairs(snapshot) do
        local ok, err = pcall(item.fn, ...)
        if not ok and type(log) == 'function' then
            pcall(log, '[eventBus] ' .. name .. ': ' .. tostring(err))
        end
    end
    return true
end

--- 查询某事件的订阅数量（测试/调试用）
function eventBus:count(name)
    local list = listeners[name]
    return list and #list or 0
end

--- 清空订阅；不传事件名则清空全部（测试/插件卸载用）
function eventBus:clear(name)
    if name then listeners[name] = nil else listeners = {} end
end

return eventBus
