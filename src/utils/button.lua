--按钮函数
local button_object = {} --对象
local input_string = ""

local function pass() --空函数
    --pass
end
local meta_type = {__index ={
    input_ed_finish = pass, --输入完成处理完成之后的回调函数
    will_draw = pass, --确认是否绘画
    style2 = nil, --第二个样式
}}
function button_new(name,func,x,y,w,h,style,thetype) --名字 与所对应的变量 还有样式
    local istype = thetype or {}
    if type(thetype) ~= "table" then
        istype = {}
    end
    setmetatable(istype,meta_type)
    table.fill(istype,meta_type.__index)
    button_object[name] = {func = func,x = x,y = y,w = w,h = h,style = style,type=thetype}
end

function button_draw(name)
    if not button_object[name].type.will_draw() then
        return
    end
    love.graphics.setColor(1,1,1,1)
    if type(button_object[name].style) == 'function' then
        button_object[name].style()
    else
        local style_width, style_height = button_object[name].style:getDimensions( ) -- 得到宽高
        local style_scale_h = 1 / style_height * button_object[name].h
        local style_scale_w = 1 / style_width * button_object[name].w
        love.graphics.draw(button_object[name].style,button_object[name].x,button_object[name].y,0,style_scale_w,style_scale_h)
    end
    local pos = button_query_type_in()
    if pos == name then
        if button_object[name].type.style2 then
            if type(button_object[name].type.style2) == 'function' then
                button_object[name].type.style2()
            else
                love.graphics.setColor(1,1,1,1)
                local style_width, style_height = button_object[name].style:getDimensions( ) -- 得到宽高
                local style_scale_h = 1 / style_height * button_object[name].h
                local style_scale_w = 1 / style_width * button_object[name].w
                love.graphics.draw(button_object[name].type.style2,button_object[name].x,button_object[name].y,0,style_scale_w,style_scale_h)
            end
        else
            love.graphics.setColor(0.5,0.5,0.5,0.5)
            love.graphics.rectangle("fill",button_object[name].x,button_object[name].y,button_object[name].w,button_object[name].h)
        end
    end
end
function button_draw_all()
        for i, v in pairs(button_object) do
            button_draw(i)
        end
end


function button_mousepressed(x,y) --输入
    for i, v in pairs(button_object) do

        if x >= button_object[i].x and x <= button_object[i].x + button_object[i].w 
        and y <= button_object[i].y + button_object[i].h and y >= button_object[i].y and button_object[i].type.will_draw() then
            button_object[i].func()
            button_object[i].type.input_ed_finish()
            break
        end
    end
end

function button_delete(name) --删除
    button_object[name] = nil
end

function button_delete_all() --删除 全部
    button_object = {}
end

function button_wheelmoved(x,y,name) --滑轮滚动 使全体位移
        button_object[name].y = button_object[name].y + y
end

function button_query_type_in() --查询现在所在位置
    for i, v in pairs(button_object) do
        
        if mouse.x >= button_object[i].x and mouse.x <= button_object[i].x + button_object[i].w 
        and mouse.y <= button_object[i].y + button_object[i].h and mouse.y >= button_object[i].y and button_object[i].type.will_draw() then
            return i
        end
    end
end