function addFractions(num1, denom1, num2, denom2)  --分数相加
    -- 计算新分子和新分母  
    local newNumerator = num1 * denom2 + num2 * denom1  
    local newDenominator = denom1 * denom2  

    -- 约分  
    local function gcd(a, b)  
        while b ~= 0 do  
            a, b = b, a % b  
        end  
        return a  
    end  
    
    local divisor = gcd(math.abs(newNumerator), math.abs(newDenominator))  
    newNumerator = newNumerator / divisor  
    newDenominator = newDenominator / divisor  

    return newNumerator, newDenominator  
end  

function intervals_intersect(a1, a2, b1, b2) -- 判断两个区间是否有交集
    -- 规范化区间，确保起点小于终点
    local a_start, a_end = math.min(a1, a2), math.max(a1, a2)
    local b_start, b_end = math.min(b1, b2), math.max(b1, b2)

    -- 检查两个区间是否有交集
    return a_end >= b_start and b_end >= a_start
end
