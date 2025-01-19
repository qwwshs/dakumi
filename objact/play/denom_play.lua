
--denom播放
objact_denom_play = {
    draw = function()
            local beat_y = 0
            local fontHeight = love.graphics.getFont():getHeight() --字体高度

            for i = 0, beat.allbeat * denom.denom do
                local isbeat = i/denom.denom
                beat_y = beat_to_y(isbeat)
                if beat_y > 800 then
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
                    love.graphics.setColor(RGBA_hexToRGBA("#FFFFFFFF"))
                    love.graphics.rectangle("fill",0,beat_y,1175,1) -- 节拍线
                    love.graphics.printf(math.floor(isbeat),1180,beat_y-fontHeight/2, 35, "left")
                goto next

                ::denom::
                    local isdenom =i - math.floor(i / denom.denom) * denom.denom
                    local r,g,b = RGBA_hexToRGB("#646464")

                    if denom.denom % 3 == 0 and denom.denom % 4 ~= 0 then
                        r,g,b = RGBA_hexToRGB("#00FF37")
                    end

                    if  isdenom % 2 == 0 and denom.denom % 2 == 0 then
                        r,g,b = RGBA_hexToRGB("#CD37FF")
                    end

                    if isdenom  == denom.denom / 2 then --中线
                        r,g,b = RGBA_hexToRGB("#7FFFF4")
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