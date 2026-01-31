-- 获取文件后缀的函数
function getFileExtension(filename)
    -- 找到最后一个点号的位置
    local dotPos = filename:match(".*()%.") or 0
    -- 提取后缀（小写形式）
    local extension = filename:sub(dotPos + 1):lower()
    return extension
end