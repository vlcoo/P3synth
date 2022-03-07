class ThemeEngine {
    HashMap<String, int[]> available_themes = new HashMap<String, int[]>();
    int[] theme;


    ThemeEngine(String theme_name) {
        load_themes();
        set_theme(theme_name);
    }
    
    
    void set_theme(String theme_name) {
        theme = available_themes.get(theme_name);
        if (theme == null) {
            theme = available_themes.get("Fresh Blue");
        }
    }


    private void load_themes() {
        // theme is an array of ints (colors in hex) in order: darker, dark, neutral, light, lightest
        int[] theme_01 = {#001247, #3c3cb0, #809fff, #bfcfff, #ffffff};
        available_themes.put("Fresh Blue", theme_01);
        int[] theme_03 = {#7d0000, #cc0000, #ff3333, #ffb3b3, #ffffff};
        available_themes.put("Hot Red", theme_03);
        int[] theme_04 = {#6bb36b, #99ff99, #ccffcc, #e6ffe6, #000000};
        available_themes.put("Crispy Green", theme_04);
        int[] theme_02 = {#5c1f09, #b2593f, #df825f, #ffd2a2, #ffffff};
        available_themes.put("GX Peach", theme_02);
    }
}

float[] prog_osc_relationship = {
    2, 1, 1, 0.5, 0.5, 0.5, 0.3, 0.3, 0.3, 1, 1, 1, 1, 0.5,
    0.3, 0.3, 1, 1, 1, 0.7, 0.7, 0.3, 0.7, 0.3, 2, 1, 2,
    0.3, 1, 0.3, 0.3, 3, 1, 1, 3, 1, 1, 1, 1, 1, 3, 3,
    3, 0.7, 3, 2, 1, 1, 3, 0.7, 0.7, 0.7, 1, 1, 0.5,
    0.5, 0.3, 0.3, 0.3, 0.3, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5,
    0.5, 0.3, 1, 0.5, 0.5, 2, 1, 2, 2, 1, 0.5, 0.5, 1, 2,
    0.7, 3, 0.5, 0.7, 0.3, 0.3, 0.7, 1, 0.3, 0.7, 0.7,
    0.7, 0.3, 0.3, 0.7, 0.5, 0.3, 0.5, 0.3, 0.7, 0.7, 0.3, 1,
    0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 1, 1, 0.5, 0.7, 1, 1,
    1, 1, 2, 0.7, 0.7, 0.3, 0.5, 0.7, 1, 3, 0.3, 0.3
};

float program_to_osc(int prog) {
    return prog_osc_relationship[prog];
}


float[] program_to_env(int prog) {
    // attack time, sustain time, release time
    return null;
}


String[] notecode_perc_relationship = {
    "Tom", "Tom", "Tom", "Snare", "Snare", "Snare", "Tom",
    "Closed hihat", "Tom", "Closed hihat", "Tom", "Open hihat",
    "Tom", "Tom", "Open hihat", "Tom", "Open hihat", "Open hihat",
    "Closed hihat", "Snare", "Open hihat", "Closed hihat",
    "Open hihat", "Tom", "Snare", "Snare", "Snare", "Open hihat",
    "Open hihat", "Closed hihat", "Open hihat", "Snare", "Tom",
    "Closed hihat", "Open hihat", "Snare", "Tom", "Closed hihat",
    "Open hihat", "Snare", "Tom", "Closed hihat", "Open hihat",
    "Snare", "Tom", "Closed hihat", "Open hihat"
};

String note_code_to_percussion(int note_code) {
    return notecode_perc_relationship[constrain(note_code, 35, 81) - 35];
}
