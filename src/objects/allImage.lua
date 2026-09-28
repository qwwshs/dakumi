isImage = {
    add = love.graphics.newImage("assets/img/add.png"),
    sub = love.graphics.newImage("assets/img/sub.png"),
    isbreak = love.graphics.newImage("assets/img/break.png"),
    up = love.graphics.newImage("assets/img/up.png"),
    down = love.graphics.newImage("assets/img/down.png"),
    close = love.graphics.newImage("assets/img/close.png"),
    save = love.graphics.newImage("assets/img/save.png"),
    play = love.graphics.newImage("assets/img/play.png"),
    pause = love.graphics.newImage("assets/img/pause.png"),
    github = love.graphics.newImage("assets/img/github-mark-white.png"),
    dakumi = love.graphics.newImage("assets/img/icon.png"),
    dakumi_32 = love.graphics.newImage("assets/img/icon_32.png"),
    dakumi_pixel = love.graphics.newImage("assets/img/dakumi-pixel.png"),
    note = love.graphics.newImage("assets/img/note.png"),
    wipe = love.graphics.newImage("assets/img/wipe.png"),
    hold_head = love.graphics.newImage("assets/img/hold_head.png"),
    hold_body = love.graphics.newImage("assets/img/hold_body.png"),
    hold_tail = love.graphics.newImage("assets/img/hold_tail.png"),
    note2 = love.graphics.newImage("assets/img/note2.png"),
    wipe2 = love.graphics.newImage("assets/img/wipe2.png"),
    hold_head2 = love.graphics.newImage("assets/img/hold_head2.png"),
    hold_body2 = love.graphics.newImage("assets/img/hold_body2.png"),
    hold_tail2 = love.graphics.newImage("assets/img/hold_tail2.png"),
    hit = love.graphics.newImage("assets/img/hit.png"),
    hit_light = love.graphics.newImage("assets/img/hit_light.png"),
}

-- UI图标缓存：浅色主题将白色图标转换为深色，保留原始透明度和抗锯齿。
local uiIconPaths = {
    add = "assets/img/add.png", sub = "assets/img/sub.png",
    isbreak = "assets/img/break.png", up = "assets/img/up.png",
    down = "assets/img/down.png", close = "assets/img/close.png",
    save = "assets/img/save.png", play = "assets/img/play.png",
    pause = "assets/img/pause.png", github = "assets/img/github-mark-white.png",
}
local uiIconCache = { dark = {}, light = {} }

local function makeUiIcon(path, theme)
    local data = love.image.newImageData(path)
    if theme == 'light' then
        data:mapPixel(function(x, y, r, g, b, a)
            -- 灰度抗锯齿仍由 alpha 保留，颜色统一为深灰。
            return 0.16, 0.17, 0.19, a
        end)
    end
    return love.graphics.newImage(data)
end

function isImage:setTheme(theme)
    theme = theme == 'light' and 'light' or 'dark'
    local previousSave = self.save
    for name, path in pairs(uiIconPaths) do
        if not uiIconCache[theme][name] then
            uiIconCache[theme][name] = makeUiIcon(path, theme)
        end
        self[name] = uiIconCache[theme][name]
    end

    -- 这些对象在模块加载时保存了图像引用，需要一并刷新。
    if menuUI and menuUI.fileTool then
        menuUI.fileTool[1].img = self.dakumi
        menuUI.fileTool[2].img = self.github
    end
    if editTool and editTool.objects then
        for _, object in ipairs(editTool.objects) do
            if object.img == previousSave then object.img = self.save end
        end
    end
    if musicPlay then
        musicPlay.img = music_play and self.pause or self.play
        musicPlay.img2 = music_play and self.play or self.pause
    end
end
