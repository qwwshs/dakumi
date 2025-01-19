local ui_add = love.graphics.newImage("asset/ui_add.png")
local ui_sub = love.graphics.newImage("asset/ui_sub.png")
local ui_break = love.graphics.newImage("asset/ui_break.png")
local ui_up = love.graphics.newImage("asset/ui_up.png")
local ui_down = love.graphics.newImage("asset/ui_down.png")
local ui_save = love.graphics.newImage("asset/ui_save.png")
local ui_play = love.graphics.newImage("asset/ui_play.png")
local ui_pause = love.graphics.newImage("asset/ui_pause.png")
local ui_close = love.graphics.newImage("asset/ui_close.png")
local ui_github = love.graphics.newImage("asset/github-mark.png")
--常用ui
ui = {}
function ui:draw(x,y,w,h,ui)
    if type (ui) == "string" then
        return function()
            ui_style:button(x,y,w,h,ui)
        end
    else
        
        return function()
            ui_style:button(x,y,w,h,nil)
            local style_width, style_height = ui:getDimensions( ) -- 得到宽高
            local style_scale_h = 1 / style_height *h
            local style_scale_w = 1 / style_width * w
            love.graphics.draw(ui,x,y,0,style_scale_w,style_scale_h)
        end

    end
end
function ui:add(x,y,w,h) return ui:draw(x,y,w,h,ui_add) end
function ui:sub(x,y,w,h) return ui:draw(x,y,w,h,ui_sub) end
function ui:isbreak(x,y,w,h) return ui:draw(x,y,w,h,ui_break) end --关键词 所以加了个is
function ui:up(x,y,w,h) return ui:draw(x,y,w,h,ui_up) end
function ui:down(x,y,w,h) return ui:draw(x,y,w,h,ui_down) end
function ui:close(x,y,w,h) return ui:draw(x,y,w,h,ui_close) end
function ui:save(x,y,w,h) return ui:draw(x,y,w,h,ui_save) end
function ui:play(x,y,w,h) return ui:draw(x,y,w,h,ui_play) end
function ui:pause(x,y,w,h) return ui:draw(x,y,w,h,ui_pause) end
function ui:github(x,y,w,h) return ui:draw(x,y,w,h,ui_github) end
