--events界面
local ChartService = require("src.services.chartService")
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
    Gevents.bezier = loadstring("return "..content)()
end
if type(Gevents.bezier) ~= "table" then
    Gevents.bezier = {}
end

setmetatable(Gevents.bezier,meta_Gevents_bezier)


function Gevents:transDo() --写出表达式
    local temp_string = ''
    if self.trans_expression.value:find("easing") then
        temp_string = self.trans_expression.value:gsub('easing','')
        temp_string = temp_string:gsub(' ','')
        if string.match(temp_string, "%d") then --有数字用数字确定easings
            self.expression = loadstring ('x = ... return easings['..temp_string..'](x)')
        else
            self.expression = loadstring ('x = ... return easings.'..temp_string..'(x)')
        end
        return
    elseif self.trans_expression.value:find("bezier") then
        if not self.trans_expression.value:find(",") then --单个数字
            temp_string = self.trans_expression.value:gsub('bezier','')
            temp_string = tonumber(temp_string) or 1
            if not Gevents.bezier[temp_string] then temp_string = 1 end

            self.expression = loadstring ('x = ... return bezier(0,1,0,1,'..tableToString(Gevents.bezier[temp_string]) ..',x)')

            return 
        end 

        temp_string = '{'..self.trans_expression.value:gsub('bezier','') .. '}'
        temp_string = temp_string:gsub(' ','')
        self.expression = loadstring ('x = ... return bezier(0,1,0,1,'..temp_string..',x)')
        return
    elseif self.trans_expression.value:find("function") then
        temp_string = self.trans_expression.value:gsub('function','')
        temp_string = temp_string:gsub(' ','')
        self.expression = loadstring ('x = ... return '..temp_string)
        return
    end
end
function Gevents:eventsDo() --执行
    if not ctrl then return end
    local copy_table = ctrl:get_copy()
    local before_map = {} --修改前的快照：k -> 该次 do 前的 event 副本
    for i = 1,#copy_table.event do
        for k = 1, ChartService:getEventCount() do
            if copy_table.event[i] == ChartService:getEvent(k) then
                local ok,err = pcall(function() local a = self.expression(1) end)
                if not ok then --处理错误的表达式
                    self.expression = function(x) return x end
                    log('expression error:',err)
                end
                local ce = copy_table.event[i]
                local from_to_random = math.random(-self.perturbation,self.perturbation)
                local new_from = ce:getFrom() + from_to_random + self.from +
                ((self.to - self.from) *
                self.expression(((ce:getBeatValue() - copy_table.event[1]:getBeatValue())/
                (copy_table.event[#copy_table.event]:getBeat2Value() - copy_table.event[1]:getBeatValue()) )) )--一起修改 保证copy_tab与chart的event一致

                local new_to = ce:getTo() + from_to_random + self.from +
                ((self.to - self.from) *
                self.expression(((ce:getBeat2Value() - copy_table.event[1]:getBeatValue())/
                (copy_table.event[#copy_table.event]:getBeat2Value() - copy_table.event[1]:getBeatValue()) )) )
                before_map[k] = before_map[k] or ChartService:getEvent(k):copy()
                ce:setFrom(new_from)
                ce:setTo(new_to)
                ChartService:getEvent(k):setFrom(new_from)
                ChartService:getEvent(k):setTo(new_to)
            end
        end
    end
    --一次 do 产生一条撤销记录（只记录实际发生变更的事件）
    if redo and next(before_map) then
        local add, del = {}, {}
        for k, old in pairs(before_map) do
            local cur = ChartService:getEvent(k)
            if cur and not old:eq(cur) then
                table.insert(del, old)
                table.insert(add, cur:copy())
            end
        end
        if next(add) then
            redo:writeRevoke({add = {event = add, note = {}}, del = {event = del, note = {}}},
                nil, 'history.batch_edit_events')
        end
    end
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

    love.graphics.setColor(1,1,1)
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

end

return Gevents
