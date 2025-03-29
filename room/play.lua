
local pos = "edit"
local now_all_track_pos = {} --现在所有轨道的属性
local effect = {note_alpha = 100,
                track_alpha = 100,
                track_line_alpha = 100,
                note_rotate = 0,
            } --影响效果
function get_all_track_pos()
    return now_all_track_pos
end
function get_effect()
    return effect
end
function get_init_effect()
    return {note_alpha = 100,
    track_alpha = 100,
    track_line_alpha = 100,
    note_rotate = 0,
} --影响效果
end

room_play = { -- 最基础的 播放页面
load = function()
    objact_hit.load()
    objact_note.load(400,50,0,50,16.6)
    objact_note_edit_inplay.load(100,50,0,50,16.6)
end,
update = function(dt)
    if not the_room_pos(pos) then
        return
    end
    local now_note_alpha_ed = false --已经计算
    local now_track_alpha_ed = false --已经计算
    local now_track_line_alpha_ed = false --已经计算
    local now_note_rotate_ed = false --已经计算
    local now_scroll_ed = false --已经计算
    for i =  #chart.effect,1,-1 do --倒着减小计算量
        if now_note_alpha_ed and now_track_alpha_ed and now_track_line_alpha_ed and now_note_rotate_ed and now_scroll_ed then --计算完成
            break
        end
        if chart.effect[i] then
            if (thebeat(chart.effect[i].beat) <= beat.nowbeat and thebeat(chart.effect[i].beat2) > beat.nowbeat) or (thebeat(chart.effect[i].beat2) <= beat.nowbeat) then
                if chart.effect[i].type == "note_alpha" and (not now_note_alpha_ed) then
                    effect.note_alpha = bezier(thebeat(chart.effect[i].beat),thebeat(chart.effect[i].beat2),chart.effect[i].from,chart.effect[i].to,chart.effect[i].trans,beat.nowbeat)
                    now_note_alpha_ed = true
                elseif chart.effect[i].type == "track_alpha" and (not now_track_alpha_ed) then
                    effect.track_alpha = bezier(thebeat(chart.effect[i].beat),thebeat(chart.effect[i].beat2),chart.effect[i].from,chart.effect[i].to,chart.effect[i].trans,beat.nowbeat)
                    now_track_alpha_ed = true
                elseif chart.effect[i].type == "track_line_alpha" and (not now_track_alpha_ed) then
                    effect.track_line_alpha = bezier(thebeat(chart.effect[i].beat),thebeat(chart.effect[i].beat2),chart.effect[i].from,chart.effect[i].to,chart.effect[i].trans,beat.nowbeat)
                    now_track_line_alpha_ed = true
                elseif chart.effect[i].type == "note_rotate" and (not now_track_alpha_ed) then
                    effect.note_rotate = bezier(thebeat(chart.effect[i].beat),thebeat(chart.effect[i].beat2),chart.effect[i].from,chart.effect[i].to,chart.effect[i].trans,beat.nowbeat)
                    now_note_rotate_ed = true
                elseif chart.effect[i].type == "scroll" and (not now_track_alpha_ed) then
                    effect.scroll = bezier(thebeat(chart.effect[i].beat),thebeat(chart.effect[i].beat2),chart.effect[i].from,chart.effect[i].to,chart.effect[i].trans,beat.nowbeat)
                    now_scroll_ed = true
                end
            end
        end
    end


    local all_track = track_get_all_track()
    for i = 1,#all_track do
        local x,w = event_get(all_track[i],beat.nowbeat)
        now_all_track_pos[all_track[i]] = {x = x,w = w}
    end

    objact_hit.update(dt)
end,

draw = function()
    if not the_room_pos(pos) then
        return
    end
    objact_demo_mode.draw()
    love.graphics.setColor(1,1,1,settings.bg_alpha / 100)

    if bg then -- 背景存在就显示
        --图像范围限制函数
        local function myStencilFunction()
            love.graphics.rectangle("fill",0,0,900,800)
        end

        love.graphics.stencil(myStencilFunction, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        local bg_width, bg_height = bg:getDimensions( ) -- 得到宽高
            bg_scale_h = 1 / bg_height * 800 
            bg_scale_w = 1 / bg_height * 800 / (window_w_scale / window_h_scale)
        if demo_mode then
            bg_scale_h = 1 / bg_height * 800 
            bg_scale_w = 1 / bg_height * 800 / (window_w_scale / window_h_scale)   / (1 / (900/1600))
        end

        love.graphics.draw(bg,450 - (bg_width *bg_scale_w) / 2,0,0,bg_scale_w,bg_scale_h) --居中显示
        
        love.graphics.setStencilTest()
    end
    
    objact_demo_inplay.draw()

    if demo_mode then
        return
    end
    
    love.graphics.setColor(1,1,1,1) --总note event 数
    local str = 'note: '..#chart.note..'  event: '..#chart.event
    love.graphics.print(str,450 - #str * 4 /2,settings.judge_line_y + 60)
    objact_demo_now_x_pos.draw()

    --event渲染
    local event_h = settings.note_height
    local event_w = 75
    for i=#chart.event,1,-1 do
        if chart.event[i].track == track.track then
            if chart.event[i].type == "w" then
                love.graphics.setColor(1,1,1,1)
            elseif chart.event[i].type == "x" then
                love.graphics.setColor(0,1,1,1)
            end
            local y = beat_to_y(chart.event[i].beat)
            local y2 = beat_to_y(chart.event[i].beat2)
            local event_h2 = y - y2 - event_h * 2
            if not (y2 > 800 or y < 0) then
            -- beizer曲线
                for k = 1,10 do
                    local nowx = low_bezier(1,10,to_play_track_original_x(chart.event[i].from),to_play_track_original_x(chart.event[i].to),chart.event[i].trans,k) --减去50是为了使50居中
                    local nowy = y + (y2 - y) * k / 10
                    love.graphics.rectangle("fill",nowx,nowy -  (y2 - y)/10,5, (y2 - y)/10) --减去一个 (y2 - y)/10是为了与头对齐
                end
            elseif  y2 >800 then
                break
            end
        end
    end
    
    
    objact_denom_play.draw()
    objact_note_play_in_edit.draw()

    --栅栏绘制
    love.graphics.setColor(1,1,1,0.5)
    for i = 1, track.fence do
        love.graphics.rectangle("fill",900 / track.fence * i,100,2,900)
    end
    if 900 / track.fence * track_get_near_fence() < 900 then
        love.graphics.setColor(0,1,1,0.7)
    love.graphics.rectangle("fill",900 / track.fence * track_get_near_fence(),100,2,900)
    end

    --note放置相关
    objact_note.draw()
    --复制粘贴相关
    objact_copy.draw()
end,
keypressed = function(key)
    if not the_room_pos(pos) then
        return
    end
    if mouse.x > 1200 then  --限制范围
        return
    end
    objact_demo_mode.keyboard(key)
    objact_alt_note_event.keyboard(key)
    objact_note.keyboard(key)
    objact_note_edit_inplay.keyboard(key)
    objact_event.keyboard(key)

    objact_copy.keyboard(key)
    objact_redo.keyboard(key)

end,

wheelmoved = function(x,y)
    if mouse.x > 1200 then  --限制范围
        return
    end

    objact_denom.wheelmoved(x,y)
    objact_copy.wheelmoved(x,y)

        
end,
mousepressed = function( x, y, button, istouch, presses )
    if not the_room_pos(pos) then
        return
    end
    objact_event.mousepressed( x, y, button, istouch, presses )
    objact_note.mousepressed( x, y, button, istouch, presses )
    objact_copy.mousepressed(x, y, button, istouch, presses)
    objact_note_edit_inplay.mousepressed(x, y, button, istouch, presses)
end,
textinput = function(input)
    if not the_room_pos(pos) then
        return
    end
end,
mousereleased = function( x, y, button, istouch, presses )
    if not the_room_pos(pos) then
        return
    end
    objact_copy.mousereleased(x, y, button, istouch, presses)
end,
keyreleased = function(key)
    if not the_room_pos(pos) then
        return
    end
end,
quit = function()
    if not the_room_pos(pos) then
        return
    end
end
}