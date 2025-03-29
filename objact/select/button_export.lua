
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local function will_draw()
    return the_room_pos('select')
end
local function draw_this_button()
    ui_style:button(x,y,w,h,objact_language.get_string_in_languages("export"))
end
local function will_do()
    if not chart_tab[select_music_pos] then
        return
    end
    --创造json文件 给游玩读的
    for i = 1,#chart_info.chart_name do
        love.filesystem.newFile(string.sub(chart_info.chart_name[i].path,1,#chart_info.chart_name[i].path - 2)..'json','w')
        love.filesystem.write(string.sub(chart_info.chart_name[i].path,1,#chart_info.chart_name[i].path - 2)..'json',dkjson.encode(
            loadstring('return '..love.filesystem.read(chart_info.chart_name[i].path))()
        ))
    end

    nativefs.mount(love.filesystem.getSourceBaseDirectory( ))
    nativefs.createDirectory("export") --防止有人运行一半删文件夹

    local file_tab = love.filesystem.getDirectoryItems("chart/"..chart_tab[select_music_pos]) --导出
    for i,v in ipairs(file_tab) do
        local info = love.filesystem.read("chart/"..chart_tab[select_music_pos].."/"..v)
        local file = io.open("export/"..v, "wb")
        file:write(info)
        file:close()
    end
    local err = os.execute("cd export && 7z a "..chart_tab[select_music_pos]..".zip"..[[ *]])  --导出 调用7zip
    objact_message_box.message("export")
    if err ~= 0 then
        log("export error:"..err,chart_tab[select_music_pos]..".zip", [[ *]])
    end
    
    for i,v in ipairs(file_tab) do
        nativefs.remove("export/"..v)  --删除
    end
    nativefs.unmount()
end

objact_export = { --分度改变用的
load = function(x1,y1,r1,w1,h1)
    x= x1 --初始化
    y = y1
    w = w1
    h = h1
    r = r1
    button_new("export",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
end,
draw = function()

end,
mousepressed = function( x1, y1, button, istouch, presses )

end,
}