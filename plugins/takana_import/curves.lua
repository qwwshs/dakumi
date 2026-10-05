-- Takana 节点解码；按官方 Opposite 约定交换 i/o、a/b，保留贝塞尔控制点。
local easings = require('src.utils.easings')
local Curves = {}
local families = {s='sine', ['2']='quad', ['3']='cubic', ['4']='quart', ['5']='quint',
    e='expo', c='circ', b='back', l='elastic', w='bounce'}
local expressions = {
    sine='1-math.cos(t*math.pi/2)', quad='t*t', cubic='t*t*t', quart='t^4', quint='t^5',
    expo='t==0 and 0 or 2^(10*t-10)', circ='1-math.sqrt(1-t*t)',
    back='2.70158*t^3-1.70158*t*t',
    elastic='t==0 and 0 or t==1 and 1 or -2^(10*t-10)*math.sin((10*t-10.75)*2*math.pi/3)',
}
local bounce = [[local function out(t)
    if t<1/2.75 then return 7.5625*t*t
    elseif t<2/2.75 then t=t-1.5/2.75; return 7.5625*t*t+0.75
    elseif t<2.5/2.75 then t=t-2.25/2.75; return 7.5625*t*t+0.9375
    else t=t-2.625/2.75; return 7.5625*t*t+0.984375 end
end
return 1-out(1-t)]]
local rpe = {'s','so','si','2o','2i','sa','2a','3o','3i','4o','4i','3a','4a',
    '5o','5i','eo','ei','co','ci','bo','bi','ca','ba','lo','li','wo','wi','wa',
    'la','5a','ea','sb','2b','3b','4b','5b','eb','cb','bb','lb','wb'}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function number(n) return string.format('%.17g',n) end
local function compile(source)
    -- 只编译固定数学模板及已验证数字；不执行谱面提供的脚本。
    local factory = assert(loadstring('return function(t)\n'..source..'\nend'))
    setfenv(factory,{math=math})
    return factory()
end
local function definition(chart,name,source)
    local existing=chart.custom_trans[name]
    if existing and existing~=source then
        local index=1
        while chart.custom_trans[name..'_'..index] and chart.custom_trans[name..'_'..index]~=source do index=index+1 end
        name=name..'_'..index
    end
    chart.custom_trans[name]=source
    return {type='custom',custom=name}
end
local function normalize(code)
    code=code:match('^%s*(.-)%s*$'):lower()
    local id=tonumber(code)
    if id then
        assert(id%1==0 and id>=0, 'Takana：无效缓动编号')
        if id==100 then return 'u' end
        if id>=101 then code=rpe[id-100]
        elseif id%10==0 then code='u'
        elseif id%10==1 then code='s'
        else
            local family=({[0]='w','s','2','3','4','5','e','c','b','l'})[math.floor(id/10)]
            local mode=({[2]='i',[3]='o',[4]='a',[5]='b'})[id%10]
            code=family and mode and family..mode
        end
    end
    assert(code, 'Takana：未知缓动编号')
    return code
end
local function easing(code,chart)
    code=normalize(code)
    if code=='u' then return {type='easings',easings=1},'return 0',true end
    if code=='s' then return {type='easings',easings=1},'return t' end
    local family=families[code:sub(1,1)]
    local mode=({i='o',o='i',a='b',b='a'})[code:sub(2)]
    assert(family and mode and #code==2, 'Takana：未知缓动 '..code)
    local source='local function ease_in(t)\n'..(family=='bounce' and bounce or
        'return '..expressions[family])..'\nend\n'
    if mode=='i' then source=source..'return ease_in(t)'
    elseif mode=='o' then source=source..'return 1-ease_in(1-t)'
    elseif mode=='a' then
        source=source..'if t<0.5 then return ease_in(2*t)/2 else return 1-ease_in(2-2*t)/2 end'
    else
        source=source..'if t<0.5 then return (1-ease_in(1-2*t))/2 else return (1+ease_in(2*t-1))/2 end'
    end
    local fn=easings[(mode=='i' and 'in_' or mode=='o' and 'out_' or mode=='a' and 'in_out_' or '')..family]
    -- Takana 的 Back 组合曲线由两段基本曲线组成，和内置 BackInOut 的参数不同。
    if fn and not (family=='back' and mode=='a') then
        for index,item in ipairs(easings) do
            if item==fn then return {type='easings',easings=index},source end
        end
    end
    return definition(chart,'takana_'..code,source),source
end
function Curves.parse(raw,chart,cache)
    assert(type(raw)=='string', 'Takana：节点必须是字符串')
    local kind,body=raw:match('^%s*(v1[eb])_%((.-)%)%s*$')
    assert(kind, 'Takana：不支持的节点 '..raw)
    local fields={}
    for field in body:gmatch('[^,]+') do fields[#fields+1]=field end
    local value=tonumber(fields[1])
    assert(finite(value), 'Takana：无效节点位置')
    local trans,source,still
    if kind=='v1e' then
        assert(#fields==2, 'Takana：缓动节点需要两个参数')
        trans,source,still=easing(fields[2],chart)
    else
        assert(#fields==5, 'Takana：贝塞尔节点需要五个参数')
        local points={}
        for i=2,5 do
            points[i-1]=tonumber(fields[i])
            assert(finite(points[i-1]), 'Takana：无效贝塞尔控制点')
        end
        local x1,y1,x2,y2=unpack(points)
        assert(x1>=0 and x1<=1 and x2>=0 and x2<=1, 'Takana：贝塞尔时间控制点必须在 0 到 1 之间')
        source='local x1,y1,x2,y2='..table.concat({number(x1),number(y1),number(x2),number(y2)},',')..'\n'..[[
if t==0 or t==1 then return t end
local lo,hi=0,1
for i=1,32 do
    local u=(lo+hi)/2
    local v=1-u
    local x=3*v*v*u*x1+3*v*u*u*x2+u*u*u
    if x<t then lo=u else hi=u end
end
local u=(lo+hi)/2
local v=1-u
return 3*v*v*u*y1+3*v*u*u*y2+u*u*u]]
        trans={type='bezier',trans=points}
        if y1<0 or y1>1 or y2<0 or y2>1 then
            trans=definition(chart,'takana_bezier',source)
        end
    end
    local fn=cache and cache[source]
    if not fn then
        fn=compile(source)
        if cache then cache[source]=fn end
    end
    return {value=value,trans=trans,source=source,evaluate=fn,still=still}
end
function Curves.slice(node,first,last,chart)
    if node.still then return node.trans end
    if first==0 and last==1 then return node.trans end
    local source='local function curve(t)\n'..node.source..'\nend\n'..
        'local a,b='..number(first)..','..number(last)..'\n'..
        'local start,finish=curve(a),curve(b)\n'..
        'if math.abs(finish-start)<0.000000000001 then return t end\n'..
        'return (curve(a+(b-a)*t)-start)/(finish-start)'
    return definition(chart,'takana_clip',source)
end
return Curves
