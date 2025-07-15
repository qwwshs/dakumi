local track = object:new('track')
track.fence = 10
track.track = 4
track.type = 'custom'
track.text = 'track'
track.text2 = 'fence'
track.layout = require 'config.layouts.editTool'
track.useToTrack = {value = "4"}
track.useToFence = {value = "10"}

function track:keypressed(key)
    if mouse.x >= 1200 then return end

    if key == "right" then
        track.track = track.track + 1
    elseif key == "left" then
        track.track = math.max(track.track-1,1)
    end
end

function track:Nui() --渲染
    if Nui:groupBegin(self.text,'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text))
        if Nui:button("",isImage.up) then
            track.track = track.track + 1
            self.useToTrack.value = tostring(track.track)
        end
        Nui:edit('field', self.useToTrack)

        if Nui:button("",isImage.down) then
            track.track = math.max(track.track-1,1)
            self.useToTrack.value = tostring(track.track)
        end

        Nui:groupEnd()
    end
    if Nui:groupBegin(self.text2,'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text2))
        if Nui:button("",isImage.up) then
            track.fence = track.fence + 0.1
            self.useToFence.value = tostring(track.fence)
        end
        Nui:edit('field', self.useToFence)

        if Nui:button("",isImage.down) then
            track.fence = math.max(track.fence - 0.1,0.1)
            self.useToFence.value = tostring(track.fence)
        end
        
        Nui:groupEnd()
    end
end

function track:update(dt)
    if tonumber(self.useToTrack.value) then
        self.track = tonumber(self.useToTrack.value)
    end
    if tonumber(self.useToFence.value) then
        self.fence = tonumber(self.useToFence.value)
    end
end

function track:to(tk)
    self.track = tk
    self.useToTrack.value = tostring(tk)
end

return track

