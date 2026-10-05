local ctx
local AudioService = require('src.services.audioService')
local ChartService = require("src.services.chartService")

local Gtakana = group:new('takana')
Gtakana.type = "settings"
Gtakana.frames = 30  -- 导出帧率

--- 坐标系变换常量
-- 将 dakumi 坐标系转换为 Takana 坐标系
local TAKANA_SCALE = 9
local TAKANA_OFFSET = -4.5

--- 将 dakumi 坐标转换为 Takana 坐标
-- @tparam number x dakumi x 坐标
-- @tparam number w dakumi 宽度
-- @treturn number lpos 左边界位置
-- @treturn number rpos 右边界位置
local function toTakanaCoord(x, w)
    local lpos = x - w / 2
    local rpos = x + w / 2
    local x_offset = ChartService:getPreferenceField('x_offset')
    local event_scale = ChartService:getPreferenceField('event_scale')
    lpos = (lpos + x_offset) / event_scale * TAKANA_SCALE + TAKANA_OFFSET
    rpos = (rpos + x_offset) / event_scale * TAKANA_SCALE + TAKANA_OFFSET
    return lpos, rpos
end

--- 生成 Takana 谱面数据
-- @tparam number frames 导出帧率
-- @treturn table Takana 谱面数据
local function generateTakanaChart(frames)
    local to_ms = 1000
    local all_track = fTrack:track_get_all_track()
    local id = 0

    local takana = {
        version = 2,
        properties = {
            offset = { value = -ChartService:getOffset(), type = "offset" },
        },
        components = {}
    }

    -- 创建根组件
    takana.components[1] = {
        id = id,
        model = { type = 'line' },
        children = {}
    }
    id = id + 1

    -- 为每个轨道创建组件
    for i, istrack in ipairs(all_track) do
        local track_component = {
            id = id,
            children = {},
            model = {
                timeStart = 0,
                timeEnd = math.floor(AudioService:getDuration() * to_ms),
                movement = {
                    left = { list = {}, type = "position" },
                    right = { list = {}, type = "position" },
                    type = "trackEdgeMovement",
                },
                type = 'track'
            }
        }
        id = id + 1

        -- 按帧率采样轨道位置
        local prev_lpos, prev_rpos = nil, nil
        local nowisfade = false

        for istime = 0, AudioService:getDuration(), 1 / frames do
            istime = math.roundToPrecision(istime, to_ms)
            local nowbeat = ChartService:toBeat(istime)
            local x, w = fEvent:get(istrack, nowbeat)
            local lpos, rpos = toTakanaCoord(x, w)
            local track_w0thenShow = ChartService:getTrackField(istrack, 'w0thenShow')

            if lpos ~= rpos or track_w0thenShow == 1 then
                -- 轨道可见
                if prev_lpos ~= lpos or nowisfade then
                    track_component.model.movement.left.list[tostring(istime * to_ms)] = "v1e_(" .. lpos .. ", u)"
                end
                if prev_rpos ~= rpos or nowisfade then
                    track_component.model.movement.right.list[tostring(istime * to_ms)] = "v1e_(" .. rpos .. ", u)"
                end
                nowisfade = false
            elseif lpos == rpos and track_w0thenShow == 0 and not nowisfade then
                -- 轨道消失（淡出）
                if prev_lpos ~= lpos or prev_rpos ~= rpos then
                    nowisfade = true
                    track_component.model.movement.left.list[tostring(istime * to_ms)] = "v1e_(" .. TAKANA_OFFSET .. ", u)"
                    track_component.model.movement.right.list[tostring(istime * to_ms)] = "v1e_(" .. TAKANA_OFFSET .. ", u)"
                end
            end

            prev_lpos = lpos
            prev_rpos = rpos
        end

        table.insert(takana.components[1].children, track_component)

        -- 为该轨道添加音符
        for j = 1, ChartService:getNoteCount() do
            local isnote = ChartService:getNote(j)
            if isnote:getTrack() == istrack then
                local note_x, note_w = fEvent:get(isnote:getTrack(), isnote:getBeatValue())
                local isDummy = (note_w == 0 or isnote:isFakeNote())

                local takana_note = {
                    id = id,
                    model = {
                        timeJudge = math.floor(ChartService:toTime(isnote:getBeatValue()) * to_ms),
                        type = 'hit'
                    },
                }

                if isDummy then
                    takana_note.model.properties = {
                        isDummy = { value = true, type = 'dummyFlag' }
                    }
                end

                -- 根据音符类型设置 Takana 类型
                if isnote:isNote() then
                    takana_note.model.hitType = 'Tap'
                elseif isnote:isWipe() then
                    takana_note.model.hitType = 'Slide'
                elseif isnote:isHold() then
                    takana_note.model.type = 'hold'
                    takana_note.model.timeEnd = math.floor(ChartService:toTime(isnote:getBeat2Value()) * to_ms)

                    -- hold 头部可以附加 note 或 wipe
                    if isnote:getNoteHead() == 1 then
                        local hold_note = {
                            id = id,
                            model = {
                                timeJudge = math.floor(ChartService:toTime(isnote:getBeatValue()) * to_ms),
                                type = 'hit',
                                hitType = 'Tap'
                            },
                        }
                        if isDummy then
                            hold_note.model.properties = {
                                isDummy = { value = true, type = 'dummyFlag' }
                            }
                        end
                        table.insert(track_component.children, hold_note)
                        id = id + 1
                    end
                    if isnote:getWipeHead() == 1 then
                        local hold_note = {
                            id = id,
                            model = {
                                timeJudge = math.floor(ChartService:toTime(isnote:getBeatValue()) * to_ms),
                                type = 'hit',
                                hitType = 'Slide'
                            },
                        }
                        if isDummy then
                            hold_note.model.properties = {
                                isDummy = { value = true, type = 'dummyFlag' }
                            }
                        end
                        table.insert(track_component.children, hold_note)
                        id = id + 1
                    end
                end

                table.insert(track_component.children, takana_note)
                id = id + 1
            end
        end
    end

    return takana
end

--- 生成歌曲信息 YAML
-- @treturn table 歌曲信息表
local function generateSongInfo()
    local songinfo = {
        id = '',
        title = { en = ChartService:getInfoField('song_name') },
        composer = { en = ChartService:getInfoField('artist') },
        illustrator = {},
        bpmDisplay = ChartService:getBpm(1).bpm,
        description = {},
        difficulties = {}
    }

    -- 根据谱面名推断难度等级
    local level = 5
    local name = 'ravage'
    local dakumi_name = ChartService:getInfoField('chart_name'):lower()
    for i, v in ipairs({ 'normal', 'hard', 'master', 'insanity', 'ravage' }) do
        if string.find(dakumi_name, v) then
            level = i
            name = v
        end
    end

    songinfo.difficulties[level] = {
        levelDisplay = string.match(ChartService:getInfoField('chart_name'), "Lv%.(.+)"),
        charter = { en = ChartService:getInfoField('chartor') }
    }

    return songinfo, level, name
end

--- 生成偏好设置 YAML
-- @treturn table 偏好设置表
local function generatePreference()
    local preference = {
        difficulty = 1,
        offset = -ChartService:getOffset(),
        musicVolumePercent = 100,
        speed = 0,
        timeGridLineCount = 4,
        widthGridInterval = 1.5,
        widthGridOffset = 0,
        bpmList = {}
    }
    for i = 1, ChartService:getBpmCount() do
        local v = ChartService:getBpm(i)
        preference.bpmList[ChartService:toTime(v.beat) * 1000] = v.bpm
    end
    return preference
end

--- 项目配置文件模板
local t3proj_template = [[# Setting_T3ProjSetting_音源文件名称 | 以下文件需要附带文件后缀名
musicFileName: music.mp3
# Setting_T3ProjSetting_封面文件名称
coverFileName: cover.jpg
# Setting_T3ProjSetting_乐曲信息文件名称
songInfoFileName: songinfo.yaml
# Setting_T3ProjSetting_偏好设置文件名称，例如在谱面编辑器中该项用来保存编辑器的一些设置
preferenceFileName: preference.yaml
# Setting_T3ProjSetting_各难度谱面文件名称 | 以下文件不需要附带文件后缀
normalChartFileName: normal
hardChartFileName: hard
masterChartFileName: master
insanityChartFileName: insanity
ravageChartFileName: ravage
]]

--- 渲染导出 UI 并执行导出
function Gtakana:Nui()
    ctx.ui:label(ctx.i18n:get('frame_rate') .. ':' .. self.frames)
    self.frames = ctx.ui:slider(1, self.frames, 120, 1)

    if ctx.ui:button(ctx.i18n:get('do')) then
        -- 生成所有数据
        local takana = generateTakanaChart(self.frames)
        local songinfo, level, name = generateSongInfo()
        local preference = generatePreference()

        -- 确定导出路径
        local music_path = menu.chartTab[menu.selectMusicPos]
        local lastSlashIndex = string.find(music_path, "/[^/]*$")
        if not lastSlashIndex then
            lastSlashIndex = string.find(music_path, "\\[^\\]*$")
        end
        if not lastSlashIndex then
            lastSlashIndex = 0
        end
        local ispath = PATH.usersPath.export .. string.sub(music_path, lastSlashIndex + 1) .. '/'

        nativefs.mount(PATH.base)
        nativefs.createDirectory(ispath)

        -- 清空导出目录
        for i, v in ipairs(nativefs.getDirectoryItems(ispath)) do
            love.filesystem.remove(ispath .. v)
        end

        -- 写入配置文件
        nativefs.newFile(ispath .. '.t3proj')
        nativefs.write(ispath .. '.t3proj', t3proj_template)

        nativefs.newFile(ispath .. 'songinfo.yaml')
        nativefs.write(ispath .. 'songinfo.yaml', yaml.to_yaml(songinfo))

        nativefs.newFile(ispath .. 'preference.yaml')
        nativefs.write(ispath .. 'preference.yaml', yaml.to_yaml(preference))

        nativefs.newFile(ispath .. name .. '.json')
        nativefs.write(ispath .. name .. '.json', dkjson.encode(takana, { indent = true }))

        -- 复制音频文件
        if AudioService:getSource() then
            local ext = getFileExtension(menu.musicPath)
            nativefs.newFile(ispath .. 'music.' .. ext)
            nativefs.write(ispath .. 'music.' .. ext, nativefs.read(menu.musicPath))
        end

        -- 复制封面图片
        if bg then
            local ext = getFileExtension(menu.bgPath)
            nativefs.newFile(ispath .. 'cover.' .. ext)
            nativefs.write(ispath .. 'cover.' .. ext, nativefs.read(menu.bgPath))
        end

        log("takana export done")
        nativefs.unmount()
    end
end

local sidebarRoom, homeGroup, navigation

return {
    name = 'takana',
    version = '1.0.0',
    description = '侧边栏 Takana 导出',
    target = 'edit/sidebar',

    init = function(context)
        ctx = context
        sidebarRoom = ctx.root:findContainer('edit/sidebar')
        homeGroup = sidebarRoom:getGroup('nil')
        navigation = object:new('takana navigation')
        function navigation:Nui()
            if ctx.ui:button(ctx.i18n:get('takana')) then
                messageBox:add('takana')
                sidebarRoom:to('takana')
            end
        end
        sidebarRoom:addGroup(Gtakana)
        homeGroup:addObject(navigation, 30)
    end,

    destroy = function()
        if homeGroup and navigation then homeGroup:deleteObject(navigation) end
        if sidebarRoom then
            if sidebarRoom.displayed_content == 'takana' then sidebarRoom:to('nil') end
            sidebarRoom:deleteGroup(Gtakana)
        end
        sidebarRoom, homeGroup, navigation = nil, nil, nil
        ctx = nil
    end,
}
