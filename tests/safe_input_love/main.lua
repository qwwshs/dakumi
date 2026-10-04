local project = love.filesystem.getWorkingDirectory()
package.path = project .. '/?.lua;' .. package.path
function love.load()
    local ok, err = xpcall(function()
        local safe = require('src.utils.safeInput')
        local function calc(s, expected, vars)
            local n, e = safe.evaluateExpression(s, vars)
            assert(n and math.abs(n - expected) < 1e-9, tostring(e or n))
        end
        calc('-2^2', -4); calc('2^3^2',512); calc('1/4+2*3',6.25)
        calc('math.sin(pi/2)+abs(-3)',4)
        calc('now.lpos + x',12,{now={lpos=10},x=2})
        for _, s in ipairs({'os.execute("evil")','require("io")','(function() while true do end end)()', 'x; os.exit()', 'math.randomseed(1)', '1/0','sqrt(-1)', '2^9999', string.rep('(',100)..'1'..string.rep(')',100)}) do
            assert(safe.evaluateExpression(s,{x=1}) == nil, s)
        end
        local data=assert(safe.parseTable("return {name='test', beat={0,1,4}, ['x']=-3, enabled=true}"))
        assert(data.name=='test' and data.beat[3]==4 and data.x==-3)
        for _, s in ipairs({'{x=os.execute("evil")}', '{(function() return 1 end)()}', '{}; os.exit()', 'setmetatable({},{})', '{x=1/0}'}) do
            assert(safe.parseTable(s)==nil,s)
        end
        for _, path in ipairs({'defaultBezier.txt','i18n/en.lua','i18n/zh-CN.lua'}) do
            local f=assert(io.open(project..'/'..path,'rb')); local s=f:read('*a'); f:close()
            assert(safe.parseTable(s),path)
        end
        log = function() end
        local groups = {}
        group = {new = function(_, name) local g={}; groups[name]=g; return g end}
        package.loaded['src.services.chartService'] = {}
        package.loaded['src.utils.clipboard'] = {}
        package.loaded['config.layouts.sidebar'] = {events={}}
        easings = require('src.utils.easings')
        assert(loadfile(project..'/src/utils/bezier.lua'))()
        assert(loadfile(project..'/src/objects/sidebar/events.lua'))()
        local g = groups.events
        for _, text in ipairs({'function x^2', 'easing 1', 'easing linear', 'bezier 1', 'bezier 0,0,1,1'}) do
            g.trans_expression.value=text; g:transDo()
            assert(g.expression_valid and type(g.expression(.5))=='number',text)
        end
        g.trans_expression.value='function os.execute("evil")'; g:transDo()
        assert(not g.expression_valid)
        assert(loadfile(project..'/src/objects/sidebar/event.lua'))
        assert(loadfile(project..'/src/objects/sidebar/events.lua'))
        assert(loadfile(project..'/src/rooms/menu.lua'))
    end, debug.traceback)
    print(ok and 'SAFE INPUT PASS' or err)
    love.event.quit(ok and 0 or 1)
end
