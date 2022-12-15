import java.util.prefs.Preferences;

Preferences prefs;
int snap_loop_mult = 0;
int snap_pos_mult = 0;


void setup_config() {
    prefs = Preferences.userRoot().node("com.vlcoo.p3synth");
    
    is_newbie = prefs.getBoolean("new user", true);
    if (prefs.getBoolean("low framerate", false)) frameRate(30);
    else frameRate(75);
    t.set_theme(prefs.get("theme", "Fresh Blue"));
    
    String p = prefs.get("loop snap", "Yes (fine)");
    snap_loop_mult = p.equals("No") ? 0 : p.equals("Yes (coarse)") ? 4 : 2;
    p = prefs.get("pos snap", "No");
    snap_pos_mult = p.equals("Yes (fine)") ? 2 : p.equals("Yes (coarse)") ? 4 : 0;
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
    .addCheckbox("System synth enabled by default *")
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
    .addCheckbox("Adding folder to playlist is recursive")
    .addCheckbox("Adding folder to playlist clears it first")
    .addLabel("* The options marked will have effect only on startup.")
    .setCloseListener(new FormCloseListener() { public void onClose(Form form) {
        String th = form.getByIndex(0).asString();
        String md = form.getByIndex(1).asString();
        boolean lf = (boolean) form.getByIndex(2).getValue();
        boolean ss = (boolean) form.getByIndex(3).getValue();
        String sf = form.getByIndex(4).asString();
        boolean al = (boolean) form.getByIndex(5).getValue();
        String snl = form.getByIndex(6).asString();
        String snp = form.getByIndex(7).asString();
        boolean rf = (boolean) form.getByIndex(8).getValue();
        boolean cf = (boolean) form.getByIndex(9).getValue();
        
        prefs.put("theme", th);
        prefs.put("meter decay", md);
        prefs.putBoolean("low framerate", lf);
        prefs.putBoolean("system synth", ss);
        prefs.put("sf path", sf);
        prefs.putBoolean("autoload sf", al);
        prefs.put("loop snap", snl);
        prefs.put("pos snap", snp);
        prefs.putBoolean("recursive folder", rf);
        prefs.putBoolean("replace playlist", cf);
        
        t.set_theme(th);
        float quickness = md.equals("Instant") ? 1 : md.equals("Slow") ? 0.1 : 0.5;
        for (ChannelOsc c : player.channels) { c.disp.METER_LERP_QUICKNESS = quickness; }
        snap_loop_mult = snl.equals("No") ? 0 : snl.equals("Yes (coarse)") ? 8 : 2;
        snap_pos_mult = snp.equals("Yes (fine)") ? 2 : snp.equals("Yes (coarse)") ? 8 : 0;
    }})
    .run();
    
    dialog_settings.getByIndex(0).setValue(prefs.get("theme", "Fresh Blue"));
    dialog_settings.getByIndex(1).setValue(prefs.get("meter decay", "Smooth"));
    dialog_settings.getByIndex(2).setValue(prefs.getBoolean("low framerate", false));
    dialog_settings.getByIndex(3).setValue(prefs.getBoolean("system synth", false));
    dialog_settings.getByIndex(4).setValue(prefs.get("sf path", ""));
    dialog_settings.getByIndex(5).setValue(prefs.getBoolean("autoload sf", true));
    dialog_settings.getByIndex(6).setValue(prefs.get("loop snap", "Yes (fine)"));
    dialog_settings.getByIndex(7).setValue(prefs.get("pos snap", "No"));
    dialog_settings.getByIndex(8).setValue(prefs.getBoolean("recursive folder", false));
    dialog_settings.getByIndex(9).setValue(prefs.getBoolean("replace playlist", true));
    
    dialog_settings.getWindow().setSize(285, 580);
}
