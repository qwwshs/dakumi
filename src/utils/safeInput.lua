-- 用户输入只解析为数据或算式，不交给 Lua 编译器。
local M = {}
local function finite(n)
    return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end
local function lexer(source, limit, tokenLimit)
    assert(type(source) == "string" and #source <= limit, "输入过长或类型错误")
    source = source:gsub("^\239\187\191", "")
    local pos, count = 1, 0
    local function nextToken()
        count = count + 1
        assert(count <= (tokenLimit or 1000000), "输入项过多")
        while true do
            local _, e = source:find("^%s+", pos)
            if e then pos = e + 1 end
            if source:sub(pos, pos + 1) ~= "--" then break end
            pos = pos + 2
            local eq = source:sub(pos):match("^%[(=*)%[")
            if eq then
                local close = "]" .. eq .. "]"
                local finish = source:find(close, pos + #eq + 2, true)
                assert(finish, "注释未结束")
                pos = finish + #close
            else
                pos = (source:find("\n", pos, true) or #source) + 1
            end
        end
        if pos > #source then return "eof" end
        local c = source:sub(pos,pos)
        if c == '"' or c == "'" then
            local quote, parts = c, {}
            pos = pos + 1
            while pos <= #source do
                c = source:sub(pos,pos); pos = pos + 1
                if c == quote then return "string", table.concat(parts) end
                assert(c ~= "\n" and c ~= "\r", "字符串未结束")
                if c == "\\" then
                    local escape = source:sub(pos,pos); pos = pos + 1
                    local escapes = {a="\a",b="\b",f="\f",n="\n",r="\r",t="\t",v="\v"}
                    if escape:match("%d") then
                        local digits = escape .. (source:sub(pos):match("^%d?%d?") or "")
                        pos = pos + #digits - 1
                        assert(tonumber(digits) <= 255, "字符串转义错误")
                        c = string.char(tonumber(digits))
                    else
                        assert(escapes[escape] or escape == "\\" or escape == quote, "不支持的字符串转义")
                        c = escapes[escape] or escape
                    end
                end
                parts[#parts+1] = c
            end
            error("字符串未结束")
        end
        local rest = source:sub(pos)
        local num = rest:match("^%d+%.?%d*[eE][+-]?%d+") or rest:match("^%.%d+[eE][+-]?%d+")
            or rest:match("^%d+%.?%d*") or rest:match("^%.%d+")
        if num then pos = pos + #num; local n=tonumber(num); assert(finite(n), "数值无效"); return "number", n end
        local name = rest:match("^[%a_][%w_]*")
        if name then pos=pos+#name; return "name",name end
        pos=pos+1; return c,c
    end
    return nextToken
end
function M.parseTable(source)
    local ok, result = pcall(function()
        local nextToken = lexer(source, 16 * 1024 * 1024)
        local token, value = nextToken()
        local function advance() token,value=nextToken() end
        local function expect(t) assert(token==t,"数据格式错误："..t); advance() end
        local read
        read = function(depth)
            assert(depth <= 64, "嵌套过深")
            if token == "{" then
                advance(); local out, index = {},1
                while token ~= "}" do
                    local key, item
                    if token == "[" then
                        advance(); key=read(depth+1); expect("]"); expect("=")
                        assert(type(key)=="string" or finite(key), "键名无效")
                        item=read(depth+1)
                    elseif token == "name" and value ~= "true" and value ~= "false" and value ~= "nil" then
                        key=value; advance(); expect("="); item=read(depth+1)
                    else
                        key=index; index=index+1; item=read(depth+1)
                    end
                    out[key]=item
                    if token ~= "}" then assert(token=="," or token==";", "数据缺少分隔符") end
                    if token=="," or token==";" then advance() end
                end
                advance(); return out
            elseif token == "number" or token == "string" then
                local item=value; advance(); return item
            elseif token == "-" or token == "+" then
                local sign=token=="-" and -1 or 1; advance()
                assert(token=="number", "符号后需要数字")
                local item=sign*value; advance(); return item
            elseif token == "name" then
                local name=value; advance()
                if name=="true" then return true elseif name=="false" then return false elseif name=="nil" then return nil end
            end
            error("只允许表、数字、字符串和布尔值")
        end
        if token=="name" and value=="return" then advance() end
        local data=read(0)
        if token==";" then advance() end
        assert(token=="eof" and type(data)=="table", "需要完整的数据表")
        return data
    end)
    if ok then return result end
    return nil, result
end
-- 预设只允许四个有限数字，非法条目不进入绘制和计算。
function M.parseBezierPresets(source)
    local data = M.parseTable(source)
    local presets = {}
    if not data then return presets end
    for key, points in pairs(data) do
        if finite(key) and key >= 1 and key % 1 == 0 and type(points) == "table" then
            if #points == 4 and finite(points[1]) and finite(points[2]) and finite(points[3]) and finite(points[4]) then
                presets[key] = {points[1], points[2], points[3], points[4]}
            end
        end
    end
    return presets
end
local functions = {}
for _, name in ipairs({"abs","acos","asin","atan","atan2","ceil","cos","exp","floor","log","log10","max","min","pow","sin","sqrt","tan","random"}) do
    if math[name] then functions[name]=math[name]; functions["math."..name]=math[name] end
end
functions.r = math.random
local precedence = {["+"]=1,["-"]=1,["*"]=2,["/"]=2,["%"]=2,["^"]=4}
function M.compileExpression(source)
    local ok, result=pcall(function()
        local nextToken=lexer(source,4096,512)
        local token,value=nextToken()
        local function advance() token,value=nextToken() end
        local expression
        expression=function(minimum,depth)
            assert(depth<=64,"算式嵌套过深")
            local node
            if token=="+" or token=="-" then
                local op=token; advance(); node={"unary",op,expression(3,depth+1)}
            elseif token=="number" then node={"number",value}; advance()
            elseif token=="(" then
                advance(); node=expression(1,depth+1); assert(token==")","缺少右括号"); advance()
            elseif token=="name" then
                local name=value; advance()
                if token=="." then advance(); assert(token=="name","名称错误"); name=name.."."..value; advance() end
                if token=="(" then
                    assert(functions[name],"不允许调用："..name); advance()
                    local args={}
                    if token~=")" then
                        repeat
                            args[#args+1]=expression(1,depth+1)
                            assert(#args<=16,"参数过多")
                            if token~="," then break end
                            advance()
                        until false
                    end
                    assert(token==")","缺少右括号"); advance(); node={"call",name,args}
                else
                    assert(name=="x" or name=="now.x" or name=="now.w" or name=="now.lpos" or name=="now.rpos" or name=="pi" or name=="math.pi", "不允许读取："..name)
                    node={"variable",name}
                end
            else error("算式格式错误") end
            while precedence[token] and precedence[token]>=minimum do
                local op,p=token,precedence[token]; advance()
                node={"binary",op,node,expression(op=="^" and p or p+1,depth+1)}
            end
            return node
        end
        local root=expression(1,0); assert(token=="eof","算式包含多余内容")
        local function evaluate(node,vars)
            local kind,n=node[1]
            if kind=="number" then n=node[2]
            elseif kind=="variable" then
                local name=node[2]
                if name=="pi" or name=="math.pi" then n=math.pi
                elseif name:sub(1,4)=="now." then n=(vars.now or {})[name:sub(5)] else n=vars[name] end
            elseif kind=="unary" then n=evaluate(node[3],vars); if node[2]=="-" then n=-n end
            elseif kind=="call" then
                local args={}; for i,v in ipairs(node[3]) do args[i]=evaluate(v,vars) end
                n=functions[node[2]](unpack(args))
            else
                local a,b=evaluate(node[3],vars),evaluate(node[4],vars)
                local op=node[2]
                if op=="+" then n=a+b elseif op=="-" then n=a-b elseif op=="*" then n=a*b
                elseif op=="/" then n=a/b elseif op=="%" then n=a%b else n=a^b end
            end
            assert(finite(n),"算式结果必须是有限数字"); return n
        end
        return function(vars) return evaluate(root,vars or {}) end
    end)
    if ok then return result end
    return nil,result
end
function M.evaluateExpression(source,vars)
    local fn,err=M.compileExpression(tostring(source))
    if not fn then return nil,err end
    local ok,result=pcall(fn,vars)
    if ok then return result end
    return nil,result
end
return M
