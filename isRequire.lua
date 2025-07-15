utf8 = require("utf8")
socket = require("socket") --网络通信
ffi = require("ffi") --调用C语言库
nuklear = require 'nuklear' --图形界面
fileselect = ffi.load("fileselect")

serpent = require("src.utils.serpent") --lua序列化
require("src.utils.room")
require("src.utils.music")
require("src.utils.beat_and_time")
require("src.utils.log")
require("src.utils.string")
require("src.utils.table")
require("src.utils.save")
nativefs = require("src.utils.nativefs")
dkjson = require("src.utils.dkjson")
require("src.utils.mc_to_dakumi")
easings = require('src.utils.easings')
require("src.utils.input_box")
require("src.utils.button")
require("src.utils.bezier")
require("src.utils.math")
require("src.utils.switch")
ui_style = require("src.utils.ui_style")
require("src.utils.track")
require("src.utils.note")
require("src.utils.event")

--属于main
require('src.objects.messageBox')
require('src/objects.i18n')
require('src/objects/ui')
require('src/objects/meta')




require("src.rooms.edit")
    require("src/objects/play/note")
    require("src/objects/play/note_edit_inplay")
    require('src/objects/play/demo_in_play')
    require("src/objects/play/alt_note_event")
    require("src/objects/play/event")
    require("src/objects/play/hit")
    require('src/objects/play/copy')
    require('src/objects/play/redo')
    require('src/objects/play/demo_mode')
    require('src/objects/play/denom_play')
    require('src/objects/play/note_play_in_edit')
    require('src/objects/play/demo_now_x_pos')

    
    require('src/objects/sidebar/button_break')

    require('src/objects/sidebar/button_chart_info')
        require('src/objects/sidebar/chart_info')
            require('src/objects/sidebar/button_bpm_list')

    require('src/objects/sidebar/button_preference')
    require('src/objects/sidebar/preference')

    require('src/objects/sidebar/note_edit')

    require('src/objects/sidebar/event_edit')
        require('src/objects/sidebar/event_edit_bezier')
        require('src/objects/sidebar/button_event_edit_default_bezier')

    require('src/objects/sidebar/events_edit')

    require('src/objects/sidebar/button_settings')
        require('src/objects/sidebar/settings')

    require('src/objects/sidebar/button_to_github')

    require('src/objects/sidebar/button_to_dakumi')

    require('src/objects/sidebar/button_tracks_edit')
        require('src/objects/sidebar/tracks_edit')

    require('src/objects/sidebar/button_track')
        require('src/objects/sidebar/track_sidebar')
        
    require('src/objects.editTool.slider')

require("src.rooms.menu")

require("src.rooms.tracks_edit")

require("src.rooms.start")
