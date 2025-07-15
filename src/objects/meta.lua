meta_chart = { --谱面基本格式 元表
    __index ={
        bpm_list = {
            {beat = {0,0,1},bpm = 120},
        },
        note = {},
        event = {},
        effect = {},
        offset = 0 ,
        info = {
            song_name = [[]],
            chart_name = [[]],
            chartor = [[]],
            artist = [[]],
        },
        preference = {
            x_offset = 0,
        },
        track = {}
    }
}
meta_settings = { --设置基本格式 元表
    __index ={
        
        judge_line_y = 700,
        music_volume = 100,
        hit_volume = 100,
        hit = 0,
        hit_sound = 0,
        track_w_scale = 8,
        language= 1,
        contact_roller = 1, --鼠标滚动系数
        note_height = 75,
        bg_alpha = 50,
        denom_alpha = 70,
        window_width = WINDOW.w,
        window_height = WINDOW.h,
        auto_save = 1, --自动保存,
    }
}
function info_to_load(obj)
    return obj.x,obj.y ,obj.r,obj.w,obj.h
end
info = {
    select = {
        button_todakumi_in_select = {x = 850,y = 0,r = 0,w = 25,h = 25},
        button_togithub_in_select = {x = 850,y = 25,r = 0,w = 25,h = 25},
        edit_chart = {x = 0,y = 750,r = 0,w = 100,h = 50},
        delete_chart = {x = 100,y = 750,r = 0,w = 100,h = 50},
        new_chart = {x = 200,y = 750,r = 0,w = 100,h = 50},

        file_selection_dialog_box = {x = 1100,y = 0,r = 0,w = 100,h = 50},
        flushed = {x = 1200,y = 0,r = 0,w = 100,h = 50},
        export = {x = 1300,y = 0,r = 0,w = 100,h = 50},
        delete_music = {x = 1400,y = 0,r = 0,w = 100,h = 50},
        open_directory = {x = 1500,y = 0,r = 0,w = 100,h = 50},
    },
    edit_tool = {
        x = 0,
        y = 0,
        w = 1220-5,
        h = 100,
        note_fake = {x = 100,y = 25,r = 0,w = 25,h = 25},
        music_speed = {x = 575,y = 50,r = 0,w = 25,h = 25},
        denom = {x = 875,y = 50,r = 0,w = 25,h = 25},
        track = {x = 725,y = 50,r = 0,w = 25,h = 25},
        track_scale = {x = WINDOW.h,y = 50,r = 0,w = 25,h = 25},
        track_fence = {x = 650,y = 50,r = 0,w = 25,h = 25},
        music_play = {x = 400,y = 50,r = 0,w = 50,h = 50},
        note = {x = 400,y = 50,r = 0,w = 50,h = 16.6},
        save = {x = 50,y = 50,r = 0,w = 50,h = 50},
        slider = {x = 0,y = 100,r = 0,w = 20,h = 700},
    },
    play = {
        play_alea = {x = 0,y = 0,r = 0,w = 900,h = WINDOW.h},
        track = {x = 900,y = 0,r = 0,w = 275,h = WINDOW.h,one_track_w = 75,interval = 100}, --侧边的三个轨道
    }
}
