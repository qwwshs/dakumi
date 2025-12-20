--event界面
local Gevent = group:new('event')
Gevent.type = "event"
Gevent.layout = require 'config.layouts.sidebar'.event
Gevent.transv = {value = '1,1,1,1'}
Gevent.transType = {value = 1}
Gevent.fromv = {value = '0'}
Gevent.tov = {value = '0'}
Gevent.bezier_index = {value = 1}
Gevent.bezier = {}
Gevent.easings_index = {value = 1}
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
    self.transv.value = ''
    if v.trans.type == 'bezier' then
        self.transType.value = 1
        self.transv.value = table.concat(v.trans.trans, ",")
    elseif v.trans.type == 'easings' then
        self.transType.value = 2
        self.transv.value = tostring(v.trans.easings)
        self.easings_index.value = v.trans.easings
    end
end

function Gevent:transTypeIsBezier()
    Nui:label(i18n:get("trans"))
    Nui:edit('field',self.transv)
    local changed = Nui:slider(1,self.bezier_index,#self.bezier,1)
    if changed then
        self.transv.value = table.concat(self.bezier[self.bezier_index.value],',')
        bezier_index = self.bezier_index.value
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

    local x = self.layout.transFunc.x or 0
    local y = self.layout.transFunc.y or 0
    local w = self.layout.transFunc.w or 0
    local h = self.layout.transFunc.h or 0
    local istrans = {}
    local bezier_y
    local bezier_y_end
    for i in string.gmatch(self.transv.value, "[^,]+") do
        local value = tonumber(i) or 0
        table.insert(istrans,value)
    end
    love.graphics.setColor(1,1,1)
    for i = 1,100 do --曲线绘制
        bezier_y = bezier(1,100,y + h,y,istrans,i) or 0
        bezier_y_end = bezier(1,100,y + h,y,istrans,i + 1) or 0
        Nui:line(w/100 * i +x,bezier_y,w/100 * (i+1) +x,bezier_y_end)
    end
    --底线
    Nui:polygon('fill',x,y + h,x + w,y + h,x + w,y + h+3,x,y + h+3)
    --侧线
    Nui:polygon('fill',x + w,y,x + w,y + h,x + w+3,y + h,x + w+3,y)
end

function Gevent:transTypeIsEasings()
    Nui:slider(1,self.easings_index,#easings,1)
    self.transv.value = tostring(self.easings_index.value)
    easings_index = self.easings_index.value

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)

    if Nui:button("",isImage.add) then
        self.easings_index.value = math.min(self.bezier_index.value + 1,#easings)
        self.transv.value = tostring(self.easings_index.value)
        easings_index = self.easings_index.value
    end
    if Nui:button("",isImage.sub) then
        self.bezier_index.value = math.max(self.bezier_index.value - 1,1)
        self.transv.value = tostring(self.easings_index.value)
        easings_index = self.easings_index.value
    end

    local x = self.layout.transFunc.x or 0
    local y = self.layout.transFunc.y or 0
    local w = self.layout.transFunc.w or 0
    local h = self.layout.transFunc.h or 0
    local istrans = self.easings_index
    local easings_y
    local easings_y_end
    love.graphics.setColor(1,1,1)
    for i = 1,100 do --曲线绘制
        easings_y = (y+h - h*easings[self.easings_index.value](i/100)) or 0
        easings_y_end = (y+h - h*easings[self.easings_index.value]((i + 1)/100)) or 0
        Nui:line(w/100 * i +x,easings_y,w/100 * (i+1) +x,easings_y_end)
    end
    --底线
    Nui:polygon('fill',x,y + h,x + w,y + h,x + w,y + h+3,x,y + h+3)
    --侧线
    Nui:polygon('fill',x + w,y,x + w,y + h,x + w+3,y + h,x + w+3,y)

end

function Gevent:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    Nui:label(i18n:get("from"))
    Nui:edit('field',self.fromv)
    if Nui:button(i18n:get("same_as_below")) then --同下
        self.fromv.value = self.tov.value
    end

    Nui:label(i18n:get("to"))
    Nui:edit('field',self.tov)
    if Nui:button(i18n:get("ditto")) then --同上
        self.tov.value = self.fromv.value
    end
    
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)
    Nui:label(i18n:get("trans_type"))
    Nui:combobox(self.transType,{'bezier','easings'})


    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)
    if self.transType.value == 1 then
        self:transTypeIsBezier()
    elseif self.transType.value == 2 then
        self:transTypeIsEasings()
    end
end

function Gevent:NuiNext() --更新信息
    local v = chart.event[sidebar.incoming[1]]
    if not v then return end
    v.from = tonumber(self.fromv.value) or 0
    v.to = tonumber(self.tov.value) or 0
    if self.transType.value == 1 then
        v.trans.type = 'bezier'
    elseif self.transType.value == 2 then
        v.trans.type = 'easings'
    end

    if v.trans.type == 'bezier' then
        for i = 1,#v.trans.trans do
            v.trans.trans[i] = nil
        end
        for i in string.gmatch(self.transv.value, "[^,]+") do
            local value = tonumber(i) or 0
            table.insert(v.trans.trans,value)
        end
    elseif v.trans.type == 'easings' then
        value = tonumber(self.transv.value) or 1
        v.trans.easings = value
    end
end

return Gevent