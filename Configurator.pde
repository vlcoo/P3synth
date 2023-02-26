import java.util.prefs.Preferences;

Preferences prefs;
int snap_loop_mult = 0;
int snap_pos_mult = 0;
int knob_sensitivity = 40;
boolean remaining_instead_of_elapsed = false;
ChannelDisplayTypes channel_disp_type = ChannelDisplayTypes.ORIGINAL;


void setup_config() {
    prefs = Preferences.userRoot().node("com.vlcoo.p3synth");
    
    is_newbie = prefs.getBoolean("new user", true);
    if (prefs.getBoolean("low framerate", false)) frameRate(30);
    else frameRate(75);
    t.set_theme(prefs.get("theme", "Fresh Blue"));
    
    String p = prefs.get("loop snap", "Yes (fine)");
    snap_loop_mult = p.equals("No") ? 0 : p.equals("Yes (coarse)") ? 4 : 2;
    remaining_instead_of_elapsed = prefs.getBoolean("remaining timer", false);
    p = prefs.get("pos snap", "No");
    snap_pos_mult = p.equals("Yes (fine)") ? 2 : p.equals("Yes (coarse)") ? 4 : 0;
    
    if (prefs.getBoolean("remember", true)) retrieve_control_memory();
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
    .addSelection(
        "Knob control sensitivity",
        Arrays.asList("Low", "Medium", "High")
    )
    .addSelection(
        "Share Discord activity",
        Arrays.asList("No", "Yes (private)", "Yes (detailed)")
    )
    .addLabel("* The options marked will have effect only on startup.")
    .setCloseListener(new FormCloseListener() { public void onClose(Form form) {
        String th = form.getByIndex(0).asString();
        String md = form.getByIndex(1).asString();
        boolean lf = (boolean) form.getByIndex(2).getValue();
        boolean re = (boolean) form.getByIndex(3).getValue();
        String sf = form.getByIndex(4).asString();
        boolean al = (boolean) form.getByIndex(5).getValue();
        String snl = form.getByIndex(6).asString();
        String snp = form.getByIndex(7).asString();
        boolean rt = (boolean) form.getByIndex(8).getValue();
        boolean rf = (boolean) form.getByIndex(9).getValue();
        boolean cf = (boolean) form.getByIndex(10).getValue();
        String ks = form.getByIndex(11).asString();
        String da = form.getByIndex(12).asString();
        
        prefs.put("theme", th);
        prefs.put("meter decay", md);
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
        switch (channel_disp_type) {
            case ORIGINAL:
                for (ChannelOsc c : player.channels) { 
                    ((ChannelDisplayOriginal)(c.disp)).recalc_quickness_from_settings();
                } 
                break;
            case VERTICAL_BARS:
                for (ChannelOsc c : player.channels) { 
                    ((ChannelDisplayVBars)(c.disp)).recalc_quickness_from_settings();
                } 
                break;
            default:
                break;
        }
        snap_loop_mult = snl.equals("No") ? 0 : snl.equals("Yes (coarse)") ? 8 : 2;
        snap_pos_mult = snp.equals("Yes (fine)") ? 2 : snp.equals("Yes (coarse)") ? 8 : 0;
        remaining_instead_of_elapsed = rt;
        knob_sensitivity = ks.equals("High") ? 20 : ks.equals("Low") ? 80 : 40;
        if (da.equals("No")) DiscordRPC.discordShutdown();
        else beginDiscordActivity();
    }})
    .run();
    
    dialog_settings.getByIndex(0).setValue(prefs.get("theme", "Fresh Blue"));
    dialog_settings.getByIndex(1).setValue(prefs.get("meter decay", "Smooth"));
    dialog_settings.getByIndex(2).setValue(prefs.getBoolean("low framerate", false));
    dialog_settings.getByIndex(3).setValue(prefs.getBoolean("remember", true));
    dialog_settings.getByIndex(4).setValue(prefs.get("sf path", ""));
    dialog_settings.getByIndex(5).setValue(prefs.getBoolean("autoload sf", true));
    dialog_settings.getByIndex(6).setValue(prefs.get("loop snap", "Yes (fine)"));
    dialog_settings.getByIndex(7).setValue(prefs.get("pos snap", "No"));
    dialog_settings.getByIndex(8).setValue(prefs.getBoolean("remaining timer", false));
    dialog_settings.getByIndex(9).setValue(prefs.getBoolean("recursive folder", false));
    dialog_settings.getByIndex(10).setValue(prefs.getBoolean("replace playlist", true));
    dialog_settings.getByIndex(11).setValue(prefs.get("knob sensitivity", "Medium"));
    dialog_settings.getByIndex(12).setValue(prefs.get("discord rpc", "No"));
    
    dialog_settings.getWindow().setSize(300, 760);
}
