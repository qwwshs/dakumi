local select_chart = object:new('select_chart')
local layout       = require 'config.layouts.menu' --菜单布局
local colors       = require 'config.colors.menu' --菜单颜色
function select_chart:draw()
    love.graphics.setFont(FONT.normal)
    local fontHeight = love.graphics.getFont():getHeight()

    --谱面信息
    love.graphics.setColor(colors.chartInofoBg)
    love.graphics.rectangle("fill", layout.chartSelect.x, layout.chartSelect.y - layout.chartSelect.chartH / 2,
        layout.chartSelect.w, layout.chartSelect.h)

    for i = 1, #menu.chartInfo.chart_name do
        if i == menu.selectChartPos then
            love.graphics.setColor(colors.selectThischartText)
        else
            love.graphics.setColor(colors.unSelectThischartText)
        end
        if not menu.chartInfo.chart_name[i].is_true_chart then love.graphics.setColor(colors.errorChart) end
        love.graphics.printf('chart:' .. menu.chartInfo.chart_name[i].name, layout.chartSelect.x,
            (menu.selectChartPos - i) * layout.chartSelect.chartH + layout.chartSelect.y - fontHeight / 2,
            layout.chartSelect.w, "center")
    end


    love.graphics.setFont(FONT.normal)
end

function select_chart:wheelmoved(x, y)
    if math.intersect(mouse.x, mouse.x, layout.chartSelect.x, layout.chartSelect.x + layout.chartSelect.w) then
        if y < 0 then
            menu.selectChartPos = menu.selectChartPos + 1
        else
            menu.selectChartPos = menu.selectChartPos - 1
        end

        menu.selectChartPos = math.max(1, math.min(#menu.chartInfo.chart_name, menu.selectChartPos))

        if menu.chartInfo.chart_name[menu.selectChartPos] then
            menu.path = menu.chartInfo.chart_name[menu.selectChartPos].path
            local info = love.filesystem.read(menu.path)
            local is_true_chart = menu:check('chart', info)
            if is_true_chart then
                info = dkjson.decode(info)
            else
                log("chart file error")
                menu.chartInfo.chart_name[menu.selectChartPos].is_true_chart = false
                info = {}
            end
            setmetatable(info, meta_chart) --防谱报废
            table.fill(info, meta_chart.__index)
            chart = table.copy(info)       --读取谱面
        end
    end
end

return select_chart
