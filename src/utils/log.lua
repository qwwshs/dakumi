function log(...) 
    local file = io.open(PATH.usersPath.log..os.date("%Y %m %d")..".log", "a") 
    file:write("["..os.date("%H:%M:%S").."]:"..serpent.block({...}).."\n") 
    file:close() 
end
