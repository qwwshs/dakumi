
--denom播放
object_denom_play = {
    draw = function()
            local beat_y = 0
            local fontHeight = love.graphics.getFont():getHeight() --字体高度

            for i = 0, beat.allbeat * denom.denom do
                local isbeat = i/denom.denom
                beat_y = beat_to_y(isbeat)
                if beat_y > WINDOW.h then
                    goto next
                elseif beat_y < 0 then
                    break
                end

                if math.floor(isbeat) == isbeat then
                    goto beat 
                else
                    goto denom
                end
                ::beat::
                    love.graphics.setColor(1,1,1,1)
                    love.graphics.rectangle("fill",0,beat_y,1175,1) -- 节拍线
                    love.graphics.printf(math.floor(isbeat),1180,beat_y-fontHeight/2, 35, "left")
                goto next

                ::denom::
                    local isdenom =i - math.floor(i / denom.denom) * denom.denom
                    local r,g,b = 0, 0.4, 0.4

                    if denom.denom % 3 == 0 and denom.denom % 4 ~= 0 then
                        r,g,b = 0, 1, 0.2
                    end

                    if  isdenom % 2 == 0 and denom.denom % 2 == 0 then
                        r,g,b = 0.8, 0.2, 1
                    end

                    if isdenom  == denom.denom / 2 then --中线
                        r,g,b = 0.5, 1, 0.95
                    end
                    love.graphics.setColor(r,g,b,settings.denom_alpha/100)
                    love.graphics.rectangle("fill",0,beat_y,1175,1)
                goto next

                ::next::
            end

            --鼠标指针所在位置所对应的beat渲染
            if mouse.x < 1200 then--在play里面
                --根据距离反推出beat
                local mouse_beat = thebeat(to_nearby_Beat(y_to_beat(mouse.y)))
                local mouse_y = beat_to_y(mouse_beat)
                love.graphics.setColor(1,1,1,0.5)
                love.graphics.rectangle("fill",0,mouse_y,1175,2)
            end
    
    end
}