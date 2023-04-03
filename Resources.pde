import com.github.kwhat.jnativehook.GlobalScreen;
import com.github.kwhat.jnativehook.NativeHookException;
import com.github.kwhat.jnativehook.keyboard.NativeKeyEvent;
import com.github.kwhat.jnativehook.keyboard.NativeKeyListener;


int snap_number(int num, int mult) {
    if (mult == 0) return num;
    return ((num + mult - 1) / mult) * mult;
}


float snap_number(float num, float mult) {
    if (mult == 0) return num;
    return ((num + mult - 1) / mult) * mult;
}


String check_and_shrink_string(String original, int max_len, boolean use_alt_ellipses) {
    if (max_len < 1) return (use_alt_ellipses ? "..." : "…");
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


class MediaKeysListener implements NativeKeyListener {
    public void nativeKeyPressed(NativeKeyEvent e) {
        if (!mk_setup.equals("")) {
            prefs.put("media " + mk_setup, String.valueOf(e.getRawCode()));
            return;
        }
        
        if (player.playing_state == -1) return;
        
        if (media_keys.get("play").equals(media_keys.get("pause"))) {
            if (e.getRawCode() == media_keys.get("play")) {
                Button b = media_buttons.get_button("Pause");
                player.set_playing_state( b.pressed ? 1 : 0 );
                return;
            }
        }
        else {
            if (e.getRawCode() == media_keys.get("play")) {
                player.set_playing_state(1);
                return;
            }
            if (e.getRawCode() == media_keys.get("pause")) {
                player.set_playing_state(0);
                return;
            }
        }
        
        if (win_plist != null) {
            if (e.getRawCode() == media_keys.get("back")) {
                win_plist.previous();
                return;
            }
            if (e.getRawCode() == media_keys.get("forward")) {
                win_plist.next();
                return;
            }
        }
        
        if (e.getRawCode() == media_keys.get("stop")) {
            player.set_playing_state(-1);
            if (win_plist != null) win_plist.set_current_item(-1);
            return;
        }
    }
}

final String[] NOTE_NAMES = new String[] {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};

int[] major_rootnotes = {
    2, 9, 4, 11, 6, 1, 8, 3, 10, 5, 0, 7, 2, 9, 4
};

int[] minor_rootnotes = {
    11, 6, 1, 8, 3, 10, 5, 0, 7, 2, 9, 4, 11, 6, 1
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


ChannelDisplay get_new_display(ChannelDisplayTypes type, int id, ChannelOsc obj) {
    switch (type) {
        case VUWindows:
            return new ChannelDisplayVUWindows(id, obj);
        case VerticalBars:
            return new ChannelDisplayVerticalBars(id, obj);
        // ← Add more cases as needed here...
        default:
            println("P3synth warning: an invalid visualizer was found in user's settings.");
            prefs.put("viz style v2", "None");
        case None:
            return new ChannelDisplayNone(id, obj);
    }
}


HashMap<String, int[]> key_transforms = new HashMap<String, int[]>();

Sequence transform_sequence(Sequence og_seq, int[] new_key) {
    if (player.seq == null || player.playing_state == -1) return null;
    
    player.set_playing_state(0);
    for (Track track : og_seq.getTracks()) {
        for (int i = 0; i < track.size(); i++) {
            MidiMessage msg = track.get(i).getMessage();
            if (!(msg instanceof ShortMessage)) continue;
            
            ShortMessage event = (ShortMessage)msg;
            if (event.getChannel() != 9 && (event.getCommand() == ShortMessage.NOTE_ON || event.getCommand() == ShortMessage.NOTE_OFF)) { 
                try {
                    int new_note = event.getData1() + new_key[(event.getData1() - 2 + player.mid_rootnote) % 12];
                    event.setMessage(event.getCommand(), event.getChannel(), new_note, event.getData2());
                }
                catch (InvalidMidiDataException imde) {
                    println("imde on transform");
                }
            }
        }
    }
    
    player.set_playing_state(1);
    return og_seq;
}
