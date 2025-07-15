local pos = "tracks_edit"
tracks_edit_x_move = 0 --x方向的移动
room_tracks_edit = { --多轨道编辑
load = function()
    
end,
update = function(dt)
    if not the_room_pos(pos) then
        return
    end
    edit:update(dt)
    track.track = tracks_table[math.floor(((mouse.x-20) / 300)) + 1 - tracks_edit_x_move] or 1
end,
draw = function()
    if not the_room_pos(pos) then
        return
    end
    if not demo then 
        object_demo_inplay.draw(1200/900,1)
    else
        object_demo_inplay.draw()
    end

    if demo then return end


    object_denom_play.draw()
    love.graphics.setColor(0,0,0,0.5) --背景板 减少play界面的亮度
    love.graphics.rectangle("fill",0,0,1200,WINDOW.h)

    --edit区轨道渲染
    for i = 1,#tracks_table do
        if i-1 + tracks_edit_x_move >= 4 then
            break
        end
        object_note_play_in_edit.draw(20+(i-1 + tracks_edit_x_move)*300,tracks_table[i])
    end
    
    
    if mouse.x < 1200 then
        local temp_x = mouse.x --对mousex作假 模拟非多线编辑下的输入
        mouse.x = (mouse.x-20)%300 + 900
        object_copy.draw(math.floor((temp_x)/300 + tracks_edit_x_move)*300+20)
        mouse.x = temp_x
    end

    love.graphics.setColor(0,1,1,1)
    love.graphics.setFont(FONT.plus)
    love.graphics.print('esc exit',0,0)
    love.graphics.setFont(FONT.normal)
end,
keypressed = function(key)
    if not the_room_pos(pos) then
        return
    end
    if mouse.x > 1200 then
        return
    end
    --退回
    if key == 'escape' then
        room_pos = "edit"
    end
    --增加、减少tracks移动
    if key == 'left' then
        tracks_edit_x_move = tracks_edit_x_move - 1
    end
    if key == 'right' then
        tracks_edit_x_move = tracks_edit_x_move + 1
    end

    room_pos = 'edit'
    local temp_x = mouse.x --对mousex作假 模拟非多线编辑下的输入
    mouse.x = (mouse.x-20)%300 + 900
    edit:keypressed(key)
    mouse.x = temp_x
    room_pos = 'tracks_edit'
end,
keyreleased = function(key)
    if not the_room_pos(pos) then
        return
    end
    if mouse.x > 1200 then
        return
    end
    --退回
    if key == 'escape' then
        room_pos = "edit"
        return
    end
    room_pos = 'edit'
    local temp_x = mouse.x --对mousex作假 模拟非多线编辑下的输入
    mouse.x = (mouse.x-20)%300 + 900
    edit:keyreleased(key)
    mouse.x = temp_x
    room_pos = 'tracks_edit'
end,
mousepressed = function(x,y,button)
    if not the_room_pos(pos) then
        return
    end
    if x > 1200 then
        return
    end
    room_pos = 'edit'
    local temp_x = mouse.x --对mousex作假 模拟非多线编辑下的输入
    mouse.x = (mouse.x-20)%300 + 900
    edit:mousepressed(mouse.x,y,button)
    mouse.x = temp_x
    room_pos = 'tracks_edit'
end,
mousereleased = function(x,y,button)
    if not the_room_pos(pos) then
        return
    end
    if mouse.x > 1200 then
        return
    end
    --退回

    room_pos = 'edit'
    local temp_x = mouse.x --对mousex作假 模拟非多线编辑下的输入
    mouse.x = (mouse.x-20)%300 + 900
    edit:mousereleased(mouse.x,y,button)
    mouse.x = temp_x
    room_pos = 'tracks_edit'
end,
mousemoved = function(x,y)
    if not the_room_pos(pos) then
        return
    end

end,
wheelmoved = function(x,y)
    if not the_room_pos(pos) then
        return
    end
    if mouse.x > 1200 then
        return
    end
    --退回
    if key == 'escape' then
        room_pos = "edit"
    end
    room_pos = 'edit'
    local temp_x = mouse.x --对mousex作假 模拟非多线编辑下的输入
    mouse.x = (mouse.x-20)%300 + 900
    edit:mousereleased(mouse.x,y,button)
    mouse.x = temp_x
    room_pos = 'tracks_edit'
end,
}