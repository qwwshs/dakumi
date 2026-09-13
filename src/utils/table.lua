--[[
    模块名: table 扩展
    描述: 为 Lua table 库添加常用工具函数
    作者: qwwshs
]]

--- 判断两个表是否内容相等（递归比较）
-- @tparam table table1 第一个表
-- @tparam table table2 第二个表
-- @treturn boolean 是否相等
function table.eq(table1, table2)
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

--- 深拷贝表（递归复制所有嵌套表）
-- @tparam table original 原始表
-- @treturn table 深拷贝后的新表
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

--- 在表中查找元素
-- @tparam table array 要搜索的表
-- @tparam any element 要查找的元素
-- @treturn number|false 找到时的下标（不是 boolean true，别写 `== true`），未找到返回 false
function table.find(array, element)
    for _, value in pairs(array) do  
        if value == element then  
            return _  
        end  
    end  
    return false  
end  

--- 用默认值填充表中缺失的字段
-- @tparam table tbl 目标表
-- @tparam table metatable 包含默认值的模板表
-- @tparam boolean func 是否填充函数类型字段（默认 false）
function table.fill(tbl, metatable, func)
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

