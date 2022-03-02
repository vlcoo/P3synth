class ThemeEngine {
    HashMap<String, int[]> available_themes = new HashMap<String, int[]>();
    int[] theme;


    ThemeEngine(String theme_name) {
        load_themes();
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
        available_themes.put("Original GX", theme_02);
    }
}
