local safeInput = require("src.utils.safeInput")
--events界面
local ChartService = require("src.services.chartService")
local eventBus = require("src.utils.eventBus")
local clipboard = require("src.utils.clipboard") -- 剪贴板数据（核心），不引用 ctrl 插件
local Gevents = group:new('events')
Gevents.type = "events"
Gevents.layout = require 'config.layouts.sidebar'.events

Gevents.perturbation = 0 --扰动

Gevents.from = 0
Gevents.to = 0
Gevents.trans_type = {value = 0} --过渡类型 用来切换的
Gevents.trans_expression = {value = ''} --过渡类型的表达式

Gevents.perturbationv = {value = '0'} --扰动
Gevents.fromv = {value = '0'}
Gevents.tov = {value = '0'}

Gevents.expression = function(x) return x end --表达式

Gevents.bezier_index = {value = 1}
Gevents.bezier = {}
local meta_Gevents_bezier = {
    __index ={
        {1,1,1,1}
    
    }
}

local bezier_file = io.open("defaultBezier.txt", "r")  -- 以只读模式打开文件
if bezier_file then
    local content = bezier_file:read("*a")  -- 读取整个文件内容
    bezier_file:close()  -- 关闭文件
    Gevents.bezier = safeInput.parseBezierPresets(content)
end
if type(Gevents.bezier) ~= "table" then
    Gevents.bezier = {}
end

setmetatable(Gevents.bezier,meta_Gevents_bezier)


function Gevents:transDo() --写出表达式
    local text = self.trans_expression.value
    local kind, body = text:match("^%s*(%a+)%s*(.-)%s*$")
    local fn, err
    if kind == "easing" then
        local key = tonumber(body) or body
        local easing = easings[key]
        if type(easing) == "function" then fn = easing end
    elseif kind == "bezier" then
        local points
        if body:find(",", 1, true) then
            points = safeInput.parseTable("{" .. body .. "}")
        else
            points = self.bezier[tonumber(body) or 1]
        end
        if type(points) == "table" and #points == 4 then
            local valid = true
            for i = 1, 4 do
                local n = points[i]
                if type(n) ~= "number" or n ~= n or math.abs(n) == math.huge then valid = false end
            end
            if valid then fn = function(x) return bezier(0, 1, 0, 1, points, x) end end
        end
    elseif kind == "function" then
        local compiled
        compiled, err = safeInput.compileExpression(body)
        if compiled then fn = function(x) return compiled({x = x}) end end
    end
    self.expression_valid = fn ~= nil
    self.expression = fn or function(x) return x end
    if err then log('expression error:', err) end
end

function Gevents:eventsDo() --执行
    if self.expression_valid == false then return end
    local copy_table = clipboard:get()
    if #copy_table.event == 0 then return end
    local proposals = {}
    local first = copy_table.event[1]:getBeatValue()
    local duration = copy_table.event[#copy_table.event]:getBeat2Value() - first
    -- 先验证所有结果，避免算式出错时只修改了一部分事件。
    local ok, err = pcall(function()
        for _, ce in ipairs(copy_table.event) do
            local random = math.random(-self.perturbation, self.perturbation)
            local function value(time, original)
                local progress = duration == 0 and 0 or (time - first) / duration
                local n = original + random + self.from + (self.to - self.from) * self.expression(progress)
                assert(type(n) == "number" and n == n and math.abs(n) ~= math.huge, "Invalid expression result")
                return n
            end
            proposals[#proposals + 1] = {event = ce,
                from = value(ce:getBeatValue(), ce:getFrom()),
                to = value(ce:getBeat2Value(), ce:getTo())}
        end
    end)
    if not ok then log('expression error:', err); return end
    ChartService:change('history.batch_edit_events', function()
        for _, proposal in ipairs(proposals) do
            for k = 1, ChartService:getEventCount() do
                if proposal.event == ChartService:getEvent(k) then
                    proposal.event:setFrom(proposal.from)
                    proposal.event:setTo(proposal.to)
                    break
                end
            end
        end
    end)
end

function Gevents:transToType() --更改过渡类型
    if self.trans_type.value == 0 then
        self.trans_expression.value = 'bezier'
    elseif self.trans_type.value == 1 then
        self.trans_expression.value = 'function'
    else
        self.trans_expression.value = 'easings'
    end
end

function Gevents:up() --快速调整bezier和easing
    if self.trans_expression.value:find("easing") then goto easing end
    if self.trans_expression.value:find("bezier") then goto bezier end

    ::bezier::
    if self.trans_expression.value:find(",") then self.trans_expression.value = 'bezier' end --不支持写进去的  
    --删除到只剩下数字
    self.trans_expression.value = tonumber(string.match(self.trans_expression.value,"%d+") ) or 1
    self.trans_expression.value = self.trans_expression.value + 1
    if not Gevents.bezier[self.trans_expression.value] then self.trans_expression.value = 1 end 
    self.trans_expression.value = 'bezier ' ..self.trans_expression.value
    self:transDo()
    if true then return end

    ::easing:: 
    --删除到只剩下数字
    self.trans_expression.value = tonumber(string.match(self.trans_expression.value,"%d+") ) or 1
    if not easings[self.trans_expression.value] then self.trans_expression.value = 1 end
    self.trans_expression.value = 'easing '..self.trans_expression.value + 1
    self:transDo()
    if true then return end
end

function Gevents:down() --快速调整bezier和easing
    if self.trans_expression.value:find("easing") then goto easing end
    if self.trans_expression.value:find("bezier") then goto bezier end

    ::bezier::
    if self.trans_expression.value:find(",") then self.trans_expression.value = 'bezier' end --不支持写进去的
    --删除到只剩下数字
    self.trans_expression.value = tonumber(string.match(self.trans_expression.value,"%d+") ) or 2
    self.trans_expression.value = self.trans_expression.value -1
    if not Gevents.bezier[self.trans_expression.value] then self.trans_expression.value = #Gevents.bezier end 
    self.trans_expression.value = 'bezier ' ..self.trans_expression.value
    self:transDo()
    if true then return end

    ::easing:: 
    --删除到只剩下数字
    self.trans_expression.value = tonumber(string.match(self.trans_expression.value,"%d+") ) or 2
    if not easings[self.trans_expression.value] then self.trans_expression.value = #easings end
    self.trans_expression.value = 'easing '..self.trans_expression.value - 1
    self:transDo()
    if true then return end
end


function Gevents:Nui()
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)

    if (self.trans_expression.value:find("easing") or self.trans_expression.value:find("bezier") ) then
        if ui:imageButton(isImage.up) then
            Gevents:up()
        end

        if ui:imageButton(isImage.down) then
            Gevents:down()
        end
    else
        Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)
    end

    if Nui:button(i18n:get('do')) then
        self:eventsDo()
    end
    Nui:layoutRow('dynamic', self.layout.uiH, self.layout.cols)

    Nui:label(i18n:get("quick_adjustments"))
    if Nui:slider(0,self.trans_type,2,1) then
        self:transToType()
    end

    Nui:label(i18n:get("perturbation"))
    ui:edit('field',self.perturbationv)
    self.perturbation = tonumber(self.perturbationv.value) or 0

    Nui:label(i18n:get("from"))
    ui:edit('field',self.fromv)
    self.from = tonumber(self.fromv.value) or 0
    
    Nui:label(i18n:get("to"))
    ui:edit('field',self.tov)
    self.to = tonumber(self.tov.value) or 0
    
    Nui:label(i18n:get("trans_expression"))
    local _,c = ui:edit('field',self.trans_expression)

    if c then
        self:transDo()
    end

    local curveColor = settings.theme == 'light' and 0 or 1
    local oldR, oldG, oldB, oldA = love.graphics.getColor()
    love.graphics.setColor(curveColor,curveColor,curveColor,1)
    local x = self.layout.bezier.x
    local y = self.layout.bezier.y
    local w = self.layout.bezier.w
    local h = self.layout.bezier.h
    local trans_y = 0
    local trans_y1 = 0
    for i = 0, 1, 0.01 do
        pcall(function() trans_y = self.expression(i) end)
        trans_y = trans_y or 0
        trans_y = trans_y * -h
        pcall(function() trans_y1 = self.expression(i + 0.01) end)
        trans_y1 = trans_y1 or 0
        trans_y1 = trans_y1 * -h
        Nui:line(w * i +x,trans_y + y + h,w * (i+0.01) +x,trans_y1 + y + h)
    end

    --底线
    Nui:polygon('fill',x,y + h,x + w,y + h,x + w,y + h+3,x,y + h+3)
    --侧线
    Nui:polygon('fill',x + w,y,x + w,y + h,x + w+3,y + h,x + w+3,y)
    love.graphics.setColor(oldR,oldG,oldB,oldA)

end

return Gevents
