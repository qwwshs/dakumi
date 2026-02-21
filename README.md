# dakumi
![dakumi](icon.ico)

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/qwwshs/dakumi)
![Love2D](https://img.shields.io/badge/Love2D-11.4-E06C75.svg)
![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)
## 概述

dakumi是由qwwshs用`love2d`所制造的TAKUMI³谱面饭制器

dakumi文档请于[dakumi](http://dakumi.qwwshs.top)中访问

这是qwwshs的个人群(QQ):`865149292` 若对该项目感兴趣或有什么疑问可以添加群聊(需要回答问题)

## 构建

* 平台要求：Windows (Windows10可用 其他Windows版本或平台不清楚)

首先 请前往[love2d](https://love2d.org)中下载love2d的源文件

> [!TAP]
> dakumi所使用的love2d版本为11.4 
> 为了支持中文输入法 dakumi所使用的SDL2.dll是经过修改的

然后将dakumi打包成以下结构的zip:

```
dakumi.zip/
│
├── 📁 assets/          
├── 📁 config/          
├── 📁 src/            
│
├── 📄 icon.ico        
├── 📄 main.lua        
├── 📄 conf.lua        
└── 📄 isRequire.lua        
```

之后将其改名为`dakumi.love`

然后将`dakumi.love`与`love.exe`放入同一文件夹 在命令行中输入以下命令：

```bat
copy /b love.exe+dakumi.love dakumi.exe
```

构建完毕

## 依赖

- [LxgwNeoXiHei](https://github.com/lxgw/LxgwNeoXiHei)

- [love2d](https://github.com/love2d/love)

- [dkjson](https://github.com/LuaDist/dkjson)

- [fileselect](https://github.com/bili-fule/fileselect)

- [serpent](https://github.com/pkulchenko/serpent)

- [LÖVE-Nuklear](https://github.com/keharriso/love-nuklear)

- [7zip](https://github.com/ip7z/7zip)

- [yaml](https://github.com/exosite/lua-yaml)

- [moonshine](https://github.com/vrld/moonshine)

- [hump](https://github.com/vrld/hump)

- [lovefft](https://github.com/Gennadiyev/lovefft)

## 开源许可

dakumi遵循宽松的MIT协议
```LICENSE
Copyright <2025> <qwwshs>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```