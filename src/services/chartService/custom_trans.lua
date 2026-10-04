-- 谱面自定义过渡定义；变更统一进入事务、撤销与事件总栈。
return function(Chart,state,internal,dependencies)
    local Custom=require('src.utils.customTransition')
    local function libraryChart() return state.activeGroupEdit and state.activeGroupEdit.mainChart or state.chart end
    function Chart:getCustomTrans(name)
        local source=libraryChart().custom_trans and libraryChart().custom_trans[name]
        return type(source)=='string' and source or nil
    end
    function Chart:getCustomTransNames()
        local names={}
        for name,source in pairs(libraryChart().custom_trans or {}) do
            if type(name)=='string' and type(source)=='string' then names[#names+1]=name end
        end
        table.sort(names)
        return names
    end
    function Chart:putCustomTrans(name,source)
        if state.activeGroupEdit then return false,'exit event group editing before changing definitions' end
        if type(name)~='string' or name=='' or #name>128 or name:find('[%c/\\]') then
            return false,'invalid name'
        end
        local ok,err=Custom.validate(source)
        if not ok then return false,err end
        self:change('history.edit_custom_trans',function()
            state.chart.custom_trans=state.chart.custom_trans or {}
            local before=state.chart.custom_trans[name]
            dependencies.recorder.touchField('custom_trans',name,before)
            state.chart.custom_trans[name]=source
            if before~=source then internal.emitMutation({kind='field_updated',field='custom_trans',
                key=name,before=before,after=source}) end
        end)
        return true
    end
    function Chart:deleteCustomTrans(name)
        if state.activeGroupEdit then return false end
        if not self:getCustomTrans(name) then return false end
        self:change('history.delete_custom_trans',function()
            local before=state.chart.custom_trans[name]
            dependencies.recorder.touchField('custom_trans',name,before)
            state.chart.custom_trans[name]=nil
            internal.emitMutation({kind='field_updated',field='custom_trans',key=name,before=before})
        end)
        return true
    end
    Custom.init(function(name) return Chart:getCustomTrans(name) end)
end
