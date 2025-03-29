utf8 = require("utf8")
socket = require("socket") --网络通信
ffi = require("ffi") --调用C语言库
--nuklear = require 'nuklear' --图形界面
serpent = require("function/serpent") --lua序列化
require("function/music")
require("function/beat_and_time")
require("function/log")
require("function/string")
require("function/table")
require("function/save")
require("function/RGB")
nativefs = require("function/nativefs")
dkjson = require("function/dkjson")
require("function/mc_to_dakumi")
easings = require('function/easings')
require("function/input_box")
require("function/animation")
require("function/button")
require("function/bezier")
require("function/math")
require("function/switch")
ui_style = require("function/ui_style")
require("function/track")
require("function/note")
require("function/event")

--属于main
require("objact/mouse") 
require('objact/message_box')
require('objact/language')
require('objact/ui')
require('objact/meta')





require("room/play")
    require("objact/play/note")
    require("objact/play/note_edit_inplay")
    require('objact/play/demo_in_play')
    require("objact/play/alt_note_event")
    require("objact/play/event")
    require("objact/play/hit")
    require('objact/play/copy')
    require('objact/play/redo')
    require('objact/play/demo_mode')
    require('objact/play/denom_play')
    require('objact/play/note_play_in_edit')
    require('objact/play/demo_now_x_pos')

require("room/sidebar")
    require('objact/sidebar/button_break')

    require('objact/sidebar/button_chart_info')
        require('objact/sidebar/chart_info')
            require('objact/sidebar/button_bpm_list')

    require('objact/sidebar/button_preference')
    require('objact/sidebar/preference')

    require('objact/sidebar/note_edit')

    require('objact/sidebar/event_edit')
        require('objact/sidebar/event_edit_bezier')
        require('objact/sidebar/button_event_edit_default_bezier')

    require('objact/sidebar/events_edit')

    require('objact/sidebar/button_settings')
        require('objact/sidebar/settings')

    require('objact/sidebar/button_to_github')

    require('objact/sidebar/button_to_dakumi')

    require('objact/sidebar/button_tracks_edit')
        require('objact/sidebar/tracks_edit')

    require('objact/sidebar/button_track')
        require('objact/sidebar/track_sidebar')

require("room/edit_tool")
    require('objact/edit_tool/switch_note_fake')
    require("objact/edit_tool/button_denom")
    require("objact/edit_tool/button_music_speed")
    require('objact/edit_tool/button_track_scale')
    require("objact/edit_tool/button_in_play_fence")
    require('objact/edit_tool/button_save')
    require("objact/edit_tool/button_music_play")
    require('objact/edit_tool/button_track')
    require('objact/edit_tool/slider')

require("room/select")
    --require('objact/select/file_selector')
        --require('objact/select/button_selector_break')
        --require('objact/select/button_selector_close')
        --require('objact/select/button_selector_refresh')
        --require('objact/select/button_select_file')
    require('objact/select/button_export')
    require('objact/select/button_flushed')
    require('objact/select/button_delete_chart')
    require('objact/select/button_delete_music')
    require('objact/select/button_open_directory')
    require('objact/select/button_edit_chart')
    require('objact/select/button_new_chart')
    require('objact/select/button_to_dakumi')
    require('objact/select/button_to_github')
    require('objact/select/button_file_selection_dialog_box')

require("room/tracks_edit")

require("room/start")
