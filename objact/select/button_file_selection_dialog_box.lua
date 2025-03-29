
-- 按钮位置和大小的变量
local x = 0  -- 按钮的 X 坐标
local y = 0  -- 按钮的 Y 坐标
local w = 0  -- 按钮的宽度
local h = 0  -- 按钮的高度
local r = 0  -- 按钮的旋转角度

local fileselect = ffi.load("fileselect")

-- 定义函数原型
ffi.cdef[[
    const char* OpenFileDialog(const char* filter);
    const char* SaveFileDialog(const char* filter);
]]
    -- ANSI 到 UTF-8 的转换函数
local function ansi_to_utf8(ansi_str)
    -- 常量定义
    local CP_ACP = 0        -- ANSI代码页
    local CP_UTF8 = 65001   -- UTF-8代码页
    
    -- 首先将 ANSI 转换为 UTF-16
    local wlen = ffi.C.MultiByteToWideChar(CP_ACP, 0, ansi_str, -1, nil, 0)
    if wlen <= 0 then return ansi_str end
    
    local wstr = ffi.new("wchar_t[?]", wlen)
    ffi.C.MultiByteToWideChar(CP_ACP, 0, ansi_str, -1, wstr, wlen)
    
    -- 然后将 UTF-16 转换为 UTF-8
    local utf8len = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wstr, -1, nil, 0, nil, nil)
    if utf8len <= 0 then return ansi_str end
    
    local utf8str = ffi.new("char[?]", utf8len)
    ffi.C.WideCharToMultiByte(CP_UTF8, 0, wstr, -1, utf8str, utf8len, nil, nil)
    
    return ffi.string(utf8str)
end
-- 绘制按钮的函数
local function draw_this_button()
    -- 使用 ui_style 绘制按钮，并获取对应语言的文本
    ui_style:button(x,y,w,h,objact_language.get_string_in_languages("file_select"))
end

-- 判断是否应该显示按钮的函数
local function will_draw()
    -- 只在选择界面显示按钮
    return the_room_pos('select')
end

-- 按钮点击时执行的函数
local function will_do()
    -- 定义文件过滤器
    local filter = 
    "Audio Files (*.ogg;*.mp3;*.wav)\0*.ogg;*.mp3;*.wav\0Chart Files (*.d3;*.mc)\0*.d3;*.mc\0Image Files (*.jpg;*.png)\0*.jpg;*.png\0Package Files (*.dkz)\0*.dkz\0All Files (*.*)\0*.*\0";
    local selectedFile = fileselect.OpenFileDialog(filter)
    if selectedFile ~= nil then
        local filepath = ffi.string(selectedFile)
        -- 将 ANSI 编码转换为 UTF-8
        filepath = ansi_to_utf8(filepath)
        local lastSlashIndex = string.find(filepath, "\\[^\\]*$") --找到最后一个斜杠的位置
        local file_name = string.sub(filepath, lastSlashIndex + 1) --从最后一个斜杠之后开始截取字符串
        local file = love.filesystem.newFile("temporary/"..file_name)
        file:open("w")
        local data = nativefs.read(filepath)
        file:write(data)
        file:close()
        room_select.filedropped(file) --导入文件
    end
end

objact_file_selection_dialog_box = {
    load = function(x1,y1,r1,w1,h1)
        x = x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        button_new("file_select",will_do,x,y,w,h,draw_this_button,{will_draw = will_draw})
    end,
    draw = function()
    end,
    mousepressed = function( x1, y1, button, istouch, presses )
    end,
}