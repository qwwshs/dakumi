local demo = group:new('demo') --演示界面
demo.layout = require 'config.layouts.demo'
demo.open = false              --演示界面开关
demo:addObject(require 'src.objects.demo.demoPlay')
demo:addObject(require 'src.objects.demo.hit')
function demo:keypressed(key)
    if key == 'tab' then
        demo.open = not demo.open
    end
    self('keypressed', key)
end

function demo:draw()
    if not self.open then
        return
    end
    love.graphics.setColor(1, 1, 1, settings.bg_alpha / 100)

    if bg then -- 背景存在就显示
        --图像范围限制函数
        local function myStencilFunction()
            love.graphics.rectangle("fill", self.layout.x, self.layout.y, self.layout.x +
                self.layout.w, self.layout.h)
        end

        love.graphics.stencil(myStencilFunction, "replace", 1)
        love.graphics.setStencilTest("greater", 0)

        local bg_width, bg_height = bg:getDimensions() -- 得到宽高
        local bg_scale_h = 1 / bg_height * WINDOW.h
        local bg_scale_w = 1 / bg_height * WINDOW.h
        if demo.open then
            bg_scale_h = 1 / bg_height * WINDOW.h
            bg_scale_w = 1 / bg_height * WINDOW.h / (1 / (self.layout.w / WINDOW.w))
        end

        love.graphics.draw(bg, self.layout.x + self.layout.w / 2 - (bg_width * bg_scale_w) / 2, 0, 0, bg_scale_w, bg_scale_h) --居中显示

        love.graphics.setStencilTest()
    end
    self('draw')
end

function demo:update(dt)
    if not self.open then
        return
    end
    self('update', dt)
end

return demo
