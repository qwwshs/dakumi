--bpmlist表相关的操作 （选择 删除 增加）
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local choose_bpm = 0 -- 现在所选择的bpm
local type = "info"
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end

local function will_do_add()
    messageBox:add("add bpm")

    --反推位置
    local pos_beat = beat.nowbeat
    local pos_min_denom = 1 --假设1最近
    for i = 1, denom.denom do --取分度 哪个近取哪个
        if math.abs(pos_beat - (math.floor(pos_beat) + i / denom.denom)) < math.abs(pos_beat - (math.floor(pos_beat) + pos_min_denom / denom.denom)) then
            pos_min_denom = i
        end

    end
    --往当前beat位置添加一个bpm
    chart.bpm_list[#chart.bpm_list + 1] = {beat = {math.floor(pos_beat),pos_min_denom,denom.denom},bpm = 120}

    --排序
    object_chart_info.bpm_list_load()

end
local function will_do_sub()
    messageBox:add("delete bpm")
    --删除当前所选择的bpm
    if chart.bpm_list[choose_bpm] and choose_bpm ~= 1 then --不是第一个bpm 和是bpm就删除
        table.remove(chart.bpm_list,choose_bpm)
        input_box_delete_choose() --全部不选择

        input_box_delete("bpm"..choose_bpm) --删除所选择的bpm
        input_box_delete("bpm_beat1"..choose_bpm)
        input_box_delete("bpm_beat2"..choose_bpm)
        input_box_delete("bpm_beat3"..choose_bpm)

        object_chart_info.bpm_list_load()
    end
end
object_bpm_list = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("add_bpm",will_do_add,x,y,w,h,ui:add(x,y,w,h),{will_draw = will_draw})
        button_new("sub_bpm",will_do_sub,x+w+20,y,w,h,ui:sub(x+w+20,y,w,h),{will_draw = will_draw})
    end,
    draw = function()
    end,
    keyboard = function(key)

    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        --bpm选择器
        if input_box_query_type_in() and string.sub(input_box_query_type_in(),1,3) == "bpm" and string.sub(input_box_query_type_in(),-1,-1) ~= "1" then --选择
            local temp_str = input_box_query_type_in()
            choose_bpm = tonumber(string.sub(temp_str,4,#temp_str))
        elseif not (x1 >= x + w + 20 and x1 <= x + w + w + 20 and y1 <= y + h  and y1 >= y) then -- 不在删除的位置
            choose_bpm = 0
        end

    end,
    wheelmoved = function(x,y)
        for i = 1, #chart.bpm_list do
            input_box_wheelmoved(x,y,"bpm"..i)
            input_box_wheelmoved(x,y,"bpm_beat1"..i)
            input_box_wheelmoved(x,y,"bpm_beat2"..i)
            input_box_wheelmoved(x,y,"bpm_beat3"..i)
        end
    end
}