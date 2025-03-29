local r = 20 --鼠标半径
local side = 20 --鼠标半径
animation_new("mouse_r",r,r,20,0.2,{0,0,1,1})
animation_new("mouse_side",side,side,20,0.2,{0,0,1,1})
objact_mouse = { -- 鼠标
    load = function()
        --鼠标不可见
        if settings.mouse == 0 then
            love.mouse.setVisible( false )
        end
    end,
    update = function(dt)
        if demo_mode == true  then
            love.mouse.setVisible( false )
        else
            love.mouse.setVisible( true )
        end
    end,  
    draw = function()
        if not demo_mode and settings.mouse == 0 and room_pos ~= "start" then
            love.graphics.setColor(1,1,1,1)
            love.graphics.circle("line",mouse.x,mouse.y,animation.mouse_r,animation.mouse_side)
        end
    end,
    mousepressed = function( x, y, button, istouch, presses )
        animation_new("mouse_r",20,10,0,0.1,{1,1,1,1})
        animation_new("mouse_side",side,4,0,0.1,{1,1,1,1})
        if settings.mouse == 1 then
            love.mouse.setVisible( true )
        elseif settings.mouse == 0 then
            love.mouse.setVisible( false )
        end
        if demo_mode  then
            love.mouse.setVisible( false )
        end
        
    end,
    mousereleased = function( x, y, button, istouch, presses )
        animation_new("mouse_r",10,20,0,0.1,{1,1,1,1})
        animation_new("mouse_side",4,side,0,0.1,{1,1,1,1})
    end,
}
