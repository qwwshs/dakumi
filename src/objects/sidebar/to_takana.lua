--takana转谱器
local Gtakana = group:new('takana')
Gtakana.type = "settings"
Gtakana.frames = 30
function Gtakana:Nui()
    Nui:label(i18n:get('frame_rate')..':'..self.frames)
    self.frames = Nui:slider(1,self.frames,120,1)
    local frames = self.frames
    if Nui:button(i18n:get('do')) then
        local to_ms = 1000
        --生成takana游玩文件
        local extra_chart = {}
        local all_track = fTrack:track_get_all_track()
        local id = 0
        local takana = {
            properties = {
                offset = "0",
                mode = 'takana',
            },
            components = {}
        }
        takana.properties.offset = tostring(math.max(chart.offset,0))

        takana.components[1] = 
        {
            id = id,
            type = 'judgeLine'
        }
        id = id + 1
        --先创建轨道
        for i,v in ipairs(all_track) do
            extra_chart[v] = {
                note = {},
                lpos = {},
                rpos = {}
            }
        end
        local track_id = 0
        for istrack,v in pairs(extra_chart) do
            local track_component = {
                id = id,
                timeStart = 0,
                timeEnd = math.floor(time.alltime*to_ms),
                line = 0,
                movement = {
                    left = {
                        list = {},
                        type = "v1e"
                    },
                    right = {
                        list = {},
                        type = "v1e"
                    },
                    type = "trackEdgeMoveList"
                },
                type = 'e_track'
            }
            track_id = id    
            id = id + 1
            local x,w
            local lpos,rpos
            local nowbeat
            for istime=0,time.alltime,1/frames do
                istime = math.roundToPrecision(istime,to_ms)
                
                nowbeat = beat:toBeat(chart.bpm_list,istime)
                x,w = fEvent:get(istrack,nowbeat)
                lpos = x - w/2
                rpos = x + w/2
                --进行坐标系变换
                lpos = (lpos + chart.preference.x_offset) / chart.preference.event_scale * 9 - 4.5
                rpos = (rpos + chart.preference.x_offset) / chart.preference.event_scale * 9 - 4.5
                table.insert(track_component.movement.left.list,"("..math.floor(istime*to_ms)..","..lpos..", u)")
                table.insert(track_component.movement.right.list,"("..math.floor(istime*to_ms)..","..rpos..", u)")
            end

            table.insert(takana.components,track_component) 
            local takana_note
            for i,isnote in ipairs(chart.note) do
                if isnote.track == istrack then

                    takana_note = {
                        id = id,
                        track = track_id,
                        timeJudge = math.floor(beat:toTime(chart.bpm_list,isnote.beat)*to_ms),
                        properties = {
                            isDummy = isnote.fake == 1
                        },
                    }
                    id = id + 1
                    if isnote.type == 'hold' then
                        takana_note.timeEnd = math.floor(beat:toTime(chart.bpm_list,isnote.beat2)*to_ms)
                    end
                    if isnote.type == 'note' then 
                        takana_note.type = 'e_tap'
                    elseif isnote.type == 'wipe' then 
                        takana_note.type = 'e_slide'
                    elseif isnote.type == 'hold' then 
                        takana_note.type = 'e_hold'
                    end
                    table.insert(takana.components,takana_note) 
                end
            end
        end
        local name = "ravage"
        local dakumi_name = chart.info.chart_name:lower()
        if dakumi_name == 'normal' or dakumi_name == 'hard' or dakumi_name == 'master' or dakumi_name == 'insanity' or dakumi_name == 'ravage' then
            name = dakumi_name
        end
        save(dkjson.encode(takana,{indent = true,invalidnumbers = true}),PATH.usersPath.export..name..'.json')
    end
end
return Gtakana