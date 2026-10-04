-- 谱面服务装配入口。所有子模块共用这份私有状态，不向调用方暴露内部表。
local ChartService = {}
local state = {chart = {}, extra_chart = {track = {}}, eventGroupsRevision = 0}
local internal = {}
local dependencies = {
    Note = require('src.models.Note'),
    Event = require('src.models.Event'),
    eventBus = require('src.utils.eventBus'),
    recorder = require('src.utils.chartRecorder'),
}

-- 装配过程不读取谱面；全部模块装配完成后才对外返回服务。
for _, name in ipairs({
    'index', 'transactions', 'lifecycle', 'event_groups', 'entities', 'fields', 'timing',
}) do
    require('src.services.chartService.' .. name)(ChartService, state, internal, dependencies)
end
require('src.utils.timeOffset').init(ChartService)
return ChartService
