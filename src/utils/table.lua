function table.eq(table1, table2)  --判断两个表是否内容相等
    -- 如果两个表是同一个引用，直接返回 true  
    if table1 == table2 then  
        return true  
    end  

    -- 如果它们不是表，直接返回 false  
    if type(table1) ~= "table" or type(table2) ~= "table" then  
        return false  
    end  

    -- 比较表的键值  
    local keys1 = {}  
    local keys2 = {}  

    for key in pairs(table1) do  
        keys1[key] = true  
    end  

    for key in pairs(table2) do  
        keys2[key] = true  
    end  

    -- 检查键的数量是否相等  
    for key in pairs(keys1) do  
        if not keys2[key] then  
            return false  
        end  
    end  

    for key in pairs(keys2) do  
        if not keys1[key] then  
            return false  
        end  
    end  

    -- 递归检查每个键的值  
    for key, value in pairs(table1) do  
        if not table.eq(value, table2[key]) then  
            return false  
        end  
    end  

    return true  
end

function table.copy(original)  
    local copy = {}  
    for key, value in pairs(original) do  
        -- 如果值是表，递归复制  
        if type(value) == "table" then  
            copy[key] = table.copy(value)  
        else  
            copy[key] = value  
        end  
    end  
    return copy  
end  

function table.find(array, element)  --元素查询
    for _, value in ipairs(array) do  
        if value == element then  
            return true  
        end  
    end  
    return false  
end  

function table.fill(tbl, metatable,func) --补充元素
    func = func or false --是否补充函数
    for key, value in pairs(metatable) do
        if type(value) == "table" then
            tbl[key] = tbl[key] or {}
            table.fill(tbl[key], value)
        elseif type(value) == "function" then
            if func then
                tbl[key] = tbl[key] or value
            end
        else
            tbl[key] = tbl[key] or value
        end
    end
end

