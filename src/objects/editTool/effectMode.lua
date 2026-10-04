-- 工具栏效果编辑开关；复用五列布局、事件放置与属性页。
local Chart=require('src.services.chartService')
local clipboard=require('src.utils.clipboard')
local mode=object:new('effectMode')
mode.type='custom'
local effectLanes={'scroll','jump','track_alpha','track_line_alpha','rotate'}
local function setLanes(lanes)
    for key,value in pairs(trackSequence) do
        if type(key)=='number' or type(value)=='number' then trackSequence[key]=nil end
    end
    for index,kind in ipairs(lanes) do trackSequence[index]=kind; trackSequence[kind]=index end
    tabs.layout.lane=table.copy(lanes)
    for _, tab in ipairs(tabs.list) do
        for _, kind in ipairs(lanes) do
            if tab.edit[kind]==nil then tab.edit[kind]=true; tab.copy[kind]=true end
        end
    end
end
function mode:toggle()
    local entering=not Chart:isEditingEffect()
    if entering and Chart:isEditingEventGroup() then
        if not sidebar:getGroup('event groups'):exitGroup(true) then return end
    end
    sidebar:to('nil') -- 先提交当前属性页，之后才切换数据源。
    fEvent:cleanUp(); fNote:holdCleanUp()
    clipboard.mouse_start_pos.down=false
    if entering then
        self.previousLanes={}
        for i=1,5 do self.previousLanes[i]=trackSequence[i] end
        self.previousClipboard=clipboard.tab
        clipboard.tab=table.copy(clipboard.meta)
        Chart:setEffectEditing(true)
        setLanes(effectLanes)
    else
        Chart:setEffectEditing(false)
        setLanes(self.previousLanes or {'note','x','w','lpos','rpos'})
        clipboard.tab=self.previousClipboard or table.copy(clipboard.meta)
        self.previousLanes,self.previousClipboard=nil,nil
    end
    require('src.objects.play.demoInEdit'):resetTraversal()
end
function mode:Nui()
    if self.previousLanes and not Chart:isEditingEffect() then
        setLanes(self.previousLanes)
        self.previousLanes,self.previousClipboard=nil,nil
        clipboard.tab=table.copy(clipboard.meta)
    end
    if Nui:groupBegin('effect_mode','border') then
        Nui:layoutRow('dynamic',20,1)
        Nui:label(i18n:get('effect_editor.title'))
        Nui:layoutRow('dynamic',34,1)
        local x,y,w,h=Nui:widgetBounds()
        self.buttonBounds={x=x,y=y,w=w,h=h}
        if Nui:button(i18n:get(Chart:isEditingEffect() and 'effect_editor.exit' or 'effect_editor.enter')) then
            self:toggle()
        end
        Nui:groupEnd()
    end
end
return mode
