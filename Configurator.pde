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
    .addCheckbox("Reduce framerate *")
    .addCheckbox("Boot with system synth enabled *")
    .addText("Default soundfont for system synth *")
    .addSelection(
        "Snap loop points to beat",
        Arrays.asList("No", "Yes (fine)", "Yes (coarse)")
    )
    .addSelection(
        "Snap song position to beat",
        Arrays.asList("No", "Yes (fine)", "Yes (coarse)")
    )
    .setCloseListener(new FormCloseListener() { public void onClose(Form form) {
        String th = form.getByIndex(0).asString();
        boolean lf = (boolean) form.getByIndex(1).getValue();
        boolean ss = (boolean) form.getByIndex(2).getValue();
        String sf = form.getByIndex(3).asString();
        String snl = form.getByIndex(4).asString();
        String snp = form.getByIndex(5).asString();
        
        prefs.put("theme", th);
        prefs.putBoolean("low framerate", lf);
        prefs.putBoolean("system synth", ss);
        prefs.put("sf path", sf);
        prefs.put("loop snap", snl);
        prefs.put("pos snap", snp);
        
        t.set_theme(th);
        snap_loop_mult = snl.equals("No") ? 0 : snl.equals("Yes (coarse)") ? 8 : 2;
        snap_pos_mult = snp.equals("Yes (fine)") ? 2 : snp.equals("Yes (coarse)") ? 8 : 0;
    }})
    .run();
    
    dialog_settings.getByIndex(0).setValue(prefs.get("theme", "Fresh Blue"));
    dialog_settings.getByIndex(1).setValue(prefs.getBoolean("low framerate", false));
    dialog_settings.getByIndex(2).setValue(prefs.getBoolean("system synth", false));
    dialog_settings.getByIndex(3).setValue(prefs.get("sf path", ""));
    dialog_settings.getByIndex(4).setValue(prefs.get("loop snap", "Yes (fine)"));
    dialog_settings.getByIndex(5).setValue(prefs.get("pos snap", "No"));
    
    dialog_settings.getWindow().setSize(260, 460);
}
