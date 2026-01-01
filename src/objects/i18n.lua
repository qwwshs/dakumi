i18n = object:new('i18n')
i18n.language = {} --语言表
i18n.languageName = {}

--读取文件夹内所有文件 获得所有语言文件
local files = nativefs.getDirectoryItems('i18n')

for i,v in ipairs(files) do
    if v:sub(-4) == '.lua' then
        local name = v:sub(1,-5)
        i18n.language[name] = loadstring(nativefs.read(PATH.i18n..v))()
        table.insert(i18n.languageName,name)
    end
end

function i18n:get_languages_number() --返回语言数量
    return #self.languageName
end
function i18n:get_now_language_in_table(lang)
    for i,v in ipairs(i18n:get_languages_table()) do
        if v == lang then
            return i
        end
    end
    return 1
end
function i18n:get_languages_table() --返回语言
    return i18n.languageName
end

function i18n:get(string) --返回语言
    if not self.language[settings.language] then
        return string
    end

    if self.language[settings.language][string] then
        return self.language[settings.language][string]
    end

    return string
end