utf8 = require("utf8")
socket = require("socket") --网络通信
ffi = require("ffi") --调用C语言库
nuklear = require 'nuklear' --图形界面
serpent = require("src.utils.serpent") --lua序列化
require("src.utils.room")

require("src.utils.music")
beat = require("src.utils.beat")
fEvent = require("src.utils.event")
fNote = require("src.utils.note")

require("src.utils.log")
require("src.utils.string")
require("src.utils.table")
require("src.utils.save")
nativefs = require("src.utils.nativefs")
dkjson = require("src.utils.dkjson")
require("src.utils.mc_to_dakumi")
easings = require('src.utils.easings')
require("src.utils.bezier")
require("src.utils.math")
fTrack = require("src.utils.track")



--属于main
require('src.objects.messageBox')
require('src/objects.i18n')
require('src.objects.allImage')
require('src/objects/meta')




require("src.rooms.edit")

require("src.rooms.menu")

require("src.rooms.start")
