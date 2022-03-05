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


float program_to_osc(int prog) {
    if (prog >= 1 && prog <= 8) return 1;
    if (prog >= 9 && prog <= 16) return 2;
    if (prog >= 17 && prog <= 24) return 0.7;
    if (prog >= 25 && prog <= 32) return 1;
    if (prog >= 33 && prog <= 40) return 0.5;
    if (prog >= 41 && prog <= 48) return 3;
    if (prog >= 49 && prog <= 56) return 3;
    if (prog >= 57 && prog <= 64) return 3;
    return 0.25;
}


float[] program_to_env(int prog) {
    // attack time, sustain time, release time
    return new float[] {0.01, 1, 0.01};
}
