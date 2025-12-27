
--denom播放
denomPlay = object:new('denomPlay')

function denomPlay:draw()
local beat_y = 0
    local fontHeight = love.graphics.getFont():getHeight() --字体高度
    local print_w = 35
    for i = 0, beat.allbeat * denom.denom do
        local isbeat = i/denom.denom
        beat_y = beat:toY(isbeat)
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
            setColor(play.colors.beat) -- 节拍线颜色
            love.graphics.rectangle("fill",play.layout.left_boundary,beat_y,play.layout.right_boundary,1) -- 节拍线
            love.graphics.printf(math.floor(isbeat),play.layout.right_boundary  + 5,beat_y-fontHeight/2, print_w, "left")
        goto next

        ::denom::
           local isdenom =i - math.roundToPrecision(i,denom.denom)
            local r,g,b = play.colors.denom[1],play.colors.denom[2],play.colors.denom[3]
            if denom.denom % 3 == 0 and denom.denom % 4 ~= 0 then
                  r,g,b = play.colors.denom3and4[1],play.colors.denom3and4[2],play.colors.denom3and4[3]
            end
            if  isdenom % 2 == 0 and denom.denom % 2 == 0 then
                r,g,b = play.colors.denom2[1],play.colors.denom2[2],play.colors.denom2[3]
            end
            if isdenom  == denom.denom / 2 then --中线
                r,g,b = play.colors.denomMid[1],play.colors.denomMid[2],play.colors.denomMid[3]
            end
            setColor(r,g,b,settings.denom_alpha/100)
            love.graphics.rectangle("fill",play.layout.left_boundary,beat_y,play.layout.right_boundary,1)
        goto next

        ::next::
        end
        --鼠标指针所在位置所对应的beat渲染
        if play:mouseInPlay() then--在play里面
            --根据距离反推出beat
            local mouse_nearby_y = beat:toY(beat:get(beat:toNearby(beat:yToBeat(mouse.y))))
            setColor(play.colors.mouseBeat)
            love.graphics.rectangle("fill",play.layout.right_boundary,mouse_nearby_y,play.layout.left_boundary-play.layout.right_boundary,2)
        end 
end
return denomPlay