local TimeOffsetField = require('src.objects.timeOffsetField')
local AudioService = require('src.services.audioService')
local safeInput = require("src.utils.safeInput")
--event界面
local ChartService = require("src.services.chartService")
local editState = require("src.utils.editState") -- 插件拖拽状态（核心持有）
local Gevent = group:new('event')
Gevent.type = "event"
Gevent.layout = require 'config.layouts.sidebar'.event
Gevent.timeOffsetV = TimeOffsetField.new()
Gevent.transv = {value = '1,1,1,1'}
Gevent.transType = {value = 1}
Gevent.fromv = {value = '0'}
Gevent.tov = {value = '0'}
Gevent.bezier_index = {value = 1}
Gevent.bezier = {}
Gevent.easings_index = {value = 1}
Gevent.groupNameV = {value = ''}
Gevent.groupChoice = {value = 1}
Gevent.flipH = {value = false}
Gevent.flipV = {value = false}
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
    Gevent.bezier = safeInput.parseBezierPresets(content)
end
if type(Gevent.bezier) ~= "table" then
    Gevent.bezier = {}
end

setmetatable(Gevent.bezier,meta_default_bezier)

function Gevent:to(event_index)
    Incoming_event_index = event_index
    local v = ChartService:getEvent(event_index)
    if not v then log("Sidebar group event not found! event index: "..event_index) log(v) sidebar:to("nil") return end
    self.timeOffsetV:load(v)
    Incoming_event = v
    Incoming_event_before_arrival = v:copy()
    self.fromv.value = tostring(v:getFrom())
    self.tov.value = tostring(v:getTo())
    self.groupNameV.value = v:getEventGroup() or ''
    self.groupChoice.value = 1
    for index, name in ipairs(ChartService:getEventGroupNames()) do
        if name == self.groupNameV.value then self.groupChoice.value = index + 1; break end
    end
    self.flipH.value = v:getFlipHorizontally() == 1
    self.flipV.value = v:getFlipVertically() == 1
    self.transv.value = ''
    if v:getTransType() == 'bezier' then
        self.transType.value = 1
        self.transv.value = table.concat(v:getTransData(), ",")
    elseif v:getTransType() == 'easings' then
        self.transType.value = 2
        self.transv.value = tostring(v:getEasings())
        self.easings_index.value = v:getEasings()
    end
    -- 打开页面事务：页面期间的实体修改（含拖拽）全部累积，leave 时合并为一条记录
    ChartService:beginChange()
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
    -- 日间背景上用黑色曲线，深色模式保持白色。
    local curveColor = settings.theme == 'light' and 0 or 1
    local oldR, oldG, oldB, oldA = love.graphics.getColor()
    love.graphics.setColor(curveColor,curveColor,curveColor,1)
    for i = 1,100 do --曲线绘制
        bezier_y = bezier(1,100,y + h,y,istrans,i) or 0
        bezier_y_end = bezier(1,100,y + h,y,istrans,i + 1) or 0
        Nui:line(w/100 * i +x,bezier_y,w/100 * (i+1) +x,bezier_y_end)
    end
    --当前的bezier
    love.graphics.setColor(curveColor,curveColor,curveColor,0.5)
    for i = 1,100 do --曲线绘制
        bezier_y = bezier(1,100,y + h,y,self.bezier[self.bezier_index.value],i) or 0
        bezier_y_end = bezier(1,100,y + h,y,self.bezier[self.bezier_index.value],i + 1) or 0
        Nui:line(w/100 * i +x,bezier_y,w/100 * (i+1) +x,bezier_y_end)
    end
    --底线
    Nui:polygon('fill',x,y + h,x + w,y + h,x + w,y + h+3,x,y + h+3)
    --侧线
    Nui:polygon('fill',x + w,y,x + w,y + h,x + w+3,y + h,x + w+3,y)
    love.graphics.setColor(oldR,oldG,oldB,oldA)
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
    local curveColor = settings.theme == 'light' and 0 or 1
    local oldR, oldG, oldB, oldA = love.graphics.getColor()
    love.graphics.setColor(curveColor,curveColor,curveColor,1)
    for i = 1,100 do --曲线绘制
        easings_y = (y+h - h*easings[self.easings_index.value](i/100)) or 0
        easings_y_end = (y+h - h*easings[self.easings_index.value]((i + 1)/100)) or 0
        Nui:line(w/100 * i +x,easings_y,w/100 * (i+1) +x,easings_y_end)
    end
    --底线
    Nui:polygon('fill',x,y + h,x + w,y + h,x + w,y + h+3,x,y + h+3)
    --侧线
    Nui:polygon('fill',x + w,y,x + w,y + h,x + w+3,y + h,x + w+3,y)
    love.graphics.setColor(oldR,oldG,oldB,oldA)

end

function Gevent:Nui()
    self.timeOffsetV:draw(self.layout.uiH)
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

    if Incoming_event and Incoming_event:getType() == 'event_group' then
        local names = ChartService:getEventGroupNames()
        local choices = {i18n:get('event_group.none')}
        for _, name in ipairs(names) do choices[#choices + 1] = name end
        Nui:layoutRow('dynamic', self.layout.uiH, 2)
        Nui:label(i18n:get('event_group.reference'))
        if Nui:combobox(self.groupChoice, choices) then
            self.groupNameV.value = names[self.groupChoice.value - 1] or ''
        end
        Nui:label(i18n:get('event_group.name'))
        ui:edit('field', self.groupNameV)
        Nui:checkbox(i18n:get('event_group.flip_h'), self.flipH)
        Nui:checkbox(i18n:get('event_group.flip_v'), self.flipV)
        return
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

function Gevent:applyFields() --更新信息
    local v = ChartService:getEvent(sidebar.incoming[1])
    if not v then return end
    self.timeOffsetV:apply(v, ChartService)

    if v:getType() == 'event_group' then
        local from, to = tonumber(self.fromv.value), tonumber(self.tov.value)
        if from and from == from and math.abs(from) < math.huge then v:setFrom(from) end
        if to and to == to and math.abs(to) < math.huge then v:setTo(to) end
        local name = self.groupNameV.value
        if type(name) == 'string' and #name <= 128 and not name:find('[%c/\\]') then
            v:setEventGroup(name)
        end
        v:setFlipHorizontally(self.flipH.value and 1 or 0)
        v:setFlipVertically(self.flipV.value and 1 or 0)
        return
    end

    if require('src.utils.input'):getUIKeyboard()['return'] then --对from以及to进行计算
        local x, w = fEvent:get(track.track, AudioService:getCurrentBeat(), true)
        local vars = {now = {x = x, w = w, lpos = x - w / 2, rpos = x + w / 2}}
        local from = safeInput.evaluateExpression(self.fromv.value, vars)
        local to = safeInput.evaluateExpression(self.tov.value, vars)
        if from then self.fromv.value = tostring(from) end
        if to then self.tov.value = tostring(to) end

    end

    local from, to = tonumber(self.fromv.value), tonumber(self.tov.value)
    if from and from == from and math.abs(from) ~= math.huge then v:setFrom(from) end
    if to and to == to and math.abs(to) ~= math.huge then v:setTo(to) end
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

function Gevent:NuiNext()
    if ChartService:isEditingEffect() then
        ChartService:changeEffectFields(function() self:applyFields() end)
    else self:applyFields() end
end

function Gevent:leave()
    local actionKey = self.historyAction or (ChartService:isEditingEffect() and 'history.edit_effect' or 'history.edit_event')
    self.historyAction = nil
    -- directEventEditing 拖拽期间每帧 sidebar:to 会刷新本页面：
    -- 刷新时不提交（页面事务继续，离开页面时统一合并为一条记录）
    if editState.draggingEvent then return end
    -- 非法落点：页面编辑实时生效，非法时回退到进入页面前的值（回退本身不产生记录）
    if Incoming_event and Incoming_event_before_arrival and
        not ChartService:canPlaceEvent(Incoming_event, Incoming_event) then
        ChartService:suspend(function()
            Incoming_event:setBeat(Incoming_event_before_arrival:getBeat())
            Incoming_event:setBeat2(Incoming_event_before_arrival:getBeat2())
            local offset = Incoming_event_before_arrival:getTimeOffset()
            Incoming_event:setTimeOffset(offset > 0 and offset or nil)
            Incoming_event:setTrack(Incoming_event_before_arrival:getTrack())
            Incoming_event:setType(Incoming_event_before_arrival:getType())
            Incoming_event:setFrom(Incoming_event_before_arrival:getFrom())
            Incoming_event:setTo(Incoming_event_before_arrival:getTo())
            Incoming_event:setTrans(table.copy(Incoming_event_before_arrival:getTrans()))
            Incoming_event:setEventGroup(Incoming_event_before_arrival:getEventGroup())
            Incoming_event:setFlipHorizontally(Incoming_event_before_arrival:getFlipHorizontally())
            Incoming_event:setFlipVertically(Incoming_event_before_arrival:getFlipVertically())
        end)
        ChartService:abortChange()
        fEvent:sort()
        messageBox:add('illegal operation')
        return
    end
    -- 提交页面事务：进入页面以来的全部变更合并为一条记录（无差异则不产生记录）
    ChartService:commitChange(actionKey)
end
return Gevent
