
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
note_is_fake = 0
local function will_draw()
    return the_room_pos('edit') and not demo_mode
end

objact_note_fake = { --默认放下为fake
    load = function(x1,y1,r1,w1,h1)
        x = x1
        y = y1
        r = r1
        w = w1
        h = h1
        switch_new('note_fake','note_is_fake',x,y,w,h,1,{will_draw = will_draw})
    end,
    draw = function()
        if demo_mode then return end
        if note_is_fake == 1 then
            love.graphics.print(objact_language.get_string_in_languages('note_type')..':'..objact_language.get_string_in_languages('false'),x-70,y)
        else
            love.graphics.print(objact_language.get_string_in_languages('note_type')..':'..objact_language.get_string_in_languages('true'),x-70,y)
        end
    end
}