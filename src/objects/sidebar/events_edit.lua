--多事件编辑
local x = 0
local y = 0
local r = 0
local w = 0
local h = 0
local pos = "multiple_events_edit"
events_edit_perturbation = 0 --扰动
events_edit_from = 0 --总的from
events_edit_to = 0 --总的to
events_trans_type = 0 --过渡类型 用来快速切换的
events_edit_trans_expression = '' --过渡类型的表达式
local expression = function(x) return x end --表达式

local function will_draw()
    return sidebar:room_type(pos) and the_room_pos({"edit",'tracks_edit'})
end

local function trans_input_ed_finish() --开关输入完成后的回调 写出表达式
    local temp_string = ''
    if events_edit_trans_expression:find("easing") then
        temp_string = events_edit_trans_expression:gsub('easing','')
        temp_string = temp_string:gsub(' ','')
        if string.match(temp_string, "%d") then --有数字用数字确定easings
            expression = loadstring ('x = ... return easings.easings_use_number['..temp_string..'](x)')
        else
            expression = loadstring ('x = ... return easings.easings_use_string.'..temp_string..'(x)')
        end
        return
    elseif events_edit_trans_expression:find("bezier") then
        if not events_edit_trans_expression:find(",") then --单个数字
            temp_string = events_edit_trans_expression:gsub('bezier','')
            temp_string = tonumber(temp_string) or 1
            if not default_bezier[temp_string] then temp_string = 1 end

            expression = loadstring ('x = ... return bezier(0,1,0,1,'..tableToString(default_bezier[temp_string]) ..',x)')

            return 
        end 

        temp_string = '{'..events_edit_trans_expression:gsub('bezier','') .. '}'
        temp_string = temp_string:gsub(' ','')
        expression = loadstring ('x = ... return bezier(0,1,0,1,'..temp_string..',x)')
        return
    elseif events_edit_trans_expression:find("function") then
        temp_string = events_edit_trans_expression:gsub('function','')
        temp_string = temp_string:gsub(' ','')
        expression = loadstring ('x = ... return '..temp_string)
        return
    end
end
local function do_events() --执行

    local copy_table = get_copy()
    for i = 1,#copy_table.event do
        for k = 1,#chart.event do
            if table.eq(copy_table.event[i],chart.event[k]) then
                local ok,err = pcall(function() local a = expression(1) end)
                if not ok then --处理错误的表达式
                    expression = function(x) return x end
                    log('expression error:',err)
                end
                local from_to_random = math.random(-events_edit_perturbation,events_edit_perturbation)
                copy_table.event[i].from = copy_table.event[i].from + from_to_random + events_edit_from + 
                ((events_edit_to - events_edit_from) *
                expression(((thebeat(copy_table.event[i].beat) - thebeat(copy_table.event[1].beat))/
                (thebeat(copy_table.event[#copy_table.event].beat2) - thebeat(copy_table.event[1].beat) ) )) )--一起修改 保证copy_tab与chart的event一致
                
                copy_table.event[i].to = copy_table.event[i].to + from_to_random + events_edit_from +
                ((events_edit_to - events_edit_from) *
                expression(((thebeat(copy_table.event[i].beat2) - thebeat(copy_table.event[1].beat))/
                (thebeat(copy_table.event[#copy_table.event].beat2) - thebeat(copy_table.event[1].beat) ))) )
                chart.event[k].from = copy_table.event[i].from
                chart.event[k].to = copy_table.event[i].to
            end
        end
    end
end
local function draw_events_button_do()
    ui_style:button(x+ w + 10,700,100,25,i18n:get("do"))
end

local function to_trans_type() --更改过渡类型
    if events_trans_type == 0 then
        events_edit_trans_expression = 'bezier'
    elseif events_trans_type == 1 then
        events_edit_trans_expression = 'function'
    else
        events_edit_trans_expression = 'easings'
    end
end

local function will_draw_up_down()
    return (events_edit_trans_expression:find("easing") or events_edit_trans_expression:find("bezier") )and will_draw() --只有这两个才可以快速调整
end

local function will_up() --快速调整bezier和easing
    if events_edit_trans_expression:find("easing") then goto easing end
    if events_edit_trans_expression:find("bezier") then goto bezier end

    ::bezier::
    if events_edit_trans_expression:find(",") then events_edit_trans_expression = 'bezier' end --不支持写进去的  
    --删除到只剩下数字
    events_edit_trans_expression = tonumber(string.match(events_edit_trans_expression,"%d+") ) or 1
    events_edit_trans_expression = events_edit_trans_expression + 1
    if not default_bezier[events_edit_trans_expression] then events_edit_trans_expression = 1 end 
    events_edit_trans_expression = 'bezier ' ..events_edit_trans_expression
    trans_input_ed_finish()
    if true then return end

    ::easing:: 
    --删除到只剩下数字
    events_edit_trans_expression = tonumber(string.match(events_edit_trans_expression,"%d+") ) or 1
    if not easings.easings_use_number[events_edit_trans_expression] then events_edit_trans_expression = 1 end
    events_edit_trans_expression = 'easing '..events_edit_trans_expression + 1
    trans_input_ed_finish()
    if true then return end
end
local function will_down() --快速调整bezier和easing
    if events_edit_trans_expression:find("easing") then goto easing end
    if events_edit_trans_expression:find("bezier") then goto bezier end

    ::bezier::
    if events_edit_trans_expression:find(",") then events_edit_trans_expression = 'bezier' end --不支持写进去的
    --删除到只剩下数字
    events_edit_trans_expression = tonumber(string.match(events_edit_trans_expression,"%d+") ) or 2
    events_edit_trans_expression = events_edit_trans_expression -1
    if not default_bezier[events_edit_trans_expression] then events_edit_trans_expression = #default_bezier end 
    events_edit_trans_expression = 'bezier ' ..events_edit_trans_expression
    trans_input_ed_finish()
    if true then return end

    ::easing:: 
    --删除到只剩下数字
    events_edit_trans_expression = tonumber(string.match(events_edit_trans_expression,"%d+") ) or 2
    if not easings.easings_use_number[events_edit_trans_expression] then events_edit_trans_expression = #easings.easings_use_number end
    events_edit_trans_expression = 'easing '..events_edit_trans_expression - 1
    trans_input_ed_finish()
    if true then return end
end

object_events_edit = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("events_edit_do",do_events,x+ w + 10,700,100,25,draw_events_button_do,{will_draw = will_draw})

        button_new("events_edit_up",will_up,x + 75,300,25,25,ui:up(x +  75,300,25,25),{will_draw = will_draw_up_down})
        button_new("events_edit_down",will_down,x + 100,300,25,25,ui:down(x + 100,300,25,25),{will_draw = will_draw_up_down})
        switch_new("events_trans_type","events_trans_type",x+ w + 10,300,100,25,2,{will_draw = will_draw,input_ed_finish = to_trans_type})

        input_box_new("events_edit_perturbation","events_edit_perturbation",x+ w + 10,100,100,25,{type = "number",will_draw = will_draw})
        input_box_new("events_edit_from","events_edit_from",x+ w + 10,150,100,25,{type = "number",will_draw = will_draw})
        input_box_new("events_edit_to","events_edit_to",x+ w + 10,200,100,25,{type = "number",will_draw = will_draw})
        input_box_new("events_edit_trans_expression","events_edit_trans_expression",x+ w + 10,250,100,25,{will_draw = will_draw,input_ed_finish = trans_input_ed_finish})
        if not sidebar:room_type(pos) then
            return
        end
        
    end,
    draw = function()
        if not sidebar:room_type(pos) then
            return
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(i18n:get("perturbation"),x,100)
        love.graphics.print(i18n:get("from"),x,150)
        love.graphics.print(i18n:get("to"),x,200)
        love.graphics.print(i18n:get("trans_expression"),x,250)
        love.graphics.print(i18n:get("quick_adjustments"),x,300)
            --函数图像绘制
        love.graphics.rectangle('fill',1300,600,200,2)
        love.graphics.rectangle('fill',1300,600,2,-200)
        love.graphics.setColor(0,1,1,1)
        for i = 0, 1, 0.01 do
            local y = 0
            pcall(function() y = expression(i) end)
            y = y or 0
            love.graphics.rectangle('fill',1300 + i*200,600-y*200,2,2)
        end
    end,
}