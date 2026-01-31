--takana转谱器
local Gtakana = group:new('takana')
Gtakana.type = "settings"
Gtakana.frames = 30
function Gtakana:Nui()
    Nui:label(i18n:get('frame_rate') .. ':' .. self.frames)
    self.frames = Nui:slider(1, self.frames, 120, 1)
    local frames = self.frames
    if Nui:button(i18n:get('do')) then
        local to_ms = 1000
        --生成takana游玩文件
        local extra_chart = {}
        local all_track = fTrack:track_get_all_track()
        local id = 0
        local takana = {
            version = 2,
            properties = {
                offset = { value = -chart.offset, type = "offset" },

            },
            components = {}
        }

        takana.components[1] =
        {
            id = id,
            model = { type = 'line' },
            children = {}
        }
        id = id + 1
        --先创建轨道
        for i, v in ipairs(all_track) do
            extra_chart[v] = {
                note = {},
                lpos = {},
                rpos = {}
            }
        end
        local track_id = 0
        for istrack, v in pairs(extra_chart) do
            local track_component = {
                id = id,
                children = {},
                model = {
                    timeStart = 0,
                    timeEnd = math.floor(time.alltime * to_ms),
                    movement = {
                        left = {
                            list = {},
                            type = "position"
                        },
                        right = {
                            list = {},
                            type = "position"
                        },
                        type = "trackEdgeMovement",

                    },
                    type = 'track'
                }

            }
            track_id = id
            id = id + 1
            local x, w
            local lpos, rpos
            local nowbeat
            for istime = 0, time.alltime, 1 / frames do
                istime = math.roundToPrecision(istime, to_ms)

                nowbeat = beat:toBeat(chart.bpm_list, istime)
                x, w = fEvent:get(istrack, nowbeat)
                lpos = x - w / 2
                rpos = x + w / 2
                --进行坐标系变换
                lpos = (lpos + chart.preference.x_offset) / chart.preference.event_scale * 9 - 4.5
                rpos = (rpos + chart.preference.x_offset) / chart.preference.event_scale * 9 - 4.5
                table.insert(v.lpos, lpos)
                table.insert(v.rpos, rpos)
                if lpos ~= rpos or fTrack:get_track_info(istrack).w0thenShow == 1 then
                    if not v.lpos[#v.lpos - 1] or v.lpos[#v.lpos] ~= v.lpos[#v.lpos - 1] then
                        track_component.model.movement.left.list[tostring(istime * to_ms)] = "v1e_(" .. lpos .. ", u)"
                    end
                    if not v.rpos[#v.rpos - 1] or v.rpos[#v.rpos] ~= v.rpos[#v.rpos - 1] then
                        track_component.model.movement.right.list[tostring(istime * to_ms)] = "v1e_(" .. rpos .. ", u)"
                    end
                elseif lpos == rpos and fTrack:get_track_info(istrack).w0thenShow == 0 then
                    track_component.model.movement.left.list[tostring(istime * to_ms)] = "v1e_(" .. 11.45 .. ", u)"
                    track_component.model.movement.right.list[tostring(istime * to_ms)] = "v1e_(" .. 11.45 .. ", u)"
                    table.insert(v.lpos, 11.45)
                    table.insert(v.rpos, 11.45)
                end
            end

            table.insert(takana.components[1].children, track_component)
            local takana_note
            for i, isnote in ipairs(chart.note) do
                if isnote.track == istrack then
                    takana_note = {
                        id = id,
                        model = {
                            timeJudge = math.floor(beat:toTime(chart.bpm_list, isnote.beat) * to_ms),
                            type = 'hit'
                        },
                    }
                    local x, w = fEvent:get(isnote.track, beat:get(isnote.beat))

                    if w == 0 or isnote.fake == 1 then
                        takana_note.model.properties = {}
                        takana_note.model.properties.isDummy = {
                            value = true,
                            type = 'dummyFlag'
                        }
                    end
                    if isnote.type == 'hold' then
                        takana_note.model.timeEnd = math.floor(beat:toTime(chart.bpm_list, isnote.beat2) * to_ms)
                    end
                    if isnote.type == 'note' then
                        takana_note.model.hitType = 'Tap'
                    elseif isnote.type == 'wipe' then
                        takana_note.model.hitType = 'Slide'
                    elseif isnote.type == 'hold' then
                        takana_note.model.type = 'hold'
                        if isnote.note_head == 1 then
                            local hold_note = {
                                id = id,
                                model = {
                                    timeJudge = math.floor(beat:toTime(chart.bpm_list, isnote.beat) * to_ms),
                                    type = 'hit',
                                    hitType = 'Tap'
                                },
                            }
                            if w == 0 or isnote.fake == 1 then
                                hold_note.model.properties = {}
                                hold_note.model.properties.isDummy = {
                                    value = true,
                                    type = 'dummyFlag'
                                }
                            end
                            table.insert(takana.components[1].children[#takana.components[1].children].children,
                                hold_note)
                            id = id + 1
                        end
                        if isnote.wipe_head == 1 then
                            local hold_note = {
                                id = id,
                                model = {
                                    timeJudge = math.floor(beat:toTime(chart.bpm_list, isnote.beat) * to_ms),
                                    type = 'hit',
                                    hitType = 'Slide'
                                },
                            }
                            if w == 0 or isnote.fake == 1 then
                                hold_note.model.properties = {}
                                hold_note.model.properties.isDummy = {
                                    value = true,
                                    type = 'dummyFlag'
                                }
                            end
                            table.insert(takana.components[1].children[#takana.components[1].children].children,
                                hold_note)
                            id = id + 1
                        end
                    end
                    table.insert(takana.components[1].children[#takana.components[1].children].children, takana_note)
                    id = id + 1
                end
            end
        end

        local name = 'ravage'
        local dakumi_name = chart.info.chart_name:lower()

        --生成配置文件
        local level = 5
        for i, v in ipairs({ 'normal', 'hard', 'master', 'insanity', 'ravage' }) do
            if string.find(dakumi_name, v) then
                level = i
                name = v
            end
        end

        local songinfo =
        {
            id = '',
            title = { en = chart.info.song_name },
            composer = { en = chart.info.artist },
            illustrator = {},
            bpmDisplay = chart.bpm_list[1].bpm,
            description = {},
            difficulties = {}
        }
        songinfo.difficulties[level] = {
            levelDisplay = string.match(chart.info.chart_name, "Lv%.(.+)"),
            charter = { en = chart.info.chartor }
        }
        local preference = {
            difficulty = level,
            offset = -chart.offset,
            musicVolumePercent = 100,
            speed = 0,
            timeGridLineCount = 4,
            widthGridInterval = 1.5,
            widthGridOffset = 0,
            bpmList = {}
        }
        for i, v in ipairs(chart.bpm_list) do
            preference.bpmList[beat:toTime(chart.bpm_list, v.beat)] = v.bpm
        end
        local t3proj = [[# Setting_T3ProjSetting_音源文件名称 | 以下文件需要附带文件后缀名
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
        local music_path = menu.chartTab[menu.selectMusicPos]
        local lastSlashIndex = string.find(music_path, "/[^/]*$") --找到最后一个斜杠的位置
        if not lastSlashIndex then
            lastSlashIndex = string.find(music_path, "\\[^\\]*$") --找到最后一个斜杠的位置
        end
        if not lastSlashIndex then
            lastSlashIndex = 0
        end
        --创建文件夹
        local ispath = PATH.usersPath.export .. string.sub(music_path, lastSlashIndex + 1) .. '/'
        nativefs.mount(PATH.base)
        nativefs.createDirectory(ispath)

        for i, v in ipairs(nativefs.getDirectoryItems(ispath)) do
            love.filesystem.remove(ispath .. v) --删除文件
        end


        save(t3proj, ispath .. '.t3proj')
        save(yaml.to_yaml(songinfo), ispath .. 'songinfo.yaml')
        save(yaml.to_yaml(preference), ispath .. 'preference.yaml')
        save(dkjson.encode(takana, { indent = true }), ispath .. name .. '.json')
        if music then
            nativefs.newFile(ispath .. 'music.' .. getFileExtension(menu.musicPath)) --复制到当前文件夹下
            nativefs.write(ispath .. 'music.' .. getFileExtension(menu.musicPath),
                nativefs.read(menu.musicPath))
        end
        if bg then
            nativefs.newFile(ispath .. 'cover.' .. getFileExtension(menu.bgPath)) --复制到当前文件夹下
            nativefs.write(ispath .. 'cover.' .. getFileExtension(menu.bgPath),
                nativefs.read(menu.bgPath))
        end

        log("takana export done")
        nativefs.unmount()
    end
end

return Gtakana
