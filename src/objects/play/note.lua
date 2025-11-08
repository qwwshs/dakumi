local noteEdit = object:new('noteEdit') --避免重名
noteEdit.layout = require 'config.layouts.play'
function noteEdit:keypressed(key)
    if not ((math.intersect(mouse.x,mouse.x,self.layout.edit.x,self.layout.edit.x + self.layout.edit.interval) or math.intersect(mouse.x,mouse.x,self.layout.demo.x,self.layout.demo.x + self.layout.demo.w)) and mouse.y >= self.layout.y) then 
        return
    end
    if key == "q" then -- note
        note:place("note",mouse.y)
        messageBox:add("note place")
        sidebar.displayed_content = 'nil'
    elseif key == "w" then --wipe
        note:place("wipe",mouse.y)
        messageBox:add("wipe place")
        sidebar.displayed_content = 'nil'
    elseif key == "e" then --hold
        hold_place = not hold_place
        note:place("hold",mouse.y)
        messageBox:add("hold place")
        sidebar.displayed_content = 'nil'
    elseif key == "d" then --delete
        note:delete(mouse.y)
        messageBox:add("note delete")
        sidebar.displayed_content = 'nil'
    end
end

function noteEdit:mousepressed(x,y,button)
    if math.intersect(mouse.x,mouse.x,self.layout.edit.x,self.layout.edit.x + self.layout.edit.interval) and love.mouse.isDown(1) then -- 选择note 在edit区域
        local pos = note:click(mouse.y)
        if pos then
            sidebar:to('note',pos)
        else
            sidebar.displayed_content = 'nil'
        end
        messageBox:add("note click")
    end
    if math.intersect(mouse.x,mouse.x,self.layout.demo.x,self.layout.demo.x + self.layout.demo.w) and love.mouse.isDown(1)  then -- 选择note 在demo区域
        local local_track = {}
        for i = 1,#chart.event do --点击轨道进入轨道的编辑事件
            if not table.find(local_track,chart.event[i].track) then --不存在 记录
                local track_x,track_w = event:get(chart.event[i].track,beat.nowbeat)
                track_x,track_w = fTrack:to_play_track(track_x,track_w)
                if x >= track_x and x <= track_w + track_x then
                    local_track[#local_track + 1] = chart.event[i].track
                end
            end
            if beat:get(chart.event[i].beat) > beat.nowbeat then
                break
            end
        end
        for i = 1, #local_track do
            if local_track[i] == track.track then --这么写的意义是为了多轨道重叠的时候能顺利的选到全部轨道
                if i + 1 <= #local_track then
                    track:to(local_track[i + 1])
                    break
                else
                    track:to(local_track[1])
                    break
                end
            elseif not table.find(local_track,track.track) then --没点到当前轨道
                track:to(local_track[i])
                break
            end
        end
    end
end

return noteEdit