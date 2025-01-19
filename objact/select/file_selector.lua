--文件选择器
--不再使用
--[[
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local drive_letter = nativefs.getDriveList() --盘
selector_now_path = "C:/"
selector_file_open = false
local all_file = nativefs.getDirectoryItems(selector_now_path) --得到文件夹下的所有文件
local select_file = 1
local now_drive_letter_pos = 1 --现在选择的盘
local now_file_pos = 1 --现在选择的文件
local drive_letter_pos_move = 0 --位移
local file_pos_move = 0 --位移

local function input()
        objact_selector.anew_find()
end
local function will_draw()
    return selector_file_open
end
objact_selector = {
    open = function()
        selector_file_open = true
        objact_selector.load_path()
        animation_new("file_selector_w",0,w,0,0.3,{0,0,1,1})
        animation_new("file_selector_h",0,h,0,0.3,{0,0,1,1})
    end,
    load_path = function() --对路径初始化
        selector_now_path = "C:/"
        all_file = nativefs.getDirectoryItems(selector_now_path) --得到文件夹下的所有文件
        input_box_new("selector_now_path",'selector_now_path',x+100,y+5,w - 200,20,{input_ed_finish = input,will_draw = will_draw})
    end,
    anew_find = function() --重新搜索路径
        all_file = nativefs.getDirectoryItems(selector_now_path) --得到文件夹下的所有文件
    end,
    load = function(x1,y1,r1,w1,h1)
        if selector_file_open == true then
            return
        end
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        --为啥 因为select那导入文件会初始化一次
        objact_selector.load_path()
        objact_selector_break.load(x+10,y+30,0,20,20)
        objact_selector_close.load(x+w-30,y+5,0,20,20)
        objact_selector_refresh.load(x+50,y+100,0,20,20)
        animation_new("file_selector_w",w,w,0,0.3,{0,0,1,1})
        animation_new("file_selector_h",h,h,0,0.3,{0,0,1,1})
    end,
    draw = function()
        if selector_file_open == false then
            return
        end
        love.graphics.setColor(1,1,1,1) --背景板
        love.graphics.rectangle("line",x,y,w,h)
        love.graphics.setColor(0,0,0,0.7)
        love.graphics.rectangle("fill",x,y,w,h)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(objact_language.get_string_in_languages("file selector"),x,y)

        love.graphics.setColor(1,1,1,1)
        

        for i = 1, #drive_letter do --盘符
            if 30 + (i + drive_letter_pos_move) * 30 < h and 30 + (i + drive_letter_pos_move) * 30 > 20 then --在范围内
                love.graphics.setColor(1,1,1,0.3)
                love.graphics.rectangle("line",x+50,y + 100 + (i + drive_letter_pos_move) * 30,40,20)
                if i == now_drive_letter_pos then --选择到的
                    love.graphics.setColor(1,1,1,0.2)
                    love.graphics.rectangle("fill",x+50,y + 100 + (i + drive_letter_pos_move) * 30,40,20)
                    love.graphics.setColor(0.5,1,1,1)
                    love.graphics.rectangle("line",x+50,y + 100 + (i + drive_letter_pos_move) * 30,40,20)

                    love.graphics.setColor(0,1,1,1)
                    love.graphics.print("-> ".. drive_letter[i],x+50,y + 100 + (i + drive_letter_pos_move) * 30)
                else
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.print(drive_letter[i],x+50,y + 100 + (i + drive_letter_pos_move) * 30)
                end
            end
        end

        for i = 1,#all_file do --文件
            if 30 + (i + file_pos_move) * 20 < h and 30 + (i + file_pos_move) * 20 > 20 then --在范围内
                love.graphics.setColor(1,1,1,0.3)
                love.graphics.rectangle("line",x+160,y + 30 + (i + file_pos_move) * 20,w - 160,20)
                if i == now_file_pos then --选择到的
                    love.graphics.setColor(1,1,1,0.2)
                    love.graphics.rectangle("fill",x+160,y + 30 + (i + file_pos_move) * 20,w - 160,20)
                    love.graphics.setColor(0.5,1,1,1)
                    love.graphics.rectangle("line",x+160,y + 30 + (i + file_pos_move) * 20,w - 160,20)
                    love.graphics.setColor(0,1,1,1)
                    love.graphics.print("-> ".. all_file[i],x+200,y + 30 + (i + file_pos_move) * 20)
                else
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.print(all_file[i],x+160,y + 30 + (i + file_pos_move) * 20)
                end
            end
        end
        

        objact_selector_break.draw()
        objact_selector_close.draw()
        objact_selector_refresh.draw()
    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        if selector_file_open == false then
            return
        end
        if x1 >= x and x1 <= x + w and y1 <= y + h and y1 >= y then -- 在范围内
            objact_selector.anew_find()
            if x1 > 100 + x then --文件选择
                if now_file_pos == math.floor((y1-20-y)/20) - file_pos_move then --进入
                    suffix = string.find(all_file[now_file_pos], ".[^.]*$") --得到后缀
                    if suffix then
                        --是文件 如果是特殊文件就导入
                        local suffix_type = string.sub(all_file[now_file_pos],suffix+1)
                        objact_message_box.message(suffix_type)
                        if suffix_type == "ogg" or suffix_type == "wav" or suffix_type == "mp3" 
                        or suffix_type == "txt" or suffix_type == "mc" or suffix_type == "zip" 
                        or suffix_type == "jpg" or suffix_type == "png" then
                            local file = love.filesystem.newFile("temporary/"..all_file[now_file_pos])
                            file:open("w")
                            local data = nativefs.read(selector_now_path.."/"..all_file[now_file_pos])
                            file:write(data)
                            file:close()
                            room_select.filedropped(file) --导入文件
                            selector_file_open = false --关闭
                            
                            return
                        end
                    end

                    selector_now_path = selector_now_path.."/"..all_file[now_file_pos]
                    objact_selector.anew_find()
                    file_pos_move = 0
                    now_file_pos = 1
                    return
                end
                now_file_pos = math.floor((y1-20-y)/20) - file_pos_move
                if now_file_pos < 1 then
                    now_file_pos = 1
                end
                if now_file_pos > #all_file then
                    now_file_pos = #all_file
                end
            else --盘符选择
                if now_drive_letter_pos == math.floor((y1-100-y)/30) - drive_letter_pos_move then --进入
                    selector_now_path = drive_letter[now_drive_letter_pos]
                    objact_selector.anew_find()
                    file_pos_move = 0
                    drive_letter_pos_move = 0
                    return
                end
                now_drive_letter_pos = math.floor((y1-100-y)/30) - drive_letter_pos_move
                if now_drive_letter_pos < 1 then
                    now_drive_letter_pos = 1
                end
                if now_drive_letter_pos > #drive_letter then
                    now_drive_letter_pos = #drive_letter
                end
            end
        end
        objact_selector_break.mousepressed(x1,y1)
        objact_selector_close.mousepressed(x1,y1)
        objact_selector_refresh.mousepressed(x1,y1)
    end,
    wheelmoved = function(x1,y1)
        if selector_file_open == false then
            return
        end
        if mouse.x < x or mouse.x > x + w and mouse.y < y or mouse.y > y + h then
            return
        end
        if mouse.x < 100 + x then
            if y1 < 0  then
                drive_letter_pos_move = drive_letter_pos_move - 1
            elseif y1 > 0 then
                drive_letter_pos_move = drive_letter_pos_move + 1
            end
        elseif mouse.x > 100 + x then
            if y1 < 0  then
                file_pos_move = file_pos_move - 1
            elseif y1 > 0 then
                file_pos_move = file_pos_move + 1
            end
        end
        while 30 + (1 + file_pos_move) * 20 > h do --限制范围
            file_pos_move = file_pos_move - 1
        end
        while 30 + (#all_file + file_pos_move) * 20 < 0 do
            file_pos_move = file_pos_move + 1
        end
        if  30 + #all_file * 20 < h and 30 + 1 * 20 > 20  then --如果第一个和最后一个文件夹都在框内就不给移动
            file_pos_move = 0
        end

    end,
    keyboard = function(key)
        if selector_file_open == false then
            return
        end
    end,
    update = function(dt)
        w = animation.file_selector_w
        h = animation.file_selector_h
    end
}
]]