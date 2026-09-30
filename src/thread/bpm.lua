local sound, output, cancel = ...
local ok, result = pcall(function()
    require('love.sound')
    local analyzer = require('src.services.bpmAnalyzer')
    return analyzer.measure(sound, function()
        if cancel:peek() then error('cancelled') end
    end)
end)
if not cancel:peek() then
    output:push(ok and {result = result} or {error = tostring(result)})
end
