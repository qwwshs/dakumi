--开关
local switch_object = {} --对象
local input_string = ""
local function pass() --默认函数
    --pass
end
local meta_type = {__index ={
    input_ed = pass,  --输入完成处理完成之前的回调函数
    input_ed_finish = pass, --输入完成处理完成之后的回调函数
    will_draw = pass, --确认是否绘画
}}
function switch_new(name,var,x,y,w,h,level,thetype) --名字 与所对应的变量
    local istype = thetype or {}
    if type(thetype) ~= "table" then
        istype = {}
    end
    setmetatable(istype,meta_type)
    table.fill(istype,meta_type.__index)
    local islevel = level
    if not level then
        islevel = 2
    end
    switch_object[name] = {var = var,x = x,y = y,w = w,h = h,level = islevel,type=thetype} --level是有几种模式的意思
end

function switch_draw(name)
    if not switch_object[name].type.will_draw() then
        return
    end
    love.graphics.setColor(0.15,0.15,0.15,1)
    love.graphics.rectangle("fill",switch_object[name].x,switch_object[name].y,switch_object[name].w,switch_object[name].h) --内框
    if switch_query_type_in() == name then  --鼠标在这
        love.graphics.setColor(0.5,0.5,0.5,1) --外框
        love.graphics.rectangle("line",switch_object[name].x,switch_object[name].y,switch_object[name].w,switch_object[name].h)
    end
    love.graphics.setColor(0,1,1,0.7) --开关
    love.graphics.rectangle('fill',switch_object[name].x, --开关内
    switch_object[name].y,
    switch_object[name].w * (loadstring("return _G."..switch_object[name].var)() ) / switch_object[name].level
    ,switch_object[name].h)

    love.graphics.setColor(1,1,1,1) --开关
    love.graphics.rectangle('fill',switch_object[name].x + switch_object[name].w * (loadstring("return _G."..switch_object[name].var)() ) / switch_object[name].level, --开关边
    switch_object[name].y,
    5
    ,switch_object[name].h)
    
    --开关档位
    love.graphics.setColor(1,1,1,0.5) --开关
    for i = 1, switch_object[name].level do

        love.graphics.rectangle('fill',switch_object[name].x + switch_object[name].w * i  / switch_object[name].level, --开关边
        switch_object[name].y,
        1
        ,switch_object[name].h)
    end

end
function switch_draw_all()
        for i, v in pairs(switch_object) do
            switch_draw(i)
        end
end


function switch_mousepressed(x,y) --输入
    for i, v in pairs(switch_object) do

        if x >= switch_object[i].x and x <= switch_object[i].x + switch_object[i].w 
        and y <= switch_object[i].y + switch_object[i].h and y >= switch_object[i].y and switch_object[i].type.will_draw() then
            switch_object[i].type.input_ed(input_string)
            if loadstring("return _G."..switch_object[i].var)() >= switch_object[i].level then 
                --大于最大值 回到第一个开关
                loadstring("_G."..switch_object[i].var.."=".. -1)() --因为后面要＋1 所以重置到0
            end
                loadstring("_G."..switch_object[i].var.."=".. "_G."..switch_object[i].var.." + 1")()
                switch_object[i].type.input_ed_finish(input_string)
        end
    end
end

function switch_delete(name) --删除
    switch_object[name] = nil
end

function switch_delete_all() --删除 全部
    switch_object = {}
end

function switch_wheelmoved(x,y,name) --滑轮滚动 使全体位移
    switch_object[name].y = switch_object[name].y + y
end

function switch_query_type_in() --查询现在所在位置
    for i, v in pairs(switch_object) do
        if mouse.x >= switch_object[i].x and mouse.x <= switch_object[i].x + switch_object[i].w 
        and mouse.y <= switch_object[i].y + switch_object[i].h and mouse.y >= switch_object[i].y then
            return i
        end
    end
end