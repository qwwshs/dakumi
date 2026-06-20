local track          = object:new('track')
track.fence          = 10
track.track          = 4
track.type           = 'custom'
track.text           = 'track'
track.text2          = 'fence'
track.layout         = require 'config.layouts.editTool'
track.useToTrack     = { value = "4" }
track.useToFence     = { value = "10" }
track.usemouse_track = false
track.usemouse_fence = false
function track:keypressed(key)
    if input('trackUp') then
        self:to('track', self.track + 1)
    elseif input('trackDown') then
        self:to('track', math.max(self.track - 1, 1))
    end
end

function track:wheelmovedInEditTool(x, y)
    if self.usemouse_track then
        if y > 0 then
            self:to('track', self.track + 1)
        elseif y < 0 then
            self:to('track', math.max(self.track - 1, 1))
        end
    end
    if self.usemouse_fence then
        if y > 0 then
            self:to('fence', self.fence + 1)
        elseif y < 0 then
            self:to('fence', math.max(self.fence - 1, 0))
        end
    end
end

function track:Nui() --渲染
    track.usemouse_track = false
    track.usemouse_fence = false
    if Nui:groupBegin(self.text, 'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text))
        if Nui:button("", isImage.up) then
            track.track = track.track + 1
            self.useToTrack.value = tostring(track.track)
        end
        local active,changed = Nui:edit('field', self.useToTrack)
        if active == 'active' then
            mouse.cursor = 'sizens'
            if iskeyboard['ctrl'] then
                self.usemouse_track = true
            end
        end
        if Nui:button("", isImage.down) then
            track.track = math.max(track.track - 1, 1)
            self.useToTrack.value = tostring(track.track)
        end

        Nui:groupEnd()
    end
    if Nui:groupBegin(self.text2, 'border') then
        Nui:layoutRow('dynamic', self.layout.uiH / 2, 2)
        Nui:label(i18n:get(self.text2))
        if Nui:button("", isImage.up) then
            track.fence = track.fence + 1
            self.useToFence.value = tostring(track.fence)
        end
        local active,changed = Nui:edit('field', self.useToFence)
        if active == 'active' then
            mouse.cursor = 'sizens'
            if iskeyboard['ctrl'] then
                self.usemouse_fence = true
            end
        end
        if Nui:button("", isImage.down) then
            track.fence = math.max(track.fence - 1, 0)
            self.useToFence.value = tostring(track.fence)
        end

        Nui:groupEnd()
    end
end

function track:update(dt)
    if tonumber(self.useToTrack.value) then
        self.track = math.max(math.floor(tonumber(self.useToTrack.value)), 1)
    end
    if tonumber(self.useToFence.value) then
        self.fence = math.max(math.floor(tonumber(self.useToFence.value)), 0)
    end
end

function track:to(ty, v)
    if ty == 'track' then
        self.track = v
        self.useToTrack.value = tostring(v)
    elseif ty == 'fence' then
        self.track = v
        self.useToFence.value = tostring(v)
    end
end

return track
