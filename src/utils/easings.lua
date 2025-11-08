-- Easing functions in Lua  
local easings = {
}
-- Linear  
function easings.linear(t)  
    return t  
end  
easings[#easings + 1] = easings.linear  
-- Quadratic  
function easings.in_quad(t)  
    return t * t  
end  
easings[#easings + 1] = easings.in_quad
function easings.out_quad(t)  
    return t * (2 - t)  
end  
easings[#easings + 1] = easings.out_quad
function easings.in_out_quad(t)  
    if t < 0.5 then  
        return 2 * t * t  
    else  
        return -1 + (4 * t) - (2 * t * t)  
    end  
end  
easings[#easings + 1] = easings.in_out_quad
-- Cubic  
function easings.in_cubic(t)  
    return t * t * t  
end  
easings[#easings + 1] = easings.in_cubic
function easings.out_cubic(t)  
    return (t - 1) * (t - 1) * (t - 1) + 1  
end  
easings[#easings + 1] = easings.out_cubic
function easings.in_out_cubic(t)  
    if t < 0.5 then  
        return 4 * t * t * t  
    else  
        return (t - 1) * (t - 1) * (t - 1) * 4 + 1  
    end  
end  
easings[#easings + 1] = easings.in_out_cubic
-- Quartic  
function easings.in_quart(t)  
    return t * t * t * t  
end  
easings[#easings + 1] = easings.in_quart
function easings.out_quart(t)  
    return 1 - (t - 1) * (t - 1) * (t - 1) * (t - 1)  
end  
easings[#easings + 1] = easings.out_quart
function easings.in_out_quart(t)  
    if t < 0.5 then  
        return 8 * t * t * t * t  
    else  
        return 1 - 8 * (t - 1) * (t - 1) * (t - 1) * (t - 1)  
    end  
end  
easings[#easings + 1] = easings.in_out_quart
-- Quintic  
function easings.in_quint(t)  
    return t * t * t * t * t  
end  
easings[#easings + 1] = easings.in_quint
function easings.out_quint(t)  
    return (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) + 1  
end  
easings[#easings + 1] = easings.out_quint
function easings.in_out_quint(t)  
    if t < 0.5 then  
        return 16 * t * t * t * t * t  
    else  
        return (t - 1) * (t - 1) * (t - 1) * (t - 1) * (t - 1) * 16 + 1  
    end  
end  
easings[#easings + 1] = easings.in_out_quint
-- Sinusoidal  
function easings.in_sine(t)  
    return 1 - math.cos(t * (math.pi / 2))  
end  
easings[#easings + 1] = easings.in_sine
function easings.out_sine(t)  
    return math.sin(t * (math.pi / 2))  
end  
easings[#easings + 1] = easings.out_sine
function easings.in_out_sine(t)  
    return -(0.5 * (math.cos(math.pi * t) - 1))  
end  
easings[#easings + 1] = easings.in_out_sine
-- Exponential  
function easings.in_expo(t)  
    return (t == 0) and 0 or math.pow(2, 10 * (t - 1))  
end  
easings[#easings + 1] = easings.in_expo
function easings.out_expo(t)  
    return (t == 1) and 1 or (1 - math.pow(2, -10 * t))  
end  
easings[#easings + 1] = easings.out_expo
function easings.in_out_expo(t)  
    if t == 0 then return 0 end  
    if t == 1 then return 1 end  
    if t < 0.5 then  
        return 0.5 * math.pow(2, (20 * t) - 10)  
    else  
        return -0.5 * math.pow(2, (-20 * t) + 10) + 1  
    end  
end  
easings[#easings + 1] = easings.in_out_expo
-- Circular  
function easings.in_circ(t)  
    return 1 - math.sqrt(1 - (t * t))  
end  
easings[#easings + 1] = easings.in_circ
function easings.out_circ(t)  
    return math.sqrt((2 - t) * t)  
end  
easings[#easings + 1] = easings.out_circ
function easings.in_out_circ(t)  
    if t < 0.5 then  
        return (1 - math.sqrt(1 - (4 * t * t))) / 2  
    else  
        return (math.sqrt((-2 * t + 3)) + 1) / 2  
    end  
end  
easings[#easings + 1] = easings.in_out_circ
-- Back  
function easings.in_back(t)  
    local s = 1.70158  
    return t * t * ((s + 1) * t - s)  
end  
easings[#easings + 1] = easings.in_back
function easings.out_back(t)  
    local s = 1.70158  
    return (t - 1) * (t - 1) * ((s + 1) * (t - 1) + s) + 1  
end  
easings[#easings + 1] = easings.out_back
function easings.in_out_back(t)  
    local s = 1.70158 * 1.525  
    if t < 0.5 then  
        return (t * t * ((s + 1) * 2 * t - s)) / 2  
    else  
        return (1 + ((t - 1) * (t - 1) * ((s + 1) * (2 * t - 2) + s))) / 2
    end  
end  
easings[#easings + 1] = easings.in_out_back
-- Bounce  
function easings.in_bounce(t)  
    return 1 - easings.out_bounce(1 - t)  
end  
easings[#easings + 1] = easings.in_bounce
function easings.out_bounce(t)  
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
easings[#easings + 1] = easings.out_bounce
function easings.in_out_bounce(t)  
    if t < 0.5 then  
        return easings.in_bounce(t * 2) * 0.5  
    else  
        return easings.out_bounce(t * 2 - 1) * 0.5 + 0.5  
    end  
end  
easings[#easings + 1] = easings.in_out_bounce
return easings