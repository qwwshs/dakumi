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
        track = {},
        version = 1
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
        language= "zh-CN",
        contact_roller = 1, --鼠标滚动系数
        note_height = 75,
        bg_alpha = 50,
        denom_alpha = 70,
        window_width = WINDOW.w,
        window_height = WINDOW.h,
        auto_save = 1, --自动保存,
    }
}