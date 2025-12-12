local demoP = table.copy(require 'src.objects.play.demoPlay') --用copy是为了防止因为require缓存引起的问题
local layout = require 'config.layouts.demo'
demoP:Setup(layout.x,layout.y,layout.w,layout.h)
return demoP