--侧边栏的轨道编辑界面
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local type = "tracks_edit"
local ui_add = isImage.add
local ui_sub = isImage.sub
local choose_track = 0 -- 现在所选择的track
local y_move = 0 --位移
tracks_table = {}
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
local function will_add()
    messageBox:add('add')
    tracks_table[#tracks_table + 1] = 1
    for i = 1 ,#tracks_table do
        input_box_new("tracks_table"..i,"tracks_table["..i.."]",x + 130,y+50+i*30,w/2,20,{type ="number",will_draw = will_draw})
    end
    y_move = 0
end
local function will_sub()
    messageBox:add(choose_track)
    if tracks_table[choose_track] then
        messageBox:add('delete')
        input_box_delete("tracks_table"..#tracks_table) --删掉最后一个 剩下的刷新时向前替换
        table.remove(tracks_table,choose_track)
        for i = 1 ,#tracks_table do --刷新
            input_box_new("tracks_table"..i,"tracks_table["..i.."]",x + 130,y+50+i*30,w/2,20,{type ="number",will_draw = will_draw})
        end
        y_move = 0
    end
end
object_tracks_edit = {
    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        for i = 1 ,#tracks_table do
            input_box_new("tracks_table"..i,"tracks_table["..i.."]",x + 130,y+50+i*30,w/2,20,{type ="number",will_draw = will_draw})
        end
        button_new("tracks_add",will_add,x,700,50,50,ui_add,{will_draw = will_draw})
        button_new("tracks_sub",will_sub,x+ 130,700,50,50,ui_sub,{will_draw = will_draw})
    end,
    mousepressed = function(x1,y1)
        if input_box_query_type_in() and string.sub(input_box_query_type_in(),1,12) == "tracks_table"  then --选择
            local temp_str = input_box_query_type_in()
            choose_track = tonumber(string.sub(temp_str,13,#temp_str))
        elseif not (x1 >= x + 100 and x1 <= x + w +100 and y1 <= y + h  and y1 >= y) then -- 不在删除的位置
            choose_track = 0
        end

    end,
    draw = function()
        if not sidebar:room_type(type) then
            return
        end
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(i18n:get("track"),x,300)
        for i = 1,#tracks_table do
            love.graphics.print(i,x + 100,y+50+i*30 +y_move)
        end
    end,
    wheelmoved = function(x1,y1)
        if not sidebar:room_type(type) then
            return
        end
        for i = 1,#tracks_table do
            input_box_wheelmoved(x1,y1,"tracks_table"..i)
        end
        y_move = y_move + y1 *10

    end
}