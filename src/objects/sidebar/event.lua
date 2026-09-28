--event界面
local ChartService = require("src.services.chartService")
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
local Incoming_event --传入的事件 
local Incoming_event_before_arrival  --传入的事件 传入前
local Incoming_event_index --传入的事件索引

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
    Incoming_event_index = event_index
    local v = ChartService:getEvent(event_index)
    if not v then log("Sidebar group event not found! event index: "..event_index) log(v) sidebar:to("nil") return end
    Incoming_event = v
    Incoming_event_before_arrival = v:copy()
    self.fromv.value = tostring(v:getFrom())
    self.tov.value = tostring(v:getTo())
    self.transv.value = ''
    if v:getTransType() == 'bezier' then
        self.transType.value = 1
        self.transv.value = table.concat(v:getTransData(), ",")
    elseif v:getTransType() == 'easings' then
        self.transType.value = 2
        self.transv.value = tostring(v:getEasings())
        self.easings_index.value = v:getEasings()
    end
end

function Gevent:transTypeIsBezier()
    Nui:label(i18n:get("trans"))
    ui:edit('field',self.transv)
    local changed = Nui:slider(1,self.bezier_index,#self.bezier,1)
    if changed then
        transIndex.bezier = self.bezier_index.value
    end

    if Nui:button(i18n:get("endow")) then
        self.transv.value = table.concat(self.bezier[self.bezier_index.value],',')
    end

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)

    if ui:imageButton(isImage.add) then
        self.bezier_index.value = math.min(self.bezier_index.value + 1,#self.bezier)
        transIndex.bezier = self.bezier_index.value
    end
    if ui:imageButton(isImage.sub) then
        self.bezier_index.value = math.max(self.bezier_index.value - 1,1)
        transIndex.bezier = self.bezier_index.value
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
    --event的bezier
    love.graphics.setColor(1,1,1,1)
    for i = 1,100 do --曲线绘制
        bezier_y = bezier(1,100,y + h,y,istrans,i) or 0
        bezier_y_end = bezier(1,100,y + h,y,istrans,i + 1) or 0
        Nui:line(w/100 * i +x,bezier_y,w/100 * (i+1) +x,bezier_y_end)
    end
    --当前的bezier
    love.graphics.setColor(1,1,1,0.5)
    for i = 1,100 do --曲线绘制
        bezier_y = bezier(1,100,y + h,y,self.bezier[self.bezier_index.value],i) or 0
        bezier_y_end = bezier(1,100,y + h,y,self.bezier[self.bezier_index.value],i + 1) or 0
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
    transIndex.easings = self.easings_index.value

    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)

    if ui:imageButton(isImage.add) then
        self.easings_index.value = math.min(self.easings_index.value + 1,#easings)
        self.transv.value = tostring(self.easings_index.value)
        transIndex.easings = self.easings_index.value
    end
    if ui:imageButton(isImage.sub) then
        self.easings_index.value = math.max(self.easings_index.value - 1,1)
        self.transv.value = tostring(self.easings_index.value)
        transIndex.easings = self.easings_index.value
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
    ui:edit('field',self.fromv)
    if Nui:button(i18n:get("same_as_below")) then --同下
        self.fromv.value = self.tov.value
    end

    Nui:label(i18n:get("to"))
    ui:edit('field',self.tov)
    if Nui:button(i18n:get("ditto")) then --同上
        self.tov.value = self.fromv.value
    end
    
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)
    Nui:label(i18n:get("trans_type"))
    if Nui:combobox(self.transType,{'bezier','easings'}) then
        if self.transType.value == 1 then
            self.transv.value = table.concat(Incoming_event:getTransData(), ",")
        elseif self.transType.value == 2 then
            self.transv.value = tostring(Incoming_event:getEasings())
            self.easings_index.value = Incoming_event:getEasings()
        end
    end


    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.trans.cols)
    if self.transType.value == 1 then
        self:transTypeIsBezier()
    elseif self.transType.value == 2 then
        self:transTypeIsEasings()
    end
end

function Gevent:NuiNext() --更新信息
    local v = ChartService:getEvent(sidebar.incoming[1])
    if not v then return end

    if iskeyboard['return'] then --对from以及to进行计算
        pcall(function ()
            self.fromv.value = loadstring(
            [[
            local now = {x = 0,w = 0}
            now.x,now.w = fEvent:get(track.track,beat.nowbeat,true)
            now.lpos,now.rpos = now.x - now.w / 2,now.x + now.w / 2
            local r = math.random
            return
            ]]..self.fromv.value)()
            if type(self.fromv.value) ~= "number" then
                self.fromv.value = 0
            end
        end)
        pcall(function ()
            self.tov.value = loadstring("return "..self.tov.value)()
            if type(self.tov.value) ~= "number" then
                self.tov.value = 0
            end
        end)
    end

    v:setFrom(tonumber(self.fromv.value) or 0)
    v:setTo(tonumber(self.tov.value) or 0)
    if self.transType.value == 1 then
        v:setTransType('bezier')
    elseif self.transType.value == 2 then
        v:setTransType('easings')
    end

    if v:getTransType() == 'bezier' then
        local td = v:getTransData()
        for i = 1, #td do
            td[i] = nil
        end
        for i in string.gmatch(self.transv.value, "[^,]+") do
            local value = tonumber(i) or 0
            table.insert(td, value)
        end
    elseif v:getTransType() == 'easings' then
        value = tonumber(self.transv.value) or 1
        v:setEasings(value)
    end
end

function Gevent:leave()
--用于撤销
local actionKey = self.historyAction or 'history.edit_event'
self.historyAction = nil
-- directEventEditing 拖拽期间每帧 sidebar:to 会刷新本页面：
-- 拖拽中不记录撤销（避免每帧产生一条记录），由插件在拖动完成时统一写入一次
if directEventEditing and directEventEditing.catch_point then return end
if Incoming_event_before_arrival == Incoming_event then return end
Incoming_event = Incoming_event:copy()
log(ChartService:deleteEvent(Incoming_event))
ChartService:addEvent(Incoming_event_before_arrival)
ChartService:push()
ChartService:delete(Incoming_event_before_arrival)
ChartService:add(Incoming_event)
ChartService:pop(actionKey)
end
return Gevent
