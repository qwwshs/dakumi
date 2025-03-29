
function tableToString(tbl, indent,isrecursion) -- 表转字符串
    return serpent.block(tbl)
end
function isLastCharChineseOrHalfwidth(str)  
    if str == "" then return false end  
    -- 获取字符串的长度  
    local len = #str  

    -- UTF-8字符长度可能超过1，因此需要找到最后一个字符的起始位置  
    local i = len  
    while i > 0 do  
        local byte = str:byte(i)  
        -- 检查字符的起始字节  
        if byte >= 0 and byte <= 127 then  
            -- ASCII字符，直接返回false  
            return false  
        elseif byte >= 192 and byte <= 223 then  
            -- 2字节字符  
            break  
        elseif byte >= 224 and byte <= 239 then  
            -- 3字节字符  
            break  
        elseif byte >= 240 and byte <= 247 then  
            -- 4字节字符  
            break  
        end  
        i = i - 1  
    end  

    -- 取出最后一个字符  
    local lastChar = str:sub(i)  

    -- 判断最后一个字符是否在中文汉字范围内  
    local codepoint = lastChar:byte(1)
    
    if (codepoint >= 0xe4 and codepoint <= 0xe9) or (codepoint >= 0x30 and codepoint <= 0x39) then  -- 大致范围  
        -- 精确检查  
        local utf8 = require("utf8") -- 加载utf8库  
        
        local charCode = 0x007e  
        pcall(function() charCode = utf8.codepoint(lastChar) or 0x007e end)  
        
        -- 检查是否为中文字符或全角符号  
        return (charCode >= 0x4e00 and charCode <= 0x9fa5)   -- 中文汉字范围  
            or (0x0021 <= charCode and charCode <= 0x007e) -- 半角符号范围  
    end  

    return false  
end  
