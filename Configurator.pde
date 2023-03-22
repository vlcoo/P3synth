import java.util.prefs.Preferences;

Preferences prefs;
int snap_loop_mult = 0;
int snap_pos_mult = 0;
int knob_sensitivity = 40;
boolean remaining_instead_of_elapsed = false;
ChannelDisplayTypes channel_disp_type;
HashMap<String, Integer> media_keys = new HashMap<>();
String mk_setup = "";


void setup_config() {
    prefs = Preferences.userRoot().node("com.vlcoo.p3synth");
    
    is_newbie = prefs.getBoolean("new user", true);
    if (prefs.getBoolean("low framerate", false)) frameRate(30);
    else frameRate(75);
    t.set_theme(prefs.get("theme", "Fresh Blue"));
    
    switch (prefs.get("visualization style", "VU windows")) {
        case "VU windows":
            channel_disp_type = ChannelDisplayTypes.ORIGINAL;
            set_small_height(false);
            break;
        case "Vertical bars":
            channel_disp_type = ChannelDisplayTypes.VERTICAL_BARS;
            set_small_height(false);
            break;
        default:
            channel_disp_type = ChannelDisplayTypes.NONE;
            set_small_height(true);
            break;
    }
    
    String p = prefs.get("loop snap", "Yes (fine)");
    snap_loop_mult = p.equals("No") ? 0 : p.equals("Yes (coarse)") ? 4 : 2;
    remaining_instead_of_elapsed = prefs.getBoolean("remaining timer", false);
    p = prefs.get("pos snap", "No");
    snap_pos_mult = p.equals("Yes (fine)") ? 2 : p.equals("Yes (coarse)") ? 4 : 0;
    
    if (prefs.getBoolean("remember", true)) retrieve_control_memory();
    load_media_keys();
}


void load_media_keys() {
    media_keys.put("play", Integer.parseInt(prefs.get("media play", "0")));
    media_keys.put("pause", Integer.parseInt(prefs.get("media pause", "0")));
    media_keys.put("back", Integer.parseInt(prefs.get("media back", "0")));
    media_keys.put("forward", Integer.parseInt(prefs.get("media forward", "0")));
    media_keys.put("stop", Integer.parseInt(prefs.get("media stop", "0")));
}


void store_control_memory() {
    if (player == null) return;
    prefs.putBoolean("remember synth", player.system_synth);
    prefs.putBoolean("remember opened queue", win_plist != null && win_plist.isLooping());
}


void retrieve_control_memory() {
    if (prefs.getBoolean("remember opened queue", false)) toggle_playlist_win();
}


void open_config_dialog() {
    if (dialog_settings != null) dialog_settings.close();
    
    dialog_settings = ui.createForm("Settings")
    .addSelection(
        "Theme",
        new ArrayList(t.available_themes.keySet())
    )
    .addSelection(
        "Visualization style",
        Arrays.asList("None", "VU windows", "Vertical bars")
    )
    .addSelection(
        "VU meter decay rate",
        Arrays.asList("Slow", "Smooth", "Instant")
    )
    .addCheckbox("Reduce framerate *")
    .addCheckbox("Always remember mode and opened panes *")
    .addText("Default soundfont for system synth *")
    .addCheckbox("Autoload SF with same name as MIDI")
    .addSelection(
        "Snap loop points to beat",
        Arrays.asList("No", "Yes (fine)", "Yes (coarse)")
    )
    .addSelection(
        "Snap setting song position to beat",
        Arrays.asList("No", "Yes (fine)", "Yes (coarse)")
    )
    .addCheckbox("Show remaining time instead of elapsed")
    .addCheckbox("Adding folder to playlist is recursive")
    .addCheckbox("Adding folder to playlist clears it first")
    .addCheckbox("Listen to media keys globally *")
    .addSelection(
        "Knob control sensitivity",
        Arrays.asList("Low", "Medium", "High")
    )
    .addSelection(
        "Share Discord activity",
        Arrays.asList("No", "Yes (private)", "Yes (detailed)")
    )
    .addLabel("* The options marked will apply after restart.")
    .setCloseListener(new FormCloseListener() { public void onClose(Form form) {
        String th = form.getByIndex(0).asString();
        String vs = form.getByIndex(1).asString();
        String md = form.getByIndex(2).asString();
        boolean lf = (boolean) form.getByIndex(3).getValue();
        boolean re = (boolean) form.getByIndex(4).getValue();
        String sf = form.getByIndex(5).asString();
        boolean al = (boolean) form.getByIndex(6).getValue();
        String snl = form.getByIndex(7).asString();
        String snp = form.getByIndex(8).asString();
        boolean rt = (boolean) form.getByIndex(9).getValue();
        boolean rf = (boolean) form.getByIndex(10).getValue();
        boolean cf = (boolean) form.getByIndex(11).getValue();
        boolean mk = (boolean) form.getByIndex(12).getValue();
        String ks = form.getByIndex(13).asString();
        String da = form.getByIndex(14).asString();
        
        prefs.put("theme", th);
        prefs.putBoolean("low framerate", lf);
        prefs.putBoolean("remember", re);
        prefs.put("sf path", sf);
        prefs.putBoolean("autoload sf", al);
        prefs.put("loop snap", snl);
        prefs.put("pos snap", snp);
        prefs.putBoolean("remaining timer", rt);
        prefs.putBoolean("recursive folder", rf);
        prefs.putBoolean("replace playlist", cf);
        prefs.put("knob sensitivity", ks);
        prefs.put("discord rpc", da);
        
        t.set_theme(th);
        if (!vs.equals(prefs.get("visualization style", "VU windows")) || !md.equals(prefs.get("meter decay", "Smooth"))) {
            switch (vs) {
                case "VU windows":
                    channel_disp_type = ChannelDisplayTypes.ORIGINAL;
                    player.create_visualizer();
                    for (ChannelOsc c : player.channels) { 
                        ((ChannelDisplayOriginal)(c.disp)).recalc_quickness(md);
                    } 
                    set_small_height(false);
                    break;
                case "Vertical bars":
                    channel_disp_type = ChannelDisplayTypes.VERTICAL_BARS;
                    player.create_visualizer();
                    for (ChannelOsc c : player.channels) { 
                        ((ChannelDisplayVBars)(c.disp)).recalc_quickness(md);
                    } 
                    set_small_height(false);
                    break;
                default:
                    channel_disp_type = ChannelDisplayTypes.NONE;
                    player.create_visualizer();
                    set_small_height(true);
                    break;
            }
        }
        prefs.put("visualization style", vs);
        prefs.put("meter decay", md);
        
        snap_loop_mult = snl.equals("No") ? 0 : snl.equals("Yes (coarse)") ? 8 : 2;
        snap_pos_mult = snp.equals("Yes (fine)") ? 2 : snp.equals("Yes (coarse)") ? 8 : 0;
        remaining_instead_of_elapsed = rt;
        knob_sensitivity = ks.equals("High") ? 20 : ks.equals("Low") ? 80 : 40;
        if (da.equals("No")) DiscordRPC.discordShutdown();
        else beginDiscordActivity();
        
        if (prefs.getBoolean("media keys", false) != mk && mk) setup_media_keys();
        prefs.putBoolean("media keys", mk);
    }})
    .run();
    
    dialog_settings.getByIndex(0).setValue(prefs.get("theme", "Fresh Blue"));
    dialog_settings.getByIndex(1).setValue(prefs.get("visualization style", "VU windows"));
    dialog_settings.getByIndex(2).setValue(prefs.get("meter decay", "Smooth"));
    dialog_settings.getByIndex(3).setValue(prefs.getBoolean("low framerate", false));
    dialog_settings.getByIndex(4).setValue(prefs.getBoolean("remember", true));
    dialog_settings.getByIndex(5).setValue(prefs.get("sf path", ""));
    dialog_settings.getByIndex(6).setValue(prefs.getBoolean("autoload sf", true));
    dialog_settings.getByIndex(7).setValue(prefs.get("loop snap", "Yes (fine)"));
    dialog_settings.getByIndex(8).setValue(prefs.get("pos snap", "No"));
    dialog_settings.getByIndex(9).setValue(prefs.getBoolean("remaining timer", false));
    dialog_settings.getByIndex(10).setValue(prefs.getBoolean("recursive folder", false));
    dialog_settings.getByIndex(11).setValue(prefs.getBoolean("replace playlist", true));
    dialog_settings.getByIndex(12).setValue(prefs.getBoolean("media keys", false));
    dialog_settings.getByIndex(13).setValue(prefs.get("knob sensitivity", "Medium"));
    dialog_settings.getByIndex(14).setValue(prefs.get("discord rpc", "No"));
    
    dialog_settings.getWindow().setSize(300, 880);
}
