--[[
    模块名: editState
    描述: 编辑器交互状态中心（核心持有）。接管交互的插件把自身状态写进来，
          内部模块只读本模块，不反向依赖具体插件（依赖方向：插件 → 核心）。
    作者: qwwshs
    依赖: 无
]]

local editState = {}

--- demo 区域交互被接管（directEventEditing 插件直观编辑模式开启时为 true，
--- play 区域的轨道点选让位给插件）
editState.demoCaptured = false

--- event 控制点拖拽中（directEventEditing 插件拖拽期间为 true；
--- 侧边栏 event 页此时不记录撤销，由插件在松手时统一写入一条记录）
editState.draggingEvent = false

return editState
