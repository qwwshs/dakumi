
local play = group:new('play')
play.now_all_track_pos = {} --现在所有轨道的属性
play.effect = {
    note_alpha = 100,
    track_alpha = 100,
    track_line_alpha = 100,
    note_rotate = 0,
    } --影响效果

function play:get_all_track_pos()
    return play.now_all_track_pos
end
function play:get_effect()
    return play.effect
end
function play:get_init_effect()
    return {note_alpha = 100,
    track_alpha = 100,
    track_line_alpha = 100,
    note_rotate = 0,
} --影响效果
end

function play:load()
    self('load')
    object_hit.load()
    object_note.load()
    object_note_edit_inplay.load(100,50,0,50,16.6)
end

function play:update(dt)
    self('update',dt)
    local now_note_alpha_ed = false --已经计算
    local now_track_alpha_ed = false --已经计算
    local now_track_line_alpha_ed = false --已经计算
    local now_note_rotate_ed = false --已经计算
    local now_scroll_ed = false --已经计算
    for i = #chart.effect,1,-1 do --倒着减小计算量
        if now_note_alpha_ed and now_track_alpha_ed and now_track_line_alpha_ed and now_note_rotate_ed and now_scroll_ed then --计算完成
            break
        end
        local v = chart.effect[i]
        if v then
            if (beat:get(v.beat) <= beat.nowbeat and beat:get(v.beat2) > beat.nowbeat) or (beat:get(v.beat2) <= beat.nowbeat) then
                if v.type == "note_alpha" and (not now_note_alpha_ed) then
                    play.effect.note_alpha = bezier(beat:get(v.beat),beat:get(v.beat2),v.from,v.to,v.trans,beat.nowbeat)
                    now_note_alpha_ed = true
                elseif v.type == "track_alpha" and (not now_track_alpha_ed) then
                    play.effect.track_alpha = bezier(beat:get(v.beat),beat:get(v.beat2),v.from,v.to,v.trans,beat.nowbeat)
                    now_track_alpha_ed = true
                elseif v.type == "track_line_alpha" and (not now_track_alpha_ed) then
                    play.effect.track_line_alpha = bezier(beat:get(v.beat),beat:get(v.beat2),v.from,v.to,v.trans,beat.nowbeat)
                    now_track_line_alpha_ed = true
                elseif v.type == "note_rotate" and (not now_track_alpha_ed) then
                    play.effect.note_rotate = bezier(beat:get(v.beat),beat:get(v.beat2),v.from,v.to,v.trans,beat.nowbeat)
                    now_note_rotate_ed = true
                elseif v.type == "scroll" and (not now_track_alpha_ed) then
                    play.effect.scroll = bezier(beat:get(v.beat),beat:get(v.beat2),v.from,v.to,v.trans,beat.nowbeat)
                    now_scroll_ed = true
                end
            end
        end
    end


    local all_track = track_get_all_track()
    for i = 1,#all_track do
        local x,w = event:get(all_track[i],beat.nowbeat)
        play.now_all_track_pos[all_track[i]] = {x = x,w = w}
    end

    object_hit.update(dt)
end

function play:draw()
    self('draw')
    object_demo_mode.draw()
    love.graphics.setColor(1,1,1,settings.bg_alpha / 100)

    if bg then -- 背景存在就显示
        --图像范围限制函数
        local function myStencilFunction()
            love.graphics.rectangle("fill",info.play.play_alea.x,info.play.play_alea.y,info.play.play_alea.x+info.play.play_alea.w,info.play.play_alea.h)
        end

        love.graphics.stencil(myStencilFunction, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        local bg_width, bg_height = bg:getDimensions( ) -- 得到宽高
        local bg_scale_h = 1 / bg_height * WINDOW.h 
        local bg_scale_w = 1 / bg_height * WINDOW.h / (WINDOW.scale / WINDOW.scale)
        if demo then
            bg_scale_h = 1 / bg_height * WINDOW.h 
            bg_scale_w = 1 / bg_height * WINDOW.h / (WINDOW.scale / WINDOW.scale)   / (1 / (info.play.play_alea.w/WINDOW.w))
        end

        love.graphics.draw(bg,450 - (bg_width *bg_scale_w) / 2,0,0,bg_scale_w,bg_scale_h) --居中显示
        
        love.graphics.setStencilTest()
    end
    
    object_demo_inplay.draw()

    if demo then
        return
    end
    
    love.graphics.setColor(1,1,1,1) --总note event 数
    local str = 'note: '..#chart.note..'  event: '..#chart.event
    love.graphics.printf(str,info.play.play_alea.x,settings.judge_line_y + 60,info.play.play_alea.w,"center")
    object_demo_now_x_pos.draw()

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
            local y = beat:toY(chart.event[i].beat)
            local y2 = beat:toY(chart.event[i].beat2)
            local event_h2 = y - y2 - event_h * 2
            if not (y2 > WINDOW.h or y < 0) then
            -- beizer曲线
                for k = 1,10 do
                    local nowx = low_bezier(1,10,to_play_track_original_x(chart.event[i].from),to_play_track_original_x(chart.event[i].to),chart.event[i].trans,k) --减去50是为了使50居中
                    local nowy = y + (y2 - y) * k / 10
                    love.graphics.rectangle("fill",nowx,nowy -  (y2 - y)/10,5, (y2 - y)/10) --减去一个 (y2 - y)/10是为了与头对齐
                end
            elseif  y2 >WINDOW.h then
                break
            end
        end
    end
    
    
    object_denom_play.draw()
    object_note_play_in_edit.draw()

    --栅栏绘制
    love.graphics.setColor(1,1,1,0.5)
    for i = 1, track.fence do
        love.graphics.rectangle("fill",(info.play.play_alea.w+info.play.play_alea.x) / track.fence * i,100,2,info.play.play_alea.w)
    end
    if 900 / track.fence * track_get_near_fence() < 900 then
        love.graphics.setColor(0,1,1,0.7)
    love.graphics.rectangle("fill",900 / track.fence * track_get_near_fence(),100,2,900)
    end

    --note放置相关
    object_note.draw()
    --复制粘贴相关
    object_copy.draw()
end

function play:keypressed(key)
    if mouse.x > 1200 then  --限制范围
        return
    end
    self('keypressed',key)
    object_demo_mode.keyboard(key)
    object_alt_note_event.keyboard(key)
    object_note.keyboard(key)
    object_note_edit_inplay.keyboard(key)
    object_event.keyboard(key)

    object_copy.keyboard(key)
    object_redo.keyboard(key)

end
function play:wheelmoved(x,y)
    if mouse.x > 1200 then  --限制范围
        return
    end
    self('wheelmoved',x,y)

    object_copy.wheelmoved(x,y)

        
end

function play:mousepressed( x, y, button, istouch, presses )
    self('mousepressed', x, y, button, istouch, presses)

    object_event.mousepressed( x, y, button, istouch, presses )
    object_note.mousepressed( x, y, button, istouch, presses )
    object_copy.mousepressed(x, y, button, istouch, presses)
    object_note_edit_inplay.mousepressed(x, y, button, istouch, presses)
end

function play:mousereleased( x, y, button, istouch, presses )
    self('mousereleased', x, y, button, istouch, presses)

    object_copy.mousereleased(x, y, button, istouch, presses)
end

return play