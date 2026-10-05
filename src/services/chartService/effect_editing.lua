-- effect 的编辑投影：复用事件界面，实际数据和撤销均写入独立的效果列表。
return function(Chart, state, internal, dependencies)
    local Event, recorder = dependencies.Event, dependencies.recorder
    local lanes = {'scroll','jump','track_alpha','track_line_alpha','rotate'}
    local function listData()
        local data={}
        for _, e in ipairs(state.effectObjects or {}) do data[#data+1]=e:toTable() end
        return data
    end
    local function flush()
        local data=listData()
        if table.eq(data,state.chart.effect) then return end
        state.chart.effect=data
        internal.emitMutation({kind='effect_updated',field='effect',after=table.copy(state.chart.effect)})
    end
    local function touch()
        recorder.touchField('effect',nil,table.copy(state.chart.effect or {}))
    end
    local function sort()
        internal.sortWithIndexMap(state.effectObjects, 'effect')
    end
    local function attach(entity)
        -- 实体不注册为谱面 event；修改通过整份 effect 字段记录，避免写入 note/event。
        for key, method in pairs(Event) do
            if type(method)=='function' and key:match('^set') then
                entity[key]=function(self,...)
                    local args={...}
                    return Chart:change('history.edit_effect',function()
                        touch()
                        method(self,unpack(args))
                        sort()
                        flush()
                    end)
                end
            end
        end
        return entity
    end
    local function ensure()
        if state.effectObjects then return end
        state.effectObjects={}
        for _, data in ipairs(state.chart.effect or {}) do
            state.effectObjects[#state.effectObjects+1]=attach(Event.new(data))
        end
        sort()
    end
    function Chart:isEditingEffect() return state.activeEffectEdit==true end
    function Chart:getEffectInitialValue(trackId,kind,t)
        local values=require('src.services.effectService'):calculate({trackId},t)
        return values[trackId][kind=='rotate' and 'note_rotate' or kind] or 0
    end
    function Chart:isEffectType(kind) return table.find(lanes,kind)~=false end
    function Chart:setEffectEditing(enabled)
        state.activeEffectEdit=enabled==true
        if enabled then ensure() end
    end
    function Chart:changeEffectFields(fn)
        return self:change('history.edit_effect',function() ensure(); touch(); fn(); sort(); flush() end)
    end
    local getEvent, getCount = Chart.getEvent, Chart.getEventCount
    Chart.getChartEvent, Chart.getChartEventCount = getEvent, getCount
    function Chart:getEvent(i)
        if self:isEditingEffect() then ensure(); return state.effectObjects[i] end
        return getEvent(self,i)
    end
    function Chart:getEventCount()
        if self:isEditingEffect() then ensure(); return #state.effectObjects end
        return getCount(self)
    end
    local add, delete = Chart.add, Chart.delete
    function Chart:add(entity,action)
        if not self:isEditingEffect() then return add(self,entity,action) end
        if not self:isEffectType(entity:getType()) then return false end
        return self:change('history.add_effect',function()
            ensure(); touch()
            state.effectObjects[#state.effectObjects+1]=attach(entity)
            sort(); flush()
            return true
        end)
    end
    function Chart:delete(entity,action)
        if not self:isEditingEffect() then return delete(self,entity,action) end
        return self:change('history.delete_effect',function()
            ensure()
            local index=internal.findItemIndex(state.effectObjects,entity)
            if not index then return false end
            touch(); table.remove(state.effectObjects,index); flush()
            return true
        end)
    end
    local snapshot = Chart.snapshotEntity
    function Chart:snapshotEntity(entity)
        if self:isEditingEffect() then ensure(); touch()
        else snapshot(self,entity) end
    end
    local commit = Chart.commitChange
    function Chart:commitChange(action)
        if self:isEditingEffect() then ensure(); flush() end
        return commit(self,action)
    end
    local canPlace = Chart.canPlaceEvent
    function Chart:canPlaceEvent(entity,ignored)
        if not self:isEditingEffect() then return canPlace(self,entity,ignored) end
        local first,last=entity:getBeatValue(),entity:getBeat2Value()
        return self:isEffectType(entity:getType()) and first==first and last==last
            and math.abs(first)<math.huge and math.abs(last)<math.huge and last>first
    end
    local sortEvents=Chart.sortEvents
    function Chart:sortEvents()
        if self:isEditingEffect() then ensure(); sort(); state.chart.effect=listData()
        else sortEvents(self) end
    end
    local beginGroup = Chart.beginEventGroupEdit
    function Chart:beginEventGroupEdit(name)
        if self:isEditingEffect() then
            dependencies.eventBus:emit('chart:effect_edit_ending')
            self:setEffectEditing(false)
            state.effectObjects=nil
        end
        return beginGroup(self,name)
    end
    dependencies.eventBus:on('chart:replaced',function()
        state.activeEffectEdit=false; state.effectObjects=nil
    end)
end
