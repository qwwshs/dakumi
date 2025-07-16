--[[子房间 就写成对象了
local x = 0
local y = 0
local w = 0
local h = 0
local r = 0
local input_type = false --输入状态
local type = "track"
local track_sidebar_pos_y = 0 --位移
local tracks_that_have_already_been_written = {} --已经编写了的轨道
orbital_search_range = {x_from = 0,x_to = 0,w_from = 0,w_to = 0} --轨道搜索范围
local function will_draw()
    return sidebar:room_type(type) and the_room_pos({"edit",'tracks_edit'})
end
object_track_sidebar = {

    load = function(x1,y1,r1,w1,h1)
        x= x1 --初始化
        y = y1
        w = w1
        h = h1
        r = r1
        track_sidebar_pos_y = 0

        if not sidebar:room_type(type) then
            return
        else
        end

        tracks_that_have_already_been_written = track_get_all_track()
        input_box_new("orbital_search_range_x_form","orbital_search_range.x_from",x+300,y+10,50,20,{type = "number",will_draw = will_draw})
        input_box_new("orbital_search_range_x_to","orbital_search_range.x_to",x+300,y+30,50,20,{type = "number",will_draw = will_draw})
        input_box_new("orbital_search_range_w_form","orbital_search_range.w_from",x+300,y+50,50,20,{type = "number",will_draw = will_draw})
        input_box_new("orbital_search_range_w_to","orbital_search_range.w_to",x+300,y+70,50,20,{type = "number",will_draw = will_draw})
    end,
    draw = function()
        if not sidebar:room_type(type) then
            return
        end
        local temp_i = 1 --充当i 因为下面的i不能用于计算y
        love.graphics.setColor(1,1,1,1)
        local x_is_not_performed = orbital_search_range.x_from == 0 and orbital_search_range.x_to == 0 -- 不进行x检测
        local w_is_not_performed  = orbital_search_range.w_from == 0 and orbital_search_range.w_to == 0 -- 不进行w检测
        for i = 1,#tracks_that_have_already_been_written do --渲染
            local temp_x,temp_w =  event_get(tracks_that_have_already_been_written[i],beat.nowbeat)
            local x_in_scope = not(temp_x < orbital_search_range.x_from or temp_x > orbital_search_range.x_to) --x在范围内
            local w_in_scope = not(temp_w < orbital_search_range.w_from or temp_w > orbital_search_range.w_to) --w在范围内
            if (x_in_scope or x_is_not_performed) and (w_in_scope or w_is_not_performed) then
                temp_i = temp_i + 1
                love.graphics.setFont(FONT.plus)
                love.graphics.print(tracks_that_have_already_been_written[i],x,y+20 + track_sidebar_pos_y + temp_i*40) 
                love.graphics.setFont(FONT.normal)
            
                love.graphics.print(math.floor(temp_x*100)/100,x+80,y+20 + track_sidebar_pos_y + temp_i*40) 
                love.graphics.print(math.floor(temp_w*100)/100,x+140,y+20 + track_sidebar_pos_y + temp_i*40) 
            end
        end


        love.graphics.setColor(0,0,0,1)
        love.graphics.rectangle('fill',x,0,600,y+45)
        love.graphics.setColor(1,1,1,1)
        love.graphics.print(i18n:get('track'),x,y+20) 
        love.graphics.print('x',x+80,y+20) 
        love.graphics.print('w',x+140,y+20) 

        love.graphics.print('x'..i18n:get('sift'),x+250,y+10) 
        love.graphics.print('w'..i18n:get('sift'),x+250,y+50) 

    end,
    mousepressed = function( x1, y1, button, istouch, presses )
        if not sidebar:room_type(type) then
            return
        end
    end,
    keypressed = function(key)
        if not sidebar:room_type(type) then
            return
        end

        
    end,
    wheelmoved = function(x,y)
        if not sidebar:room_type(type) then
            return
        end
        local scroll = 40
        if y < 0 then
            scroll = - scroll
        end

        track_sidebar_pos_y = track_sidebar_pos_y + scroll
    end
}
]]
--track界面
local Gtrack = group:new('track')
Gtrack.type = "track"
Gtrack.range = {x = {from = {value = '0'},to = {value = '0'}},w = {from = {value = '0'},to = {value = '0'}}} --轨道搜索范围
Gtrack.layout = require 'config.layouts.sidebar'.track

function Gtrack:Nui()
    local allTrack = track_get_all_track()
    local allTrackPos = play:get_all_track_pos()
    local xf = tonumber(self.range.x.from.value)
    local xt = tonumber(self.range.x.to.value)
    local wf = tonumber(self.range.w.from.value)
    local wt = tonumber(self.range.w.to.value)

    for i,v in ipairs(allTrack) do
        local x = allTrackPos[v].x
        local w = allTrackPos[v].w

        if xf and xt and wf and wt then
            if not (math.intersect(xf,xt,x,x) and math.intersect(wf,wt,w,w)) then
                goto next
            end
        end

        if Nui:button('track:'..v.." x:"..x..' w:'..w) then
            track:to(v)
        end
        ::next::
    end
end

function Gtrack:NuiNext() --用于书写筛选条件
    local layout = self.layout
    if Nui:windowBegin(i18n:get('range'), layout.x, layout.y, layout.w, layout.h,'border','movable','title') then

        Nui:layoutRow('dynamic', layout.uiH, layout.cols)

        Nui:label('x')
        Nui:edit('field', self.range.x.from)
        Nui:edit('field', self.range.x.to)

        Nui:label('w')
        Nui:edit('field', self.range.w.from)
        Nui:edit('field', self.range.w.to)
        Nui:windowEnd()
    end
end

return Gtrack