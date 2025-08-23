i18n = object:new('i18n')
i18n.language = {} --语言表
i18n.language.len = 0

--读取文件夹内所有文件 获得所有语言文件
local files = nativefs.getDirectoryItems('i18n')

for i,v in ipairs(files) do
    if v:sub(-4) == '.lua' then
        i18n.language.len = i18n.language.len + 1
        local name = v:sub(1,-5)
        i18n.language[name] = loadstring(nativefs.read('i18n/'..v))()
    end
end

function i18n:get_languages_number() --返回语言数量
    return self.language.len
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
    return {'en','zh-CN'}
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