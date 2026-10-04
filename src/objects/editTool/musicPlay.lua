
local buttonMusicPlay = object:new('music_play')
local AudioService = require("src.services.audioService")
buttonMusicPlay.type = 'button'
buttonMusicPlay.text = ''
buttonMusicPlay.text2 = ''
buttonMusicPlay.img = isImage.play
buttonMusicPlay.img2 = isImage.pause

function buttonMusicPlay:click()
    AudioService:toggle()
    self.img = AudioService:isPlaying() and isImage.pause or isImage.play
    self.img2 = AudioService:isPlaying() and isImage.play or isImage.pause
end

function buttonMusicPlay:keypressed(key)
    if input('play') then
        self:click()
    end
end

function buttonMusicPlay:update(dt)
    self.img = AudioService:isPlaying() and isImage.pause or isImage.play
    self.img2 = AudioService:isPlaying() and isImage.play or isImage.pause
end

return buttonMusicPlay
