-- 真正的解码资源、内部应用、WAV/PNG 写出与 menu 未匹配入口。
return function()
    local Import=require('src.services.importService')
    local manager=require('src.utils.plugin')
    local Chart=require('src.services.chartService')
    local Audio=require('src.services.audioService')
    local sound=love.sound.newSoundData(4410,44100,16,1)
    sound:setSample(1,0.5)
    local pixels=love.image.newImageData(3,2)
    pixels:setPixel(1,1,0.5,0.25,0.75,0.5)
    local payload
    assert(manager:register({name='_test_import',type='import',layer=-100,
        review=function(ctx,r) assert(ctx.importer==Import); return r.extension=='testpkg' end,
        import=function(ctx,r) assert(r.data=='bytes'); return payload end}))
    for mask=1,7 do
        local oldChart,oldSource,oldBg=Chart:getInfoField('chart_name'),Audio:getSource(),bg
        payload={}
        if mask%2==1 then payload.chart={info={chart_name='import '..mask}} end
        if math.floor(mask/2)%2==1 then payload.audio=sound end
        if math.floor(mask/4)%2==1 then payload.background=pixels end
        local result,err=Import:import({name='file.testpkg',data='bytes'})
        assert(result==payload,err)
        if payload.chart then assert(Chart:getInfoField('chart_name')=='import '..mask)
        else assert(Chart:getInfoField('chart_name')==oldChart) end
        if payload.audio then assert(Audio:getSoundData()==sound and Audio:getSource():typeOf('Source'))
        else assert(Audio:getSource()==oldSource) end
        if payload.background then assert(bg:getWidth()==3 and bg:getHeight()==2)
        else assert(bg==oldBg) end
    end
    local oldWrite,oldInfo,oldCreate=nativefs.write,nativefs.getInfo,nativefs.createDirectory
    local files={}
    nativefs.write=function(path,data) files[path]=data; return true end
    nativefs.getInfo=function(path) return files[path] end
    nativefs.createDirectory=function(path) files[path]={directory=true}; return true end
    payload={chart={},audio=sound,background=love.graphics.newImage(pixels)}
    local folder,err,paths=Import:saveToMenu(payload,{name='file.testpkg'})
    assert(folder,err)
    local decoded=love.sound.newSoundData(love.filesystem.newFileData(files[paths.audio],'import.wav'))
    assert(decoded:getSampleRate()==44100 and decoded:getSampleCount()==4410)
    assert(math.abs(decoded:getSample(1)-0.5)<0.001)
    local image=love.image.newImageData(love.filesystem.newFileData(files[paths.background],'import.png'))
    local r,g,b,a=image:getPixel(1,1)
    assert(math.abs(r-0.5)<0.01 and math.abs(a-0.5)<0.01,'Image export changed colors or transparency: '..tostring(r)..','..tostring(a))
    nativefs.write,nativefs.getInfo,nativefs.createDirectory=oldWrite,oldInfo,oldCreate
    local oldImport,oldTabs,oldFlushed=menu.importFile,menu.chartTab,menu.flushed
    local forwarded,closed=false,false
    menu.chartTab={}
    menu.importFile=function(self,request)
        assert(request.name=='file.testpkg' and request.data=='bytes')
        local result,reason=Import:convert(request,'menu')
        assert(result==payload,reason)
        forwarded=true
        return result
    end
    menu.flushed=function() error('plugin import must not be refreshed a second time') end
    menu:filedropped({open=function() return true end,read=function() return 'bytes' end,
        close=function() closed=true end,getFilename=function() return 'C:/test/file.testpkg' end})
    assert(forwarded and closed)
    menu.importFile,menu.chartTab,menu.flushed=oldImport,oldTabs,oldFlushed
    manager:unregister('_test_import')
    print('PASS: seven real import combinations, decoded audio/background, WAV/PNG roundtrip and menu fallback')
end
