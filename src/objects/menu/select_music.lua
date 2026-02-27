local select_music = object:new('select_music')
local layout    = require 'config.layouts.menu' --菜单布局
local colors    = require 'config.colors.menu' --菜单颜色
function select_music:draw()
    love.graphics.setFont(FONT.plus)

    --歌曲信息

    --背景板
    love.graphics.setColor(colors.bg)
    love.graphics.rectangle("fill", layout.musicSelect.x, layout.musicSelect.y, layout.musicSelect.w,
        layout.musicSelect.h)

    --装饰线
    love.graphics.setColor(colors.line2)
    love.graphics.rectangle("fill", layout.musicSelect.x, layout.musicSelect.y, 1, layout.musicSelect.h)
    love.graphics.setColor(colors.line3)
    love.graphics.rectangle("fill", layout.musicSelect.x - 5, layout.musicSelect.y, 3, layout.musicSelect.h)


    local middle = WINDOW.h/2
    local fontHeight = love.graphics.getFont():getHeight()

    love.graphics.setColor(colors.selectThisMusicTextBg)
    love.graphics.rectangle("fill", layout.musicSelect.x, middle - layout.musicSelect.musicH / 2, layout.musicSelect.w,
        layout.musicSelect.musicH)


    for i, v in ipairs(menu.chartTab) do
        --分割线
        love.graphics.setColor(colors.line4)
        love.graphics.rectangle("line", layout.musicSelect.x, (i - menu.selectMusicPos) * layout.musicSelect.musicH - layout.musicSelect.musicH / 2 + middle, layout.musicSelect.w,
        layout.musicSelect.musicH)
        if i == menu.selectMusicPos then
            love.graphics.setColor(colors.selectThisMusicText)
        else
            love.graphics.setColor(colors.unSelectThisMusicText)
        end


        love.graphics.printf(v, layout.musicSelect.x,
            (i - menu.selectMusicPos) * layout.musicSelect.musicH + middle - fontHeight / 2, layout.musicSelect.w,
            "center")
    end
end

function select_music:wheelmoved(x, y)
        if math.intersect(mouse.x,mouse.x,layout.musicSelect.x,layout.musicSelect.x + layout.musicSelect.w) then
        if y < 0 then
            menu.selectMusicPos = menu.selectMusicPos + 1
        else
            menu.selectMusicPos = menu.selectMusicPos - 1
        end

        menu.selectMusicPos = math.max(1, math.min(#menu.chartTab, menu.selectMusicPos))

        menu.selectChartPos = 1 --归位
        menu:select_music()
    end
end

return select_music