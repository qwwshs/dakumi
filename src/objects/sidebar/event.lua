--event界面
local Gevent = group:new('event')
Gevent.type = "event"
Gevent.layout = require 'config.layouts.sidebar'.event
Gevent.transv = {value = '1,1,1,1'}
Gevent.fromv = {value = '0'}
Gevent.tov = {value = '0'}
Gevent.bezier_index = {value = 1}
Gevent.bezier = {}
local meta_default_bezier = {
    __index ={
        {1,1,1,1}
    
    }
}

local bezier_file = io.open("defaultBezier.txt", "r")  -- 以只读模式打开文件
if bezier_file then
    local content = bezier_file:read("*a")  -- 读取整个文件内容
    bezier_file:close()  -- 关闭文件
    Gevent.bezier = loadstring("return "..content)()
end
if type(Gevent.bezier) ~= "table" then
    Gevent.bezier = {}
end

setmetatable(Gevent.bezier,meta_default_bezier)

function Gevent:to(event_index)
    local v = chart.event[event_index]
    self.fromv.value = tostring(v.from)
    self.tov.value = tostring(v.to)
    self.transv.value = table.concat(v.trans,',')
end

function Gevent:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get("from"))
    Nui:edit('field',self.fromv)
    if Nui:button(i18n:get("same_as_below")) then --同下
    
    end

    Nui:label(i18n:get("to"))
    Nui:edit('field',self.tov)
    if Nui:button(i18n:get("ditto")) then --同上
    
    end
    
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)
    Nui:label(i18n:get("trans"))
    Nui:edit('field',self.transv)

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)

    local changed = Nui:slider(1,self.bezier_index,#self.bezier,1)
    if changed then
        self.transv.value = table.concat(self.bezier[self.bezier_index.value],',')
    end

    if Nui:button(i18n:get("endow")) then
        self.transv.value = table.concat(self.bezier[self.bezier_index.value],',')
    end

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)

    if Nui:button("",isImage.add) then
        self.bezier_index.value = math.min(self.bezier_index.value + 1,#self.bezier)
        self.transv.value = table.concat(self.bezier[self.bezier_index.value],',')
        bezier_index = self.bezier_index.value
    end
    if Nui:button("",isImage.sub) then
        self.bezier_index.value = math.max(self.bezier_index.value - 1,1)
        self.transv.value = table.concat(self.bezier[self.bezier_index.value],',')
        bezier_index = self.bezier_index.value
    end

    local x = self.layout.bezier.x
    local y = self.layout.bezier.y
    local w = self.layout.bezier.w
    local h = self.layout.bezier.h
    local istrans = {}
    local bezier_y
    local bezier_y_end
    for i in string.gmatch(self.transv.value, "[^,]+") do
        local value = tonumber(i) or 0
        table.insert(istrans,value)
    end
    
    for i = 1,100 do --曲线绘制
        bezier_y = bezier(1,100,y + h,y,istrans,i)
        bezier_y_end = bezier(1,100,y + h,y,istrans,i + 1)
        Nui:line(w/100 * i +x,bezier_y,w/100 * (i+1) +x,bezier_y_end)
    end
    --底线
    Nui:polygon('fill',x,y + h,x + w,y + h,x + w,y + h+3,x,y + h+3)
    --侧线
    Nui:polygon('fill',x + w,y,x + w,y + h,x + w+3,y + h,x + w+3,y)
end

function Gevent:NuiNext() --更新信息
    local v = chart.event[sidebar.incoming[1]]
    v.from = tonumber(self.fromv.value) or 0
    v.to = tonumber(self.tov.value) or 0
    v.trans = {}
    for i in string.gmatch(self.transv.value, "[^,]+") do
        local value = tonumber(i) or 0
        table.insert(v.trans,value)
    end

end

return Gevent