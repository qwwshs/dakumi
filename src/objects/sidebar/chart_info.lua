--子房间 就写成对象了
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local input_type = false --输入状态
local type = "info"
local chart_info_pos_y = 0 --位移
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
object_chart_info = {
    bpm_list_load = function() -- 只改变bpmlist
            --bpmlist表
            bpm_list_sort()
            for i = 1, #chart.bpm_list do
                input_box_new("bpm"..i,"chart.bpm_list["..i.."].bpm",x,y+160+i*30 + chart_info_pos_y,w/2,20,{type ="number",will_draw = will_draw})
                input_box_new("bpm_beat1"..i,"chart.bpm_list["..i.."].beat[1]",x+w/2+10,y+160+i*30 + chart_info_pos_y,w/2,20,{type ="number",will_draw = will_draw})
                input_box_new("bpm_beat2"..i,"chart.bpm_list["..i.."].beat[2]",x+w+20,y+160+i*30 + chart_info_pos_y,w/2,20,{type ="number",will_draw = will_draw})
                input_box_new("bpm_beat3"..i,"chart.bpm_list["..i.."].beat[3]",x+w+w/2+30,y+160+i*30 + chart_info_pos_y,w/2,20,{type ="number",will_draw = will_draw})
            end
    end,
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        chart_info_pos_y = 0
        object_bpm_list.load(x,y+500,0,20,20)
        if not sidebar:room_type(type) then
            return
        else

            input_box_new("chartor","chart.info.chartor",x+ w + 10,y+40 + chart_info_pos_y,w,20,{type ="string",will_draw = will_draw})
            input_box_new("artist","chart.info.artist",x + w + 10,y+80 + chart_info_pos_y,w,20,{type ="string",will_draw = will_draw})

            input_box_new("chart","chart.info.chart_name",x,y+40 + chart_info_pos_y,w,20,{type ="string",will_draw = will_draw})
            input_box_new("music","chart.info.song_name",x,y+80 + chart_info_pos_y,w,20,{type ="string",will_draw = will_draw})

            input_box_new("chart_offset","chart.offset",x,y+120,w,20 + chart_info_pos_y,{type ="number",will_draw = will_draw})
            object_chart_info.bpm_list_load()
        end

        
    end,
    draw = function()
        if not sidebar:room_type(type) then
            return
        end
        

        love.graphics.setColor(1,1,1,1)
        love.graphics.print(i18n:get("chart"),x,y+20 + chart_info_pos_y) 
        love.graphics.print(i18n:get("music"),x,y+60 + chart_info_pos_y) 
        love.graphics.print(i18n:get("chartor"),x+w+10,y+20 + chart_info_pos_y) 
        love.graphics.print(i18n:get("artist"),x+w+10,y+60 + chart_info_pos_y) 

        love.graphics.print(i18n:get("offset(ms)"),x,y+100 + chart_info_pos_y)
        love.graphics.print(i18n:get("bpm"),x,y+160 + chart_info_pos_y)
        love.graphics.print(i18n:get("beat"),x+w+20,y+160 + chart_info_pos_y)

        object_bpm_list.draw()

    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        if not sidebar:room_type(type) then
            return
        end
        time.alltime = music:getDuration() + chart.offset / 1000 -- 得到音频总时长
        beat.allbeat = time_to_beat(chart.bpm_list,time.alltime)
        object_bpm_list.mousepressed(x1,y1)
        bpm_list_sort()
    end,
    keypressed = function(key)
        if not sidebar:room_type(type) then
            return
        end

        
    end,
    wheelmoved = function(x,y)
        if not sidebar:room_type(type) then
            return
        end
        local scroll = 40
        if y < 0 then
            scroll = - scroll
        end
        input_box_wheelmoved(x,scroll,"chartor")
        input_box_wheelmoved(x,scroll,"artist")
        input_box_wheelmoved(x,scroll,"chart")
        input_box_wheelmoved(x,scroll,"music")
        input_box_wheelmoved(x,scroll,"chart_offset")
        chart_info_pos_y = chart_info_pos_y + scroll
        object_bpm_list.wheelmoved(x,scroll)
    end
}