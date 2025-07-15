-- Easing functions in Lua  
local easings = {
    easings_use_string = {},  --使用string索引的easing
    easings_use_number = {}  --使用number索引的easing
}
-- Linear  
function easings.easings_use_string.linear(t)  
    return t  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.linear  
-- Quadratic  
function easings.easings_use_string.in_quad(t)  
    return t * t  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_quad
function easings.easings_use_string.out_quad(t)  
    return t * (2 - t)  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_quad
function easings.easings_use_string.in_out_quad(t)  
    if t < 0.5 then  
        return 2 * t * t  
    else  
        return -1 + (4 * t) - (2 * t * t)  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_quad
-- Cubic  
function easings.easings_use_string.in_cubic(t)  
    return t * t * t  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_cubic
function easings.easings_use_string.out_cubic(t)  
    return (t - 1) * (t - 1) * (t - 1) + 1  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_cubic
function easings.easings_use_string.in_out_cubic(t)  
    if t < 0.5 then  
        return 4 * t * t * t  
    else  
        return (t - 1) * (t - 1) * (t - 1) * 4 + 1  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_cubic
-- Quartic  
function easings.easings_use_string.in_quart(t)  
    return t * t * t * t  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_quart
function easings.easings_use_string.out_quart(t)  
    return 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1)  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_quart
function easings.easings_use_string.in_out_quart(t)  
    if t < 0.5 then  
        return 8 * t * t * t * t  
    else  
        return 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1)  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_quart
-- Quintic  
function easings.easings_use_string.in_quint(t)  
    return t * t * t * t * t  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_quint
function easings.easings_use_string.out_quint(t)  
    return (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_quint
function easings.easings_use_string.in_out_quint(t)  
    if t < 0.5 then  
        return 16 * t * t * t * t * t  
    else  
        return (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) * 16 + 1  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_quint
-- Sinusoidal  
function easings.easings_use_string.in_sine(t)  
    return 1 - math.cos(t * (math.pi / 2))  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_sine
function easings.easings_use_string.out_sine(t)  
    return math.sin(t * (math.pi / 2))  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_sine
function easings.easings_use_string.in_out_sine(t)  
    return -(0.5 * (math.cos(math.pi * t) - 1))  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_sine
-- Exponential  
function easings.easings_use_string.in_expo(t)  
    return (t == 0) and 0 or math.pow(2, 10 * (t - 1))  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_expo
function easings.easings_use_string.out_expo(t)  
    return (t == 1) and 1 or (1 - math.pow(2, -10 * t))  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_expo
function easings.easings_use_string.in_out_expo(t)  
    if t == 0 then return 0 end  
    if t == 1 then return 1 end  
    if t < 0.5 then  
        return 0.5 * math.pow(2, (20 * t) - 10)  
    else  
        return -0.5 * math.pow(2, (-20 * t) + 10) + 1  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_expo
-- Circular  
function easings.easings_use_string.in_circ(t)  
    return 1 - math.sqrt(1 - (t * t))  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_circ
function easings.easings_use_string.out_circ(t)  
    return math.sqrt((2 - t) * t)  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_circ
function easings.easings_use_string.in_out_circ(t)  
    if t < 0.5 then  
        return (1 - math.sqrt(1 - (4 * t * t))) / 2  
    else  
        return (math.sqrt((-2 * t + 3)) + 1) / 2  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_circ
-- Back  
function easings.easings_use_string.in_back(t)  
    local s = 1.70158  
    return t * t * ((s + 1) * t - s)  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_back
function easings.easings_use_string.out_back(t)  
    local s = 1.70158  
    return (t - 1) * (t - 1) * ((s + 1) * (t - 1) + s) + 1  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_back
function easings.easings_use_string.in_out_back(t)  
    local s = 1.70158 * 1.525  
    if t < 0.5 then  
        return (t * t * ((s + 1) * 2 * t - s)) / 2  
    else  
        return (1 + ((t - 1) * (t - 1) * ((s + 1) * (2 * t - 2) + s))) / 2
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_back
-- Bounce  
function easings.easings_use_string.in_bounce(t)  
    return 1 - easings.easings_use_string.out_bounce(1 - t)  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_bounce
function easings.easings_use_string.out_bounce(t)  
    if t < (1 / 2.75) then  
        return 7.5625 * t * t  
    elseif t < (2 / 2.75) then  
        t = t - (1.5 / 2.75)  
        return 7.5625 * t * t + 0.75  
    elseif t < (2.5 / 2.75) then  
        t = t - (2.25 / 2.75)  
        return 7.5625 * t * t + 0.9375  
    else  
        t = t - (2.625 / 2.75)  
        return 7.5625 * t * t + 0.984375  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.out_bounce
function easings.easings_use_string.in_out_bounce(t)  
    if t < 0.5 then  
        return easings.easings_use_string.in_bounce(t * 2) * 0.5  
    else  
        return easings.easings_use_string.out_bounce(t * 2 - 1) * 0.5 + 0.5  
    end  
end  
easings.easings_use_number[#easings.easings_use_number + 1] = easings.easings_use_string.in_out_bounce
return easings