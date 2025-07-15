--预设的bezier表格
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0

bezier_index = 1 --表格位置索引
default_bezier = {}
local meta_default_bezier = {
    __index ={
        {1,1,1,1}
    
    }
}

local bezier_file = io.open("defaultBezier.txt", "r")  -- 以只读模式打开文件
if bezier_file then
    local content = bezier_file:read("*a")  -- 读取整个文件内容
    bezier_file:close()  -- 关闭文件
    default_bezier = loadstring("return "..content)()
end
if type(default_bezier) ~= "table" then
default_bezier = {}
end
setmetatable(default_bezier,meta_default_bezier) --防报废

local function will_draw()
    return string.sub(sidebar.displayed_content,1,5) == "event" and the_room_pos({"edit",'tracks_edit'})
end
local function input_ed_finish()
    local trans1,trans2,trans3,trans4 = default_bezier[bezier_index][1],default_bezier[bezier_index][2],
    default_bezier[bezier_index][3],default_bezier[bezier_index][4]

    trans1 = math.floor(trans1 * 100) / 100
    trans2 = math.floor(trans2 * 100) / 100
    trans3 = math.floor(trans3 * 100) / 100
    trans4 = math.floor(trans4 * 100) / 100
    chart.event[tonumber(string.sub(sidebar.displayed_content,6,#sidebar.displayed_content))].trans = {trans1,trans2,trans3,trans4}
end

local function up()
    bezier_index = bezier_index + 1
    if not default_bezier[bezier_index] then
        bezier_index = 1
    end
    local trans1,trans2,trans3,trans4 = default_bezier[bezier_index][1],default_bezier[bezier_index][2],
    default_bezier[bezier_index][3],default_bezier[bezier_index][4]

    trans1 = math.floor(trans1 * 100) / 100
    trans2 = math.floor(trans2 * 100) / 100
    trans3 = math.floor(trans3 * 100) / 100
    trans4 = math.floor(trans4 * 100) / 100
    chart.event[tonumber(string.sub(sidebar.displayed_content,6,#sidebar.displayed_content))].trans = {trans1,trans2,trans3,trans4}
end

local function down()
    bezier_index = math.abs(bezier_index - 2) + 1--防止非自然数
    if not default_bezier[bezier_index] then
        bezier_index = 1
    end
        local trans1,trans2,trans3,trans4 = default_bezier[bezier_index][1],default_bezier[bezier_index][2],
        default_bezier[bezier_index][3],default_bezier[bezier_index][4]

        trans1 = math.floor(trans1 * 100) / 100
        trans2 = math.floor(trans2 * 100) / 100
        trans3 = math.floor(trans3 * 100) / 100
        trans4 = math.floor(trans4 * 100) / 100
        chart.event[tonumber(string.sub(sidebar.displayed_content,6,#sidebar.displayed_content))].trans = {trans1,trans2,trans3,trans4}
end

object_event_edit_default_bezier = { --bezier表格的
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("bezier_up",up,x,y,w,h,ui:up(x,y,w,h),{will_draw = will_draw})
        button_new("bezier_down",down,x,y + h,w,h,ui:down(x,y+h,w,h),{will_draw = will_draw})
        input_box_new("bezier_index","bezier_index",x-50,y + h,50,h,{type = "number",will_draw = will_draw,input_ed_finish = input_ed_finish})
    end,
    draw = function()
        if not(string.sub(sidebar.displayed_content,1,5) == "event") then -- 太特殊 所以不用type 和roomtype 判断
            return
        end
        love.graphics.print(i18n:get("bezier"),x-50,y)

    end,
    keyboard = function(key)

    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
    textinput = function(input)

    end
}