i18n = object:new('i18n')
i18n.language = {} --语言表
local language_file = io.open("i18n/i18n.txt", "r")  -- 以只读模式打开文件
if language_file then
    local content = language_file:read("*a")  -- 读取整个文件内容
    language_file:close()  -- 关闭文件
    i18n.language = loadstring("return "..content)()
end
if type(i18n.language) ~= "table" then
    i18n.language = {}
end


function i18n:get_languages_number() --返回语言数量
    local int = 1 --最大语言数
    local lang = self.language
    for i,v in ipairs(lang) do
        int = math.max(int,#v)
    end
    return int
end

function i18n:get(string) --返回语言
    local lang = self.language
    for i = 1, #lang do
        if lang[i] and lang[i][1] == string then --以英语作为基准
            if lang[i][settings.language + 1] then
                return lang[i][settings.language + 1]
            end
            return lang[i][1]
        end
    end
    return string
end