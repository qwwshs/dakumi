--设置界面
--子房间 就写成对象了
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local input_type = false --输入状态
local roomtype = "settings"
local chart_info_pos_y = 0 --位移
local setting_type ={}
local function will_draw()
    return sidebar:room_type(roomtype) and the_room_pos({"edit",'tracks_edit'})
end

local function input_box_ed_finish()
    save(dkjson.encode(settings, { indent = true }),PATH.usersPath.settings..'settings.json')
end

-- 读取设置文件
local settings_file = io.open(PATH.usersPath.settings..'settings.json', "r")
if settings_file then
    local content = settings_file:read("*a")  -- 读取整个文件内容
    settings_file:close()  -- 关闭文件
    settings = dkjson.decode(content)
end
if type(settings) ~= "table" then
    settings = {}
end
setmetatable(settings,meta_settings)
    
table.fill(settings,meta_settings.__index)

object_settings = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        chart_info_pos_y = 0
        
        setting_type = {
            {'judge_line_y',"input_box"},
            {'music_volume',"input_box"},
            {'hit_volume',"input_box"},
            {'hit',"switch1"},
            {'hit_sound',"switch1"},
            {'track_w_scale',"input_box"},
            {'language',"switch"..(i18n:get_languages_number() - 1)},
            {'contact_roller',"input_box"},
            {'note_height',"input_box"},
            {'bg_alpha',"input_box"},
            {'denom_alpha',"input_box"},
            {'auto_save',"switch1"},
            {'window_width',"input_box"},
            {'window_height',"input_box"},
        }
        if not sidebar:room_type(roomtype) then
            return
        else
            for k=1,#setting_type do
                if setting_type[k][2] == "input_box" then
                    input_box_new(setting_type[k][1],"settings."..setting_type[k][1],x+ w + 10,y+k * 40 + chart_info_pos_y,w,20,{type = "number",will_draw = will_draw,input_ed_finish = input_box_ed_finish})
                elseif setting_type[k][2] and string.sub(setting_type[k][2],1,6) == "switch" then
                    switch_new(setting_type[k][1],"settings."..setting_type[k][1],x+ w + 10,y+k * 40 + chart_info_pos_y,w,20,tonumber(string.sub(setting_type[k][2],7,#setting_type[k][2])),{will_draw = will_draw,input_ed_finish = input_box_ed_finish})
                end
            end

        end
    end,
    draw = function()
        if not sidebar:room_type(roomtype) then
            return
        end
    

        love.graphics.setColor(1,1,1,1)
        for k=1,#setting_type do
            if setting_type[k] then
                love.graphics.print(i18n:get(setting_type[k][1]),x,y+k * 40 + chart_info_pos_y) 
            end
        end


    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        if not sidebar:room_type(roomtype) then
            return
        end
        object_bpm_list.mousepressed(x1,y1)

        
        bpm_list_sort()
    end,
    keypressed = function(key)
        if not sidebar:room_type(roomtype) then
            return
        end

        
    end,
    wheelmoved = function(x,y)
        if not sidebar:room_type(roomtype) then
            return
        end
        local scroll = 40 --滚动值
        if y < 0 then
            scroll = -scroll
        end
        for i=1,#setting_type do
            if setting_type[i][2] == "input_box" then
                input_box_wheelmoved(x,scroll,setting_type[i][1])
            elseif string.sub(setting_type[i][2],1,6) == "switch" then
                switch_wheelmoved(x,scroll,setting_type[i][1])
            end
        end
        chart_info_pos_y = chart_info_pos_y + scroll
    end
}