return {
    placeNote = {'q'}, --放置note
    placeWipe = {'w'}, --放置wipe
    placeHold = {'e'}, --放置hold
    placeEvent = {'e'}, --#放置event
    delete = {'d'}, --删除note或event
    demo = {'tab'}, --预览或关闭预览
    play = {'space'}, --播放或暂停
    trackUp = {'right'}, --轨道加1
    trackDown = {'left'}, --轨道减1
    denomUp = {'up'}, --节拍分度+1
    denomDown = {'down'}, --节拍分度-1

    select = {'shift'}, --框选确认
    copy = {'ctrl','c'}, --复制
    paste = {'ctrl','v'}, --粘贴
    pasteAll = {'ctrl','a','v'}, --粘贴，包括event
    flipPasteAll = {'ctrl','a','b'}, --取反event粘贴,包括event(为了统一)
    flipPaste = {'ctrl','b'}, --取反event粘贴
    cut = {'ctrl','x'}, --剪切
    accelerate = {'ctrl'}, --滚动加速
 
    deleteSelect = {'ctrl','d'}, --删除所选
    deleteAllSelect = {'ctrl','a','d'}, --删除,包括event的所选
    undo = {'ctrl','z'}, --撤销
    redoing = {'ctrl','y'}, --重做

    save = {'ctrl','s'}, --保存

    flipEvent = {'alt','b'}, --翻转event数值
    cutEventOrHold = {'alt','c'}, --裁切hold或event
    dragHead = {'alt','z'}, --拖头
    dragTail = {'alt','x'}, --拖尾
    adjustEventValue = {'alt','t'}, --调整event数值
    flipUpsideDownEvent = {'alt','u'}, --上下翻转event
}