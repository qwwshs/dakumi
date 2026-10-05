-- 真实 ZIP 内存挂载与媒体解码；只写测试 identity，不写用户谱面。
local root=love.filesystem.getWorkingDirectory()
package.path=root..'/?.lua;'..root..'/?/init.lua;'..package.path
nativefs=require('src.utils.nativefs')
local plugin=require('plugins.takana_import.init')
local json=require('src.utils.dkjson')
local bit=require('bit')
local function bytes(n,count)
    local result={}
    for i=1,count do result[i]=string.char(n%256); n=math.floor(n/256) end
    return table.concat(result)
end
local function crc(data)
    local value=-1
    for i=1,#data do
        value=bit.bxor(value,data:byte(i))
        for _=1,8 do value=bit.bxor(bit.rshift(value,1),bit.band(value,1)==1 and 0xedb88320 or 0) end
    end
    local result=bit.bnot(value)
    return result<0 and result+4294967296 or result
end
local function zip(files)
    local localFiles,central={},{}
    local offset=0
    for _,file in ipairs(files) do
        local name,data=file[1],file[2]
        local common=bytes(0,2)..bytes(0,2)..bytes(0,4)..bytes(crc(data),4)..bytes(#data,4)..bytes(#data,4)..bytes(#name,2)
        local entry='PK\3\4'..bytes(20,2)..common..bytes(0,2)..name..data
        central[#central+1]='PK\1\2'..bytes(20,2)..bytes(20,2)..common..bytes(0,2)..bytes(0,2)..bytes(0,2)..bytes(0,2)..bytes(0,4)..bytes(offset,4)..name
        localFiles[#localFiles+1]=entry; offset=offset+#entry
    end
    local directory=table.concat(central)
    return table.concat(localFiles)..directory..'PK\5\6'..bytes(0,4)..bytes(#files,2)..bytes(#files,2)..bytes(#directory,4)..bytes(offset,4)..bytes(0,2)
end
local function run()
    local pcm=string.rep('\0',882)
    local wav='RIFF'..bytes(36+#pcm,4)..'WAVEfmt '..bytes(16,4)..bytes(1,2)..bytes(1,2)..bytes(44100,4)
        ..bytes(88200,4)..bytes(2,2)..bytes(16,2)..'data'..bytes(#pcm,4)..pcm
    local image=love.image.newImageData(2,3):encode('png'):getString()
    local chart={version=3,components={{model={type='track',timeStart=0,timeEnd=1000,
        movement={type='trackEdgeMovement',left={type='position',list={['0']='v1e_(-4.5,u)'}},
        right={type='position',list={['0']='v1e_(4.5,u)'}}}},children={
        {model={type='hit',hitType='Tap',timeJudge=500}}}}}}
    local files={{'project/test.t3proj','musicFileName: music.wav\ncoverFileName: cover.png\n'},
        {'project/normal.json',json.encode(chart)},{'project/music.wav',wav},{'project/cover.png',image}}
    local result=plugin.import({}, {extension='t3pkg',data=zip(files)})
    assert(result.chart.bpm_list[1].bpm==120 and #result.chart.note==1)
    assert(result.audio:getSampleCount()==441 and result.background:getWidth()==2)
    assert(not love.filesystem.getInfo('_takana_import_1/project/normal.json'), '成功后必须卸载 ZIP')
    files[2][2]='invalid JSON'
    assert(not pcall(plugin.import,{}, {extension='t3pkg',data=zip(files)}))
    assert(not love.filesystem.getInfo('_takana_import_2/project/normal.json'), '失败后必须卸载 ZIP')
    assert(not pcall(plugin.import,{}, {extension='t3pkg',data='not a ZIP'}))
    local sample=os.getenv('DAKUMI_TAKANA_SAMPLE')
    local pathFile=os.getenv('DAKUMI_TAKANA_SAMPLE_PATH_FILE')
    if pathFile then
        local file=assert(io.open(pathFile,'rb')); sample=file:read('*a'); file:close()
    end
    if sample then
        local data=assert(nativefs.read(sample))
        result=plugin.import({}, {extension='t3pkg',data=data})
        assert(require('src.services.importService'):validate(result))
        print('SAMPLE: '..#result.chart.note..' notes, '..#result.chart.event..' events, BPM '..result.chart.bpm_list[1].bpm)
        local directory=sample:gsub('\\','/'):match('^(.*)/[^/]+$')
        local externalCount=0
        for _,name in ipairs(nativefs.getDirectoryItems(directory)) do
            if name:match('%.t3proj$') or name=='insanity.json' then
                local external=plugin.import({}, {extension=name:match('%.([^%.]+)$'),
                    name=name,path=directory..'/'..name,data=assert(nativefs.read(directory..'/'..name))})
                assert(#external.chart.note==#result.chart.note and external.audio and external.background)
                externalCount=externalCount+1
                print('SAMPLE external: '..name)
            end
        end
        assert(externalCount>0, '样例目录未找到外部工程文件')
    end
    print('PASS: real Takana ZIP, nested project, audio/image decoding, missing preference and unmount on failure')
end
function love.load()
    local ok,err=xpcall(run,debug.traceback)
    if not ok then print(err) end
    local report=io.open(root..'/.zcode/takana_import_love.txt','w')
    if report then report:write(ok and 'PASS: Takana ZIP and external project\n' or err); report:close() end
    love.event.quit(ok and 0 or 1)
end
function love.errorhandler(err) print(err); return function() return 1 end end
