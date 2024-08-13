--设置界面
--子房间 就写成对象了
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local input_type = false --输入状态
local type = "settings"
local ui_break = love.graphics.newImage("asset/ui_break.png")
local chart_info_pos_y = 0 --位移
local setting_type ={}
objact_settings = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        chart_info_pos_y = 0
        setting_type = {judge_line_y = "input_box",
            angle =  "input_box",
            music_volume =  "input_box",
            audio_picture =  "switch1",
            hit_volume =  "input_box",
            hit = "switch1",
            hit_sound = "switch1",
            language= "switch"..(objact_language.get_languages_number() - 1),
            vsync= "switch2",
            contact_roller=  "input_box",
            mouse=  "switch1",
            note_alpha =  "input_box",
            note_height =  "input_box",
        }
        if not room_type(type) then
            return
        else
            input_box_delete_all()
            switch_delete_all()
            local i = 1
            for k, v in pairs(setting_type) do
                if setting_type[k] == "input_box" then
                    input_box_new(k,"settings."..k,x+ w + 10,y+i * 40 + chart_info_pos_y,w,20,"number")
                elseif setting_type[k] and string.sub(setting_type[k],1,6) == "switch" then
                    switch_new(k,"settings."..k,x+ w + 10,y+i * 40 + chart_info_pos_y,w,20,tonumber(string.sub(setting_type[k],7,#setting_type[k])))
                end
                i = i + 1
            end

        end
    end,
    draw = function()
        if not room_type(type) then
            return
        end
        

        --输入框
        input_box_draw_all()
        switch_draw_all()
        love.graphics.setColor(1,1,1,1)
        local i = 1
        for k, v in pairs(setting_type) do
            if setting_type[k]then
                love.graphics.print(objact_language.get_string_in_languages(k),x,y+i * 40 + chart_info_pos_y) 
            end
            i = i + 1
        end


    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        if not room_type(type) then
            return
        end
        objact_bpm_list.mousepressed(x1,y1)
        input_box_mousepressed(x1, y1)
        switch_mousepressed(x1,y1)
        bpm_list_sort()
        save(settings,"settings.txt")
    end,
    keypressed = function(key)
        if not room_type(type) then
            return
        end

        
    end,
    wheelmoved = function(x,y)
        if not room_type(type) then
            return
        end
        input_box_wheelmoved(x,y)
        switch_wheelmoved(x,y)
        chart_info_pos_y = chart_info_pos_y + y * 10
    end
}