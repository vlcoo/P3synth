int snap_number(int num, int mult) {
    if (mult == 0) return num;
    return ((num + mult - 1) / mult) * mult;
}


String check_and_shrink_string(String original, int max_len) {
     if (original.length() > max_len) original = original.substring(0, max_len - 1) + "…";
     return original;
}


class ThemeEngine {
    HashMap<String, int[]> available_themes = new HashMap<String, int[]>();
    int[] theme;
    String curr_theme_name;


    ThemeEngine() {
        load_themes();
    }
    
    
    void set_theme(String theme_name) {
        theme = available_themes.get(theme_name);
        if (theme == null) theme = available_themes.get("Fresh Blue");
        else curr_theme_name = theme_name;
    }


    private void load_themes() {
        // theme is an array of ints (colors in hex) in order: darker, dark, neutral, light, lightest
        int[] theme_01 = {#000000, #5151cf, #809fff, #bfcfff, #ffffff};
        available_themes.put("Fresh Blue", theme_01);
        int[] theme_03 = {#000000, #d50000, #ff5131, #ff867c, #ffffff};
        available_themes.put("Hot Red", theme_03);
        int[] theme_04 = {#000000, #00b248, #00e676, #66ffa6, #ffffff};
        available_themes.put("Crisp Green", theme_04);
        int[] theme_06 = {#000000, #c6a700, #fdd835, #ffff6b, #ffffff};
        available_themes.put("Summer Yellow", theme_06);
        int[] theme_02 = {#5c1f09, #b2593f, #df825f, #ffd2a2, #ffffff};
        available_themes.put("GX Peach", theme_02);
        int[] theme_05 = {#000000, #777777, #aaaaaa, #444444, #ffffff};
        available_themes.put("Metallic Grayscale", theme_05);
    }
}



class KeyTransformer {
    HashMap<String, int[]> available_transforms = new HashMap<String, int[]>();
    int[] transform;
    
    KeyTransformer() {
        load_transforms();
        set_transform("None");
    }
    
    
    void set_transform(String name) {
        transform = available_transforms.get(name);
        if (transform == null) {
            transform = available_transforms.get("None");
        }
    }
    
    
    private void load_transforms() {
        int[] tr_01 = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
        available_transforms.put("None", tr_01);
        int[] tr_02 = {0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0};
        available_transforms.put("Major", tr_02);
        int[] tr_03 = {0, 0, 0, 0, -1, 0, 0, 0, 0, -1, 0, -1};
        available_transforms.put("Minor", tr_03);
    }
}


void show_help_topic(String which) {
    switch (which.charAt(0)) {
        case '1':
        ui.showInfoDialog("one", "a");
        break;
        
        case '2':
        ui.showInfoDialog("two", "a");
        break;
        
        case '3':
        ui.showInfoDialog("three", "a");
        break;
        
        case '4':
        ui.showInfoDialog("four", "a");
        break;
        
        case '5':
        ui.showInfoDialog("five", "a");
        break;
    }
}


int[] major_rootnotes = {
    12, 5, 1, 8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1
};

int[] minor_rootnotes = {
    8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1, 8, 3, 10
};


float[] prog_osc_relationship = {
    2, 1, 1, .25, .75, .25, .125, .125, .75, 1, 1, 1, 1, .25,
    .125, .125, 1, 1, 1, .5, .5, .125, .5, .125, 2, 1, 2,
    .125, 1, .125, .125, 3, 1, 1, 3, 1, 1, 1, 1, 1, 3, 3,
    3, .5, 3, 2, 1, 1, 3, .5, .5, .5, 1, 1, .25, .25, .125,
    .125, .125, .75, .25, .25, .25, .75, .25, .25, .25, .75,
    1, .25, .25, 2, 1, 2, 2, 1, .25, .25, 1, 2, .5, 3, .25,
    .5, .125, .125, .5, 1, .125, .5, .5, .5, .75, .125, .5,
    .25, .125, .75, .125, .5, .5, .125, 1, .125, .125, .125,
    .125, .75, .125, .125, 1, 1, .25, 4, 4, 4, 4, 4, 4, 4,
    4, 4, 4, 4, 4, 4, 4, 4
};

float program_to_osc(int prog) {
    return prog_osc_relationship[prog];
}


float[][] prog_env_relationship = {
    {1.2, 3}, {3, 9.1}
};

float[] program_to_env(int prog) {
    return prog_env_relationship[prog];
}


// 1 → closed hihat, 2 → open hihat, 3 → snare, 4 → tom
int[] notecode_perc_relationship = {
    4, 4, 4, 3, 3, 3, 4, 1, 4, 1, 4, 2,
    4, 4, 2, 4, 2, 2, 1, 3, 2, 1, 2, 4,
    3, 3, 3, 2, 2, 2, 3, 1, 4, 4, 2, 1,
    3, 4, 1, 2, 3, 2, 3, 4, 1, 2, 3
};

int note_code_to_percussion(int note_code) {
    return notecode_perc_relationship[constrain(note_code, 35, 81) - 35];
}
