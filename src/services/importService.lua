-- 导入插件统一入口：审核、转换、可选资源应用，以及菜单导入文件保存。
local manager=require('src.utils.plugin')
local Chart=require('src.services.chartService')
local Audio=require('src.services.audioService')
local json=require('src.utils.dkjson')
local Import={}
local function is(value,kind)
    local ok,result=pcall(function() return value:typeOf(kind) end)
    return ok and result==true
end
local function checked(ok,err) if not ok then error(err or 'import failed') end return ok end
function Import:request(input,origin)
    if type(input)=='table' and type(input.data)=='string' then
        return {path=input.path or '',name=input.name or (input.path or ''):match('[^/\\]+$') or '',
            data=input.data,origin=origin or input.origin or 'internal'}
    end
    if type(input)=='string' then
        local data,err=nativefs.read(input)
        if not data then return nil,err end
        return {path=input,name=input:match('[^/\\]+$') or input,data=data,origin=origin or 'internal'}
    end
    local ok,request=pcall(function()
        checked(input:open('r'))
        local data,err=input:read()
        input:close()
        checked(data,err)
        local path=input:getFilename()
        return {path=path,name=path:match('[^/\\]+$') or path,data=data,origin=origin or 'internal'}
    end)
    if not ok then return nil,tostring(request) end
    return request
end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function validBeat(t)
    return type(t)=='table' and finite(t[1]) and finite(t[2]) and finite(t[3]) and t[3]>0
end
local function validEntities(list,kind)
    for _, raw in pairs(list or {}) do
        if type(raw)~='table' then return false end
        local data=raw._data or raw
        if not validBeat(data.beat or {0,0,1}) then return false end
        if (kind~='note' or data.type=='hold') and not validBeat(data.beat2 or {0,0,1}) then return false end
        if data.track~=nil and (not finite(data.track) or data.track<1 or data.track%1~=0) then return false end
        if kind~='note' then
            if not finite(data.from or 0) or not finite(data.to or 0) then return false end
            local trans=data.trans
            if trans~=nil then
                if type(trans)~='table' then return false end
                if trans.type=='bezier' then
                    if type(trans.trans)~='table' or #trans.trans~=4 then return false end
                    for _, n in ipairs(trans.trans) do if not finite(n) then return false end end
                end
            end
        end
    end
    return true
end
function Import:validate(result)
    if type(result)~='table' then return false,'import must return a table' end
    if result.chart==nil and result.audio==nil and result.background==nil then
        return false,'import returned no chart, audio or background'
    end
    if result.chart~=nil then
        if type(result.chart)~='table' then return false,'chart must be a Dakumi chart table' end
        for _, key in ipairs({'note','event','bpm_list','effect','event_groups','preference','info','track'}) do
            if result.chart[key]~=nil and type(result.chart[key])~='table' then return false,'invalid chart.'..key end
        end
        if not validEntities(result.chart.note,'note') or not validEntities(result.chart.event,'event')
            or not validEntities(result.chart.effect,'effect') then return false,'invalid chart entity data' end
        for _, group in pairs(result.chart.event_groups or {}) do
            if type(group)~='table' or type(group.event)~='table' or not validEntities(group.event,'event') then
                return false,'invalid event group'
            end
        end
        if result.chart.offset~=nil and not finite(result.chart.offset) then return false,'invalid chart offset' end
        if result.chart.bpm_list~=nil then
            if #result.chart.bpm_list==0 then return false,'empty BPM list' end
            for _, bpm in pairs(result.chart.bpm_list) do
                if type(bpm)~='table' or not validBeat(bpm.beat) or not finite(bpm.bpm) or bpm.bpm<=0 then
                    return false,'invalid BPM entry'
                end
            end
        end
        local ok,encoded=pcall(json.encode,result.chart)
        if not ok or not encoded then return false,'chart cannot be serialized' end
    end
    if result.audio~=nil and not is(result.audio,'SoundData') and not is(result.audio,'Source') then
        if type(result.audio)~='table' or not is(result.audio.source,'Source')
            or (result.audio.data~=nil and not is(result.audio.data,'SoundData')) then
            return false,'audio must be SoundData, Source or {source=Source, data=SoundData}'
        end
    end
    if result.background~=nil and not is(result.background,'Image') and not is(result.background,'ImageData') then
        return false,'background must be Image or ImageData'
    end
    return true
end
function Import:convert(input,origin)
    local request,err=self:request(input,origin)
    if not request then return nil,err end
    request.extension=(request.name:match('%.([^%.]+)$') or ''):lower()
    local result,reason,name=manager:dispatchImport(request)
    if not result then return nil,reason end
    local valid,message=self:validate(result)
    if not valid then return nil,(name or 'import')..': '..message end
    return result,nil,request
end
local function audioParts(audio)
    if is(audio,'SoundData') then return nil,audio end
    if is(audio,'Source') then return audio,nil end
    if type(audio)=='table' then return audio.source,audio.data end
end
function Import:apply(result,options)
    options=options or {}
    local valid,err=self:validate(result)
    if not valid then return false,err end
    local ok,message=pcall(function()
        -- 先构造媒体，失败时不替换当前资源；没有返回的资源不修改。
        local source,data=audioParts(result.audio)
        if data and not source then source=love.audio.newSource(data,'static') end
        if source then source:getDuration('seconds') end -- 已释放的 Source 在改谱面前报错。
        local image=result.background
        if is(image,'ImageData') then image=love.graphics.newImage(image) end
        if image then image:getDimensions() end
        if result.chart then
            checked(Chart:setChart(result.chart)~=false)
            Chart:update()
            checked(Chart:load()~=false)
        end
        if source then Audio:setSource(source,nil,options.preview); Audio:setSoundData(data) end
        if image then
            bg=image
            if menu and menu.chartInfo then menu.chartInfo.bg=image end
        end
    end)
    return ok,not ok and tostring(message) or nil
end
-- 内部导入也必须经过插件审核。成功返回插件结果，失败返回 nil 和原因。
function Import:import(input)
    local result,err=self:convert(input,'internal')
    if not result then return nil,err end
    local ok,reason=self:apply(result)
    if not ok then return nil,reason end
    return result
end
local function u32(n)
    return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256)
end
local function u16(n) return string.char(n%256,math.floor(n/256)%256) end
local function wav(data)
    local channels,rate=data:getChannelCount(),data:getSampleRate()
    local pcm
    if data:getBitDepth()==16 then pcm=data:getString()
    else
        local bytes={}
        for frame=0,data:getSampleCount()-1 do
            for channel=1,channels do
                local sample=math.max(-32768,math.min(32767,math.floor(data:getSample(frame,channel)*32767)))
                bytes[#bytes+1]=u16(sample%65536)
            end
        end
        pcm=table.concat(bytes)
    end
    assert(#pcm<4294967259,'audio is too large for WAV')
    return 'RIFF'..u32(36+#pcm)..'WAVEfmt '..u32(16)..u16(1)..u16(channels)
        ..u32(rate)..u32(rate*channels*2)..u16(channels*2)..u16(16)..'data'..u32(#pcm)..pcm
end
local function imageData(image)
    if is(image,'ImageData') then return image end
    local canvas=love.graphics.newCanvas(image:getWidth(),image:getHeight())
    love.graphics.push('all')
    local ok,err=pcall(function()
        love.graphics.setCanvas(canvas); love.graphics.clear(0,0,0,0)
        love.graphics.origin(); love.graphics.setShader(); love.graphics.setScissor()
        love.graphics.setColor(1,1,1,1); love.graphics.setBlendMode('replace','premultiplied'); love.graphics.draw(image)
    end)
    love.graphics.pop()
    if not ok then error(err) end
    return canvas:newImageData()
end
function Import:saveToMenu(result,request,selectedFolder)
    local valid,err=self:validate(result)
    if not valid then return nil,err end
    local attempted={}
    local ok,folder,paths=pcall(function()
        local stem=(request.name or 'import'):gsub('%.[^.]+$',''):gsub('[%c<>:"/\\|?*]','_'):gsub('[ .]+$','')
        if stem=='' then stem='import' end
        local files={}
        if result.chart then files[#files+1]={kind='chart',name=stem..'.json',data=checked(json.encode(result.chart))} end
        if result.audio then
            local _,data=audioParts(result.audio)
            assert(data,'menu import needs decoded SoundData to save the audio')
            files[#files+1]={kind='audio',name=stem..'.wav',data=wav(data)}
        end
        if result.background then
            files[#files+1]={kind='background',name=stem..'.png',data=imageData(result.background):encode('png'):getString()}
        end
        local root=PATH.usersPath.chart
        local target=selectedFolder
        if result.audio or not target then
            target=stem
            while nativefs.getInfo(root..target) do target=target..'_' end
            checked(nativefs.createDirectory(root..target))
        end
        local saved={}
        for _, file in ipairs(files) do
            local path=root..target..'/'..file.name
            local base,extension=file.name:match('^(.*)(%.[^.]+)$')
            while nativefs.getInfo(path) do base=base..'_'; path=root..target..'/'..base..extension end
            attempted[#attempted+1]=path
            checked(nativefs.write(path,file.data))
            saved[file.kind]=path
        end
        return target,saved
    end)
    if not ok then
        -- 仅清理本次新建且未覆盖旧文件的输出；失败不留下半套导入文件。
        for _, path in ipairs(attempted) do pcall(nativefs.remove,path) end
        return nil,tostring(folder)
    end
    return folder,nil,paths
end
return Import
