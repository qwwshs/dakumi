local demoH = table.copy(require 'src.objects.play.hit') --用copy是为了防止因为require缓存引起的问题
local layout = require 'config.layouts.demo'
demoH:Setup(layout.x,layout.y,layout.w,layout.h)
return demoH