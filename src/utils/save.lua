
function save(tab,name) --谱与设置保存 
    if name == "chart.json" then --特殊保存
        if not menu.chartInfo.chart_name[menu.selectChartPos].path then return end
        
        pcall(function()nativefs.mount(PATH.base) 
            nativefs.write( menu.chartInfo.chart_name[menu.selectChartPos].path ,dkjson.encode(tab , {indent = true}) ) 
            nativefs.unmount()
        end)
        
        return
    end
    local file = io.open(name, "w")
    if file then
        if type(tab) == "table" then
            file:write(tableToString(tab))
        elseif type(tab) == "string" then
            file:write(tab)
        end
        file:close()
    end
end