-- Takana 工程读取：统一处理项目配置、编辑谱面与发布谱面；外部文件只作为数据。
local yaml=require('src.utils.yaml')
local Converter=require('plugins.takana_import.converter')
local Project={}
local difficulties={'normal','hard','master','insanity','ravage'}
local function safe(path)
    assert(type(path)=='string' and path~='', 'Takana：文件名称为空')
    path=path:gsub('\\','/')
    assert(not path:match('^/') and not path:find(':',1,true), 'Takana：文件必须位于工程目录内')
    for part in path:gmatch('[^/]+') do assert(part~='..', 'Takana：文件不能越过工程目录') end
    return path
end
function Project.yaml(bytes)
    if not bytes then return nil end
    local source=bytes:gsub('^\239\187\191',''):gsub('\r\n','\n'):gsub('\r','\n')
    -- 项目自带 YAML 解析器要求固定缩进；Takana 导出的映射可使用任意递增缩进。
    -- 只规范缩进层级，不改字段与标量内容；文本块保留内部相对缩进。
    local lines,indents={}, {0}
    local blockIndent,blockDepth,blockFirst
    for line in (source..'\n'):gmatch('(.-)\n') do
        local spaces,text=line:match('^( *)(.*)$')
        local indent=#spaces
        if text=='' or text:match('^#') then lines[#lines+1]=line
        elseif blockIndent and indent>blockIndent then
            blockFirst=blockFirst or indent
            lines[#lines+1]=string.rep(' ',(blockDepth+1)*2+math.max(0,indent-blockFirst))..text
        else
            blockIndent,blockDepth,blockFirst=nil,nil,nil
            while #indents>1 and indent<indents[#indents] do table.remove(indents) end
            if indent>indents[#indents] then indents[#indents+1]=indent end
            assert(indent==indents[#indents], 'Takana：YAML 缩进不匹配')
            local depth=#indents-1
            lines[#lines+1]=string.rep(' ',depth*2)..text
            if text:match(':%s*[|>][%d+-]*%s*$') then blockIndent,blockDepth=indent,depth end
        end
    end
    local data=yaml.eval(table.concat(lines,'\n'))
    assert(type(data)=='table', 'Takana：YAML 必须是映射表')
    return data
end
function Project.read(read,list,requested,bytes)
    local config={}
    local projectName=requested and requested:lower():match('%.t3proj$') and requested
    if not projectName then
        local names=list('') or {}
        table.sort(names)
        for _,name in ipairs(names) do
            if name:lower():match('%.t3proj$') then projectName=name; break end
        end
    end
    if projectName then config=Project.yaml(projectName==requested and bytes or read(safe(projectName))) or {} end
    local function resource(key,default) return read(safe(config[key] or default)) end
    local preference=Project.yaml(resource('preferenceFileName','preference.yaml'))
    local songinfo=Project.yaml(resource('songInfoFileName','songinfo.yaml')) or {}
    local selected=tonumber((preference or {}).difficulty) or 1
    local chartName,chartBytes,difficulty
    if requested and requested:lower():match('%.json$') then
        chartName,chartBytes=requested,bytes
        for i,name in ipairs(difficulties) do
            local base=config[name..'ChartFileName'] or name
            if requested==base..'.json' or requested==base..'.editing.json' then difficulty=i end
        end
    else
        -- 优先偏好指定的难度；不存在时按 Normal 到 Ravage 选择首张可用谱面。
        local order={}
        if selected>=1 and selected<=5 and selected%1==0 then order[1]=selected end
        for i=1,5 do if i~=selected then order[#order+1]=i end end
        for _,i in ipairs(order) do
            local base=safe(config[difficulties[i]..'ChartFileName'] or difficulties[i])
            for _,suffix in ipairs({'.editing.json','.json'}) do
                local data=read(base..suffix)
                if data then chartName,chartBytes,difficulty=base..suffix,data,i; break end
            end
            if chartBytes then break end
        end
    end
    assert(chartBytes, 'Takana：工程中没有可导入的难度谱面')
    local chart=Converter.convert(Converter.decode(chartBytes),{preference=preference,songinfo=songinfo,
        difficulty=difficulty,chartName=chartName:gsub('%.editing%.json$',''):gsub('%.json$','')})
    local musicName=safe(config.musicFileName or 'music.mp3')
    local coverName=safe(config.coverFileName or 'cover.jpg')
    return {chart=chart,music=read(musicName),musicName=musicName,cover=read(coverName),coverName=coverName}
end
return Project
