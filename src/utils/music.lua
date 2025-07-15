function get_music_type(file)  --得到后缀
    local header = file:read(12)  -- 读取前12个字节  
    file:close()  

    if not header then  
        return nil
    end  

    -- 判断文件类型  
    if header:sub(1, 3) == "Ijson" or (header:byte(1) == 0xFF and bit.band(header:byte(2), 0xE0) == 0xE0) then  
        return "mp3"  
    elseif header:sub(1, 4) == "RIFF" and header:sub(9, 12) == "WAVE" then  
        return "wav"  
    elseif header:sub(1, 4) == "OggS" then  -- OGG 文件以"OggS"开头  
        return "ogg"  
    else  
        return nil
    end  
end  
