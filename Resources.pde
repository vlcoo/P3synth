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


void show_help_topic(char which) {
    switch (which) {
        case '1':
        ui.showInfoDialog(
            "- The only thing you need to know: drag and drop a valid " +
            "MIDI file (usual extension: .mid) into the main window of " +
            "P3synth to play it. If you need help discovering other features, " +
            "I invite you to keep reading.\n\n" +
            
            "- The three topmost buttons on the left control playback of the song." +
            "\n   · Replaying will start the current song from the beginning.\n   · " +
            "Pausing will temporarily stop the song until the Pause button is pressed " +
            "a second time.\n   · Stopping will unload the file.\n\n" +
            
            "- The bar on the bottom left shows the song's current position in "+
            "minutes and seconds, as well as the total length. Clicking on any part " +
            "of the bar will skip the song to that position in time.\n   · The looping function" +
            " can be toggled, and will restart the song when reaching the end instead " +
            "of stopping.\n   · While looping is enabled, the starting and ending points of " +
            "the loop are controlled by the sliding ticks above and below the position bar.\n\n" +
            
            "- The other bar, on the bottom right, displays some text in real time. " +
            "This text is contained in the MIDI file itself, and might contain lyrics or " +
            "other comments.\n   · Clicking on the bar itself will show the history of " +
            "this stream of text.\n   · The metadata button will display additional information" +
            "such as author, copyright, date... if available.\n\n",
            "Basic usage");
        break;
        
        case '2':
        ui.showInfoDialog(
            "- While playing a MIDI sequence, the events get logged and displayed in a " +
            "variety of ways. Currently, the most common, but not all, MIDI messages are supported." +
            "\n\n" +
            
            "- Every one of the 16 channels have their own display area. The ID is shown at the " +
            "top left corner of it (on top of the X mute button).\n\n" +
            
            "- Roughly in the middle, a simulated 'VU meter' shows the total volume of the " +
            "entire channel.\n   · Right below it, a bar shows the Expression value.\n\n" +
            
            "- From left to right and top to bottom, the 4 squares on the right contain..." +
            "\n   · the last musical note pitch and its Velocity;" +
            " the instrument being used (or the Program Change ID depending on the mode);" +
            " the Pitchbend; and the Stereo Pan.", 
            "Visualization");
        break;
        
        case '3':
        ui.showInfoDialog(
            "wiwi",
            "Advanced usage");
        break;
        
        case '4':
        ui.showInfoDialog(
            "- Adjustments to the behaviour of the program can be made via the Config button " +
            "on the top right.\n\n" +
            
            "Parameters marked with * will have effect on a program restart;" +
            " otherwise, settings will be saved when the Settings dialog is closed.\n   " +
            "· The theme changes the colours of the interface.\n   · *Reducing the framerate " +
            "runs the visuals at a limited 30 FPS instead of 75 FPS.\n   · *Booting with system " +
            "synth enabled will always use the device's instrument bank instead of the " +
            "oscillators.\n   · *Optionally, the path to a custom soundfont file can be given to " +
            "automatically load it on boot.\n   · Snapping to beat helps align the loop or position" +
            " points to the beat/tempo of the song.",
            "Settings");
        break;
        
        case '5':
        ui.showInfoDialog(
            "wawo",
            "Labs dialog");
        break;
        
        case '6':
        ui.showInfoDialog(
            "by me for myself",
            "About project");
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
