-- 新服务与纯计算模块先采用严格检查，历史全局依赖由边界检查约束。
std = 'luajit'
self = false -- 冒号方法允许不读取隐式 self，保持接口一致。
max_line_length = false
files['src/utils/autoSaveRetention.lua'] = {globals = {'love'}}
