-- 自定义过渡的隔离执行器：仅接收 t，提供只读数学函数，限制指令和新增内存。
local Custom={}
local resolve
local cache={}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local allowed={}
for _, key in ipairs({'abs','acos','asin','atan','atan2','ceil','cos','cosh','deg','exp','floor',
    'fmod','frexp','ldexp','log','log10','max','min','modf','pow','rad','sin','sinh','sqrt','tan','tanh','pi','huge'}) do
    allowed[key]=math[key]
end
local readOnlyMath=setmetatable({}, {__index=allowed,__newindex=function() error('math is read-only') end})
local run
local function compile(source)
    if type(source)~='string' or #source>16384 then return nil,'script must be a string of at most 16384 bytes' end
    local factory,err=loadstring('return function(t)\n'..source..'\nend','@custom_trans')
    if not factory then return nil,err end
    local values={math=readOnlyMath,tonumber=tonumber,type=type,pairs=pairs,ipairs=ipairs,
        assert=assert,error=error,select=select}
    local env=setmetatable({}, {__index=values,__newindex=function() error('global writes are disabled') end})
    setfenv(factory,env)
    if jit then jit.off(factory,true) end
    local fn,err=run(factory,nil,true)
    if not fn then return nil,err end
    -- LuaJIT 的已编译循环可能绕过计数钩子；只关闭用户函数的 JIT。
    if jit then jit.off(fn,true) end
    return fn
end
run=function(fn,t, factory)
    local oldHook,oldMask,oldCount=debug.gethook()
    local stringMeta=debug.getmetatable('')
    -- 字符串方法可能在 C 内大量分配或长时间匹配；脚本只允许 Lua 运算。
    debug.setmetatable('',{__index={}})
    local instructions=0
    local memory=collectgarbage('count')
    debug.sethook(function()
        instructions=instructions+10
        if instructions>20000 then error('script instruction limit exceeded') end
        if collectgarbage('count')-memory>4096 then error('script memory limit exceeded') end
    end,'',10)
    local ok,result=pcall(fn,t)
    debug.sethook(oldHook,oldMask,oldCount)
    debug.setmetatable('',stringMeta)
    if not ok then return nil,tostring(result) end
    if factory then
        if type(result)=='function' then return result end
        return nil,'invalid script body'
    end
    if not finite(result) then return nil,'script must return a finite number' end
    return result
end
function Custom.init(resolver) resolve=resolver; cache={} end
function Custom.validate(source)
    local fn,err=compile(source)
    if not fn then return false,err end
    for _,t in ipairs({0,0.25,0.5,0.75,1}) do
        local result,message=run(fn,t)
        if not result then return false,message end
    end
    return true
end
function Custom.evaluate(name,t)
    t=finite(t) and math.max(0,math.min(1,t)) or 0
    local source=resolve and resolve(name)
    if not source then return t,'custom transition not found' end
    local entry=cache[name]
    if not entry or entry.source~=source then
        local fn,err=compile(source)
        entry={source=source,fn=fn,error=err}; cache[name]=entry
    end
    if entry.error then return t,entry.error end
    local result,err=run(entry.fn,t)
    if err then entry.error=err; return t,err end
    return result
end
function Custom.getError(name)
    return cache[name] and cache[name].error or nil
end
return Custom
