utf8 = require("utf8")
socket = require("socket")             --网络通信
ffi = require("ffi")                   --调用C语言库
nuklear = require 'nuklear'            --图形界面
serpent = require("src.utils.serpent") --lua序列化
input = require("src.utils.input")   --输入处理
yaml = require("src.utils.yaml")     --YAML解析
timer = require("src.utils.timer")     --计时器

require('src.utils.file')
require('src.utils.pass')

require("src.utils.room")
require('src/objects/meta')

require("src.utils.beat")
fEvent = require("src.utils.event")
fNote = require("src.utils.note")

require("src.utils.log")
require("src.utils.string")
require("src.utils.table")
require("src.utils.save")
nativefs = require("src.utils.nativefs")
dkjson = require("src.utils.dkjson")
easings = require('src.utils.easings')
require("src.utils.bezier")
require("src.utils.math")
fTrack = require("src.utils.track")

--属于main
require('src.objects.messageBox')
require('src/objects.i18n')
require('src.objects.allImage')
ui = require("src.objects.ui")

require("src.rooms.edit")

require("src.rooms.menu")

require("src.rooms.start")

