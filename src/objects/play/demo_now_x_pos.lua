--显示现在鼠标在的play的x位置
object_demo_now_x_pos = {
    draw = function()
        if mouse.x > 900 then
            return
        end
        love.graphics.setColor(1,1,1,1)
        local now_near_x = track_get_near_fence_x()
        local now_x = math.floor(to_chart_track(mouse.x)*100) / 100
        love.graphics.printf("x:"..now_x.."\nnear x:"..now_near_x,mouse.x, settings.judge_line_y+35,1000,"left")
    end
    
}