local x = 0
local y = 0
local w = 0
local h = 0
local r = 0

local function will_draw()
    return the_room_pos({"edit",'tracks_edit'}) and not demo_mode
end
local function do_up()
    denom.denom = denom.denom + 1
end
local function do_down()
    denom.denom = math.max(denom.denom - 1,1)
end
objact_denom = { --分度改变用的
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        input_box_new("denom","denom.denom",x-50,y + h,50,h,{type = "number",will_draw = will_draw})
        button_new("denom_up",do_up,x,y,w,h,ui:up(x,y,w,h),{will_draw = will_draw})
        button_new("denom_down",do_down,x,y+h,w,h,ui:down(x,y+h,w,h),{will_draw = will_draw})
    end,
    draw = function()

        love.graphics.print(objact_language.get_string_in_languages("denom"),x-50,y)

    end,
    keyboard = function(key)
        if key == "up" then
            do_up()
        elseif key == "down" then
            do_down()
        end

    end,
    mousepressed = function( x1, y1, button, istouch, presses )

    end,
    wheelmoved = function(x,y)
        if mouse.x > 1200 then  --限制范围
            return
        end
        --beat更改
            local temp = settings.contact_roller--临时数值

            if y > 0 then
                temp = temp/ denom.denom
            else
                temp = -temp/ denom.denom
            end
    
            beat.nowbeat = beat.nowbeat +temp
            if beat.nowbeat < 0 then
                beat.nowbeat = 0
            end
            if beat.nowbeat >= beat.allbeat then
                beat.nowbeat = beat.allbeat
            end

            local min_denom = 0 --假设0最近
            for i = 1, denom.denom do --取分度 哪个近取哪个
                if math.abs(beat.nowbeat - (math.floor(beat.nowbeat) + i / denom.denom)) < math.abs(beat.nowbeat - (math.floor(beat.nowbeat) + min_denom / denom.denom)) then
                    min_denom = i
                end
            end
            beat.nowbeat = math.floor(beat.nowbeat) + min_denom / denom.denom --更正位置
    
            time.nowtime = beat_to_time(chart.bpm_list,beat.nowbeat)
            music_play = false
    end,
    textinput = function(input)

    end
}