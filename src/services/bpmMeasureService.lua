local AudioService = require('src.services.audioService')
-- 单次后台测量；确认写入由 ChartService 事务记录，可整体撤销。
local ChartService = require('src.services.chartService')
local bus = require('src.utils.eventBus')
local recorder = require('src.utils.chartRecorder')
local Service = {}
local job
local generation = 0
local function invalidate()
    generation = generation + 1
    if job and not job.cancel:peek() then job.cancel:push(true) end
end
bus:on('chart:replaced', invalidate)
bus:on('chart:group_edit_begin', invalidate)
bus:on('chart:group_edit_end', invalidate)

function Service:isBusy() return job ~= nil end

function Service:start(onApplied)
    if job then return false end
    if ChartService:isEditingEventGroup() then
        love.window.showMessageBox(i18n:get('bpm_measure'), i18n:get('bpm_measure_group'), 'info')
        return false
    end
    if not AudioService:getSoundData() then
        love.window.showMessageBox(i18n:get('bpm_measure'), i18n:get('bpm_measure_no_audio'), 'error')
        return false
    end
    local nextJob = {sound = AudioService:getSoundData(), generation = generation, onApplied = onApplied,
        output = love.thread.newChannel(), cancel = love.thread.newChannel()}
    local ok, err = pcall(function()
        nextJob.thread = love.thread.newThread('src/thread/bpm.lua')
        nextJob.thread:start(nextJob.sound, nextJob.output, nextJob.cancel)
    end)
    if not ok then
        love.window.showMessageBox(i18n:get('bpm_measure'), i18n:get('bpm_measure_failed') .. '\n' .. tostring(err), 'error')
        return false
    end
    job = nextJob
    return true
end

function Service:update()
    if not job then return end
    local current = job
    if (current.generation ~= generation or current.sound ~= AudioService:getSoundData()) and not current.cancel:peek() then current.cancel:push(true) end
    if recorder.hasTxn() and not current.cancel:peek() then return end
    local message = current.output:pop()
    if not message and current.thread:isRunning() then return end
    job = nil
    if current.cancel:peek() then return end
    if not message or message.error then
        local err = message and message.error or current.thread:getError() or 'unknown'
        if log then log('BPM measurement: ' .. tostring(err)) end
        love.window.showMessageBox(i18n:get('bpm_measure'), i18n:get('bpm_measure_failed'), 'error')
        return
    end
    local result = message.result
    -- Dakumi 的音频时间 = 谱面时间 - offset；静音时长在谱面中应填负值。
    local offset = -result.offsetMs
    local prompt = string.format(i18n:get('bpm_measure_confirm'), result.bpm, offset, result.offsetMs)
    if result.uncertain then prompt = prompt .. '\n\n' .. i18n:get('bpm_measure_uncertain') end
    local choice = love.window.showMessageBox(i18n:get('bpm_measure'), prompt,
        {i18n:get('bpm_measure_keep'), i18n:get('bpm_measure_apply'), enterbutton = 1, escapebutton = 1}, 'info', true)
    if choice ~= 2 then return end
    local list = {}
    for i = 1, ChartService:getBpmCount() do list[i] = table.copy(ChartService:getBpm(i)) end
    list[1] = list[1] or {beat = {0, 0, 1}, linear_ramp = 0}
    list[1].bpm = result.bpm
    ChartService:change('history.measure_bpm', function()
        ChartService:setOffset(offset)
        ChartService:setBpmList(list)
    end)
    if current.onApplied then current.onApplied(result.bpm, offset) end
end

return Service
