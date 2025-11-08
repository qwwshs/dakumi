-- 计算任意阶贝塞尔曲线的函数  
-- 计算阶乘
local function factorial(n)
    local result = 1
    for i = 2, n do
        result = result * i
    end
    return result
end

-- 计算贝塞尔曲线上的点
local function time_to_x(controlPoints, t)
    local n = #controlPoints - 1  -- 控制点的数量减1即为贝塞尔曲线的阶数
    local result = {0, 0}

    for i = 0, n do
        -- 贝塞尔基函数的计算
        local binomialCoeff = factorial(n) / (factorial(i) * factorial(n - i))
        local term = binomialCoeff * (t ^ i) * ((1 - t) ^ (n - i))

        result[1] = result[1] + term * controlPoints[i + 1][1]
        result[2] = result[2] + term * controlPoints[i + 1][2]
    end

    return {result[1],result[2]}
end

function GetBezier(startTime, endTime, startValue, endValue,nowtime,bezierTable,accuracy)
    -- 计算时间点在时间范围内的百分比
    local timePercent = (nowtime - startTime) / (endTime - startTime)
    
    -- 限制时间范围在0到1之间
    timePercent = math.max(0, math.min(1, timePercent))

    if #bezierTable % 2 ~= 0 then
        return 0
    end

    local bezier_tab = {{0,0}}
    for i=1,#bezierTable,2 do
        bezier_tab[#bezier_tab + 1] = {bezierTable[i],bezierTable[i + 1]}
    end
    bezier_tab[#bezier_tab + 1] = {1,1}
    bezierTable = bezier_tab

    --二分求解 
    local accuracy = 0.0005
    if accuracy then
        accuracy = accuracy
    end
    --精度
    local lf = 0
    local rl = 1
    local mid = 0.5

    if timePercent == 1 then
        local ky = startValue + (endValue - startValue) * time_to_x(bezierTable,timePercent)[2]
        return ky
    elseif timePercent == 0 then
        local ky = startValue + (endValue - startValue) * time_to_x(bezierTable,timePercent)[2]
        return ky
    end

    while rl - lf > accuracy do --精度之外
        --算出x和时间百分比的距离
        mid = (lf + rl) / 2
        local mid_x = time_to_x(bezierTable,mid)[1]
        if mid_x < timePercent then -- 往右偏
            lf = mid
        elseif mid_x > timePercent then --往左偏
            rl = mid
        else-- 同
            break
        end
    end
    timePercent = mid
    -- 根据插值点计算数值
    local ky = startValue + (endValue - startValue) * time_to_x(bezierTable,timePercent)[2]

    return ky
end


function low_bezier(startTime, endTime, startValue, endValue, bezierTable,nowtime)
    -- 计算时间点在时间范围内的百分比
    return GetBezier(startTime, endTime, startValue, endValue,nowtime,bezierTable,0.05)
end


function bezier(startTime, endTime, startValue, endValue, bezierTable,nowtime)
    -- 计算时间点在时间范围内的百分比
    local ky = GetBezier(startTime, endTime, startValue, endValue,nowtime,bezierTable,0.005)
    return ky
end
