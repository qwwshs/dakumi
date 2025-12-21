--- 分数相加函数
-- 将两个分数相加，并返回约分后的结果
-- @tparam number num1 第一个分数的分子
-- @tparam number denom1 第一个分数的分母
-- @tparam number num2 第二个分数的分子
-- @tparam number denom2 第二个分数的分母
-- @treturn number 相加后结果的分子
-- @treturn number 相加后结果的分母
-- @usage local num, denom = addFractions(1, 2, 1, 3) -- 返回 5, 6
function addFractions(num1, denom1, num2, denom2)
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

--- 判断两个数值区间是否有交集
-- 将输入的两个点规范化为区间（确保起点小于终点），然后检查是否有交集
-- @tparam number a1 第一个区间的第一个端点
-- @tparam number a2 第一个区间的第二个端点
-- @tparam number b1 第二个区间的第一个端点
-- @tparam number b2 第二个区间的第二个端点
-- @treturn boolean 如果有交集返回true，否则返回false
-- @usage local intersect = math.intersect(1, 5, 3, 7) -- 返回 true
-- @usage local intersect = math.intersect(1, 2, 3, 4) -- 返回 false
function math.intersect(a1, a2, b1, b2)
    -- 规范化区间，确保起点小于终点
    local a_start, a_end = math.min(a1, a2), math.max(a1, a2)
    local b_start, b_end = math.min(b1, b2), math.max(b1, b2)

    -- 检查两个区间是否有交集
    return a_end >= b_start and b_end >= a_start
end

--- 按指定精度舍入数值
-- 将数值乘以精度因子，取整后再除以精度因子，实现舍入效果
-- @tparam number x 要舍入的数值（默认为0）
-- @tparam number a 精度因子，即舍入到1/a的倍数（默认为1，即整数舍入）
-- @treturn number 舍入后的结果
-- @usage math.roundToPrecision(3.14159, 100) -- 返回 3.14
-- @usage math.roundToPrecision(3.14159) -- 返回 3
function math.roundToPrecision(x, a)
    x = x or 0
    a = a or 1

    return math.floor(x * a) / a
end
