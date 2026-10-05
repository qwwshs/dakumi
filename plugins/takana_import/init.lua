-- Takana 导入插件：t3pkg 是 ZIP；也支持拖入 t3proj 或具体难度 JSON。
local Converter=require('plugins.takana_import.converter')
local Project=require('plugins.takana_import.project')
local serial=0
local function decodeMedia(project)
    local result={chart=project.chart}
    if project.music then
        result.audio=love.sound.newSoundData(love.filesystem.newFileData(project.music,project.musicName))
    end
    if project.cover then
        result.background=love.image.newImageData(love.filesystem.newFileData(project.cover,project.coverName))
    end
    return result
end
local function external(request)
    local root=(request.path or ''):gsub('\\','/'):match('^(.*)/[^/]*$')
    local function read(name) if root then return nativefs.read(root..'/'..name) end end
    local function list(name) return root and nativefs.getDirectoryItems(root..'/'..name) or {} end
    return decodeMedia(Project.read(read,list,request.name,request.data))
end
local function archive(request)
    serial=serial+1
    local mountpoint='_takana_import_'..serial
    local archiveData=love.filesystem.newFileData(request.data,'takana.zip')
    assert(love.filesystem.mount(archiveData,mountpoint), 'Takana：无法打开 t3pkg ZIP 压缩包')
    local ok,result=xpcall(function()
        -- 兼容 ZIP 根目录直接放工程文件以及外包一层文件夹的工程。
        local roots={}
        local function find(path,depth)
            assert(depth<32, 'Takana：压缩包目录过深')
            local names=love.filesystem.getDirectoryItems(mountpoint..'/'..path)
            table.sort(names)
            for _,name in ipairs(names) do
                local relative=path..name
                local info=love.filesystem.getInfo(mountpoint..'/'..relative)
                if info.type=='directory' then find(relative..'/',depth+1)
                elseif name:lower():match('%.t3proj$') then roots[#roots+1]=path end
            end
        end
        find('',0)
        assert(#roots<=1, 'Takana：压缩包包含多个工程，请分别导入')
        local root=roots[1] or ''
        local function read(name) return love.filesystem.read(mountpoint..'/'..root..name) end
        local function list(name) return love.filesystem.getDirectoryItems(mountpoint..'/'..root..name) end
        return decodeMedia(Project.read(read,list))
    end,debug.traceback)
    love.filesystem.unmount(archiveData)
    if not ok then error(result) end
    return result
end
return {
    name='takana_import',version='1.0.0',type='import',layer=20,
    review=function(_,request)
        if request.extension=='t3pkg' or request.extension=='t3proj' then return true end
        if request.extension~='json' then return false end
        local ok,data=pcall(Converter.decode,request.data)
        return ok and Converter.matches(data)
    end,
    import=function(_,request)
        if request.extension=='t3pkg' then return archive(request) end
        return external(request)
    end,
}
