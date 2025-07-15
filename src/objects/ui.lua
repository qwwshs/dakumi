isImage = {
    add = love.graphics.newImage("assets/img/add.png"),
    sub = love.graphics.newImage("assets/img/sub.png"),
    isbreak = love.graphics.newImage("assets/img/break.png"),
    up = love.graphics.newImage("assets/img/up.png"),
    down = love.graphics.newImage("assets/img/down.png"),
    close = love.graphics.newImage("assets/img/close.png"),
    save = love.graphics.newImage("assets/img/save.png"),
    play = love.graphics.newImage("assets/img/play.png"),
    pause = love.graphics.newImage("assets/img/pause.png"),
    github = love.graphics.newImage("assets/img/github-mark-white.png"),
    dakumi = love.graphics.newImage("assets/img/icon.png"),
    note = love.graphics.newImage("assets/img/note.png"),
    wipe = love.graphics.newImage("assets/img/wipe.png"),
    hold_head = love.graphics.newImage("assets/img/hold_head.png"),
    hold_body = love.graphics.newImage("assets/img/hold_body.png"),
    hold_tail = love.graphics.newImage("assets/img/hold_tail.png"),
    note2 = love.graphics.newImage("assets/img/note2.png"),
    wipe2 = love.graphics.newImage("assets/img/wipe2.png"),
    hold_head2 = love.graphics.newImage("assets/img/hold_head2.png"),
    hold_body2 = love.graphics.newImage("assets/img/hold_body2.png"),
    hold_tail2 = love.graphics.newImage("assets/img/hold_tail2.png"),
    hit = love.graphics.newImage("assets/img/hit.png"),
    hit_light = love.graphics.newImage("assets/img/hit_light.png"),
}


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
function ui:add(x,y,w,h) return ui:draw(x,y,w,h,isImage.add) end
function ui:sub(x,y,w,h) return ui:draw(x,y,w,h,isImage.sub) end
function ui:isbreak(x,y,w,h) return ui:draw(x,y,w,h,isImage.isbreak) end --关键词 所以加了个is
function ui:up(x,y,w,h) return ui:draw(x,y,w,h,isImage.up) end
function ui:down(x,y,w,h) return ui:draw(x,y,w,h,isImage.down) end
function ui:close(x,y,w,h) return ui:draw(x,y,w,h,isImage.close) end
function ui:save(x,y,w,h) return ui:draw(x,y,w,h,isImage.save) end
function ui:play(x,y,w,h) return ui:draw(x,y,w,h,isImage.play) end
function ui:pause(x,y,w,h) return ui:draw(x,y,w,h,isImage.pause) end
function ui:github(x,y,w,h) return ui:draw(x,y,w,h,isImage.github) end
function ui:dakumi(x,y,w,h) return ui:draw(x,y,w,h,isImage.dakumi) end

