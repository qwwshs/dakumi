--显示现在鼠标在的play的x位置
local demoNowX = object:new("demoNowX")
function demoNowX:draw()
    if not play:mouseInPlay() then
        return
    end
    love.graphics.setColor(1,1,1)
    local now_near_x = fTrack:track_get_near_fence_x()
    local now_x = math.roundToPrecision(fTrack:to_chart_track(mouse.x), 100)
    love.graphics.printf("x:"..now_x.."\nnear x:"..now_near_x,mouse.x, settings.judge_line_y+35,114514,"left")
end

return demoNowX