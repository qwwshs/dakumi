-- 自定义过渡管理：选择定义后用多行 Lua 函数体编辑，保存时验证并写入撤销栈。
local Chart=require('src.services.chartService')
local Custom=require('src.utils.customTransition')
local G=group:new('custom transitions')
G.selected=nil
G.name={value=''}
G.source={value='return t'}
G.error=''
function G:load() self.selected=nil; self.name.value=''; self.source.value='return t'; self.error='' end
function G:select(name)
    self.selected=name; self.name.value=name; self.source.value=Chart:getCustomTrans(name) or 'return t'; self.error=''
end
function G:save()
    if self.selected and self.name.value~=self.selected then
        self.error=i18n:get('custom_trans.name_locked'); return false
    end
    local ok,err=Chart:putCustomTrans(self.name.value,self.source.value)
    self.error=err or ''
    if ok then self.selected=self.name.value end
    return ok
end
function G:Nui()
    local h=sidebar.layout.uiH
    Nui:layoutRow('dynamic',h,1)
    if not self.selected then
        Nui:label(i18n:get('custom_trans.list'))
        for _,name in ipairs(Chart:getCustomTransNames()) do
            if Nui:button(name) then self:select(name); return end
        end
    end
    Nui:label(i18n:get('custom_trans.name'))
    ui:edit('field',self.name)
    Nui:label(i18n:get('custom_trans.tip'))
    Nui:layoutRow('dynamic',sidebar.layout.custom_trans.code_height,1)
    local x,y,w,height=Nui:widgetBounds()
    self.codeBounds={x=x,y=y,w=w,h=height}
    self.codeState=ui:edit('box',self.source)
    Nui:layoutRow('dynamic',h,2)
    local x,y,w,height=Nui:widgetBounds()
    self.saveBounds={x=x,y=y,w=w,h=height}
    if Nui:button(i18n:get('custom_trans.save')) then self:save() end
    if Nui:button(i18n:get('custom_trans.new')) then self:load() end
    Nui:layoutRow('dynamic',h,1)
    if self.selected then
        if Nui:button(i18n:get('custom_trans.delete')) then
            Chart:deleteCustomTrans(self.selected); self:load()
        end
        if Nui:button(i18n:get('custom_trans.back')) then self:load() end
    end
    local err=self.error~='' and self.error or Custom.getError(self.selected)
    if err then Nui:label(i18n:get('custom_trans.error')); Nui:label(tostring(err)) end
end
return G
