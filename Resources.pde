int snap_number(int num, int mult) {
    if (mult == 0) return num;
    return ((num + mult - 1) / mult) * mult;
}


float snap_number(float num, float mult) {
    if (mult == 0) return num;
    return ((num + mult - 1) / mult) * mult;
}


String check_and_shrink_string(String original, int max_len, boolean use_alt_ellipses) {
    if (original.length() > max_len) original = original.substring(0, max_len - 1) + (use_alt_ellipses ? "..." : "…");
    return original;
}

String check_and_shrink_string(String original, int max_len) {
     return check_and_shrink_string(original, max_len, false);
}


class ThemeEngine {
    HashMap<String, int[]> available_themes = new HashMap<String, int[]>();
    int[] theme;
    String curr_theme_name;
    boolean is_extended_theme;


    ThemeEngine() {
        load_themes();
    }
    
    
    void set_theme(String theme_name) {
        theme = available_themes.get(theme_name);
        if (theme == null) theme = available_themes.get("Fresh Blue");
        else curr_theme_name = theme_name;
        is_extended_theme = theme.length > 5;
    }


    private void load_themes() {
        // theme is an array of ints (colors in hex) in order: darker, dark, neutral, bright, brigthest, optional
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
        int[] theme_05 = {#000000, #575757, #888888, #cccccc, #ffffff};
        available_themes.put("Metallic Grayscale", theme_05);
        int[] theme_07 = {#0a0c37, #375971, #ff9900, #5cecff, #f4ff61, #ff61c6};
        available_themes.put("Sick Gradient", theme_07);
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
