import drop.*;

import java.io.*;
import java.util.Map.*;
import java.awt.*;
import processing.awt.PSurfaceAWT;

final processing.core.PApplet PARENT = this;
final float VERCODE = 23.32;
final float OVERALL_VOL = 0.8;
final float HIRES_MULT = 2;

String process_id = "p3synth2332";
Frame frame;
String osname;
Player player;
LabsModule win_labs;
PlaylistModule win_plist;
DnDMidListener dnd_mid;
DnDSfListener dnd_sf;
PImage[] logo_anim;
PImage[] osc_type_textures;
PImage midi_program_icon;
PImage logo_icon;
PFont[] fonts;
SoundFile[] samples;
ThemeEngine t;
boolean is_newbie;
ButtonToolbar media_buttons;
ButtonToolbar setting_buttons;
Button b_labs;
Button curr_mid_pressed;
WaitingDialog dialog_meta_msgs;
Form dialog_settings;
boolean show_key_hints = false;
boolean hi_res = false;
boolean low_frate = false;

boolean demo_ui = false;
String demo_layout = "NES (NTSC)";
String demo_title = "- No title -";
String demo_description = "- no description -\n\nUnknown composer";


void settings() {
    if (setup_process_lock()) {
        System.exit(0);
        return;
    }
    
    size(724, 460);
}


void setup() {
    new Sound(PARENT).volume(1);    // fixes crackling? (sometimes??)
    
    t = new ThemeEngine();
    surface.setTitle("vlco_o P3synth");
    frame = ( (PSurfaceAWT.SmoothCanvas)surface.getNative() ).getFrame();
    frame.setSize(new Dimension(724, 460));
    
    setup_images();
    setup_buttons();
    setup_config();
    setup_fonts();
    setup_samples();
    
    player = new Player();
    SDrop drop = new SDrop(PARENT);
    dnd_mid = new DnDMidListener();
    dnd_sf = new DnDSfListener();
    drop.addDropListener(dnd_mid);
    drop.addDropListener(dnd_sf);
    
    if (is_newbie) {
        ui.showInfoDialog(
            "Welcome! Please check your audio levels.\n\n" +
            
            "Feel free to check the usage guide via the HELP button.\n",
        "Hello");
        if (new File("P3synth config").exists()) ui.showWarningDialog(
            "This version uses a new settings backend, and the old config file will be ignored!\n" +
            "It's recommended to delete the 'P3synth config' file from the executable's directory.",
        "Settings conflict");
        prefs.putBoolean("new user", false);
    }
    
    request_media_buttons_refresh();
    redraw_all();
    
    if (args != null && args.length > 0) {
        player.vu_anim_val = -1.0;
        try_play_from_args(args.length > 1 ? args[1] : "", args[0]);
    }
    
    beginDiscordActivity();
}


void exit() {
    DiscordRPC.discordShutdown();
    store_control_memory();
    
    super.exit();
}
    
    
void draw() {
    updateDiscordActivity();
    redraw_all();
    
    if (player.playing_state == 1 && !demo_ui) {
        int n = (int) (player.seq.getTickPosition() / (player.midi_resolution/4)) % 8;
        image(logo_anim[abs(n)], 311, 10);
    }
    else {
        image(logo_anim[0], 311, 10);
        if (player.vu_anim_val >= 0.0) {
            player.vu_anim_step();
        }
    }
    
    if (dnd_mid.draggedOnto) player.custom_info_msg = "OK! (MID file)";
    else if (dnd_sf.draggedOnto) player.custom_info_msg = "OK! (Soundfont)";
    else player.custom_info_msg = "";
}


void redraw_all() {
    if (t.is_extended_theme) gradientRect(0, 0, width, height, (int) t.theme[2], t.theme[5], 0, this);
    else background(t.theme[2]);
    
    if (!demo_ui) {
        media_buttons.redraw();
        setting_buttons.redraw();
        b_labs.redraw();
    }
    player.redraw();
}


boolean setup_process_lock() {
    try {
        JUnique.acquireLock(process_id, new MessageHandler() {
            public String handle(String message) {
                if (!message.equals("")) {
                    String[] split_msg = message.split("\n");
                    try_play_from_args(split_msg.length > 1 ? split_msg[1] : "", split_msg[0]);
                }
                else {
                    frame.toFront();
                    frame.setState(Frame.NORMAL);
                }
                return "gotcha";
            }
        });
    }
    catch (AlreadyLockedException ale) {
        String msg_to_send = "";
        if (args != null && args.length > 0) msg_to_send = args[0] + "\n" + (args.length > 1 ? args[1] : "");
        if (JUnique.sendMessage(process_id, msg_to_send).equals("gotcha")) {
            return true;
        }
        else JUnique.releaseLock(process_id);
    }
    
    return false;
}


void setup_samples() {
    samples = new SoundFile[4];
    for (int i = 1; i <= samples.length; i++) {
        samples[i-1] = new SoundFile(PARENT, "samples/" + i + ".wav");
    }
}


void setup_images() {
    logo_anim = new PImage[8];
    for (int i = 0; i < 8; i++) {
        PImage img = loadImage("graphics/logo" + i + ".png");
        logo_anim[i] = img;
    }
    
    osc_type_textures = new PImage[6];
    for (int i = -1; i < 5; i++) {
        PImage img = loadImage("graphics/osc_" + i + ".png");
        osc_type_textures[i+1] = img;
    }
    midi_program_icon = loadImage("graphics/midi_program.png");
    
    logo_icon = loadImage("graphics/icon.png");
    surface.setIcon(logo_icon);
}


void setup_fonts() {
    fonts = new PFont[6];
    fonts[0] = loadFont("TerminusTTF-12.vlw");
    fonts[1] = loadFont("TerminusTTF-14.vlw");
    fonts[2] = loadFont("TerminusTTF-Bold-14.vlw");
    fonts[3] = loadFont("TerminusTTF-Bold_Italic-14.vlw");
    fonts[4] = loadFont("RobotoCondensed-BoldItalic-16.vlw");
    fonts[5] = loadFont("TerminusTTF-Bold_Italic-18.vlw");
}


void setup_buttons() {
    Button b1 = new Button(12, 376, "reload", "Replay");
    b1.set_key_hint("Home");
    Button b2 = new Button("stop", "Stop");
    b2.set_key_hint("End");
    Button b3 = new Button("pause", "Pause");
    b3.set_key_hint("Space");
    Button[] buttons_ctrl = {b1, b3, b2};
    media_buttons = new ButtonToolbar(160, 16, 1.3, 0, buttons_ctrl);
    
    b1 = new Button("info", "Help");
    //b1.set_key_hint("F1");
    b2 = new Button("conf", "Config");
    b2.set_key_hint("F2");
    b3 = new Button("update", "Update");
    Button[] buttons_set = {b2, b1, b3};
    setting_buttons = new ButtonToolbar(456, 16, 1.3, 0, buttons_set);
    
    b_labs = new Button(353, 390, "expand", "Labs");
    b_labs.set_key_hint("F3");
}


void request_media_buttons_refresh() {
    if (player == null) return;
    
    media_buttons.get_button("Pause").set_pressed(player.playing_state == 0);
    media_buttons.get_button("Stop").set_pressed(player.playing_state == -1);
}


void toggle_labs_win() {
    if (win_labs == null) {
        cursor(WAIT);
            win_labs = new LabsModule(frame);
            String[] args = {""};
            runSketch(args, win_labs);
        cursor(ARROW);
    }
    else {
        if (win_labs.isLooping()) {
            win_labs.selfFrame.setVisible(false);
            win_labs.noLoop();
        }
        else {
            win_labs.selfFrame.setVisible(true);
            win_labs.loop();
        }
    }
    
    win_labs.reposition();
    b_labs.set_pressed(!b_labs.pressed);
}


void toggle_playlist_win() {
    if (win_plist == null) {
        cursor(WAIT);
        win_plist = new PlaylistModule(frame, this);
        String[] args = {""};
        runSketch(args, win_plist);
        cursor(ARROW);
    }
    else {
        if (win_plist.isLooping()) {
            win_plist.selfFrame.setVisible(false);
            win_plist.noLoop();
        }
        else {
            win_plist.selfFrame.setVisible(true);
            win_plist.loop();
        }
    }
    
    win_plist.reposition();
    if (player != null) {
        player.seq.setLoopCount(0);
        player.disp.b_loop.set_pressed(false);
    }
}


void keyPressed() {
    if (keyCode == 18) {        // ALT
        show_key_hints = true;
    }
    
    if (key == ' ') {
        if (player.playing_state == -1) return;
        Button b = media_buttons.get_button("Pause");
        player.set_playing_state( b.pressed ? 1 : 0 );
    }
    
    else if (key == 'o') {
        File file = ui.showFileSelection("MIDI files", "mid", "midi");
        try_play_file(file);
    }
    
    else if (key == 'l') {
        if (player.seq == null) return;
        
        int n = player.disp.b_loop.pressed ? 0 : 64;
        player.seq.setLoopCount(n);
        player.disp.b_loop.set_pressed(!player.disp.b_loop.pressed);
    }
    
    else if (key == 'm') {
        ui.showTableImmutable(player.get_metadata_table(), Arrays.asList("Parameter", "Value"), "Files' metadata");
    }
    
    else if (key == 'n') {
        if (dialog_meta_msgs != null) dialog_meta_msgs.close();
        dialog_meta_msgs = ui.showWaitingDialog(
            "These are lyrics, comments, or other text in the MIDI file.",
            "Meta message history", player.history_text_messages
        );
    }
    
    else if (key == 's') {
        File file = ui.showFileSelection("Instrument patch files", "sf2", "dls");
        cursor(WAIT);
        try_load_sf(file);
        cursor(ARROW);
    }
    
    else if (keyCode == 112) {        // F1
        
    }
    
    else if (keyCode == 113) {
        open_config_dialog();
    }
    
    else if (keyCode == 114) {        // F3
        toggle_labs_win();
    }
    
    else if (keyCode == 115) {
        cursor(WAIT);
        player.set_seq_synth(!player.system_synth);
        cursor(ARROW);
    }
    
    else if (keyCode == 116) {        // F5
        toggle_playlist_win();
    }
    
    else if (keyCode == 36) {        // HOME
        player.reload_curr_file();
    }
    
    else if (keyCode == 35) {        // END
        if (player.playing_state == -1) return;
        player.set_playing_state(-1);
        win_plist.set_current_item(-1);
    }
    
    if (win_plist != null) {
        if (keyCode == 33) {        // PGUP
            win_plist.previous();
        }
        
        else if (keyCode == 34) {        // PGDOWN
            win_plist.next();
        }
    }
    
    if (player.playing_state != -1) {
        if (keyCode == LEFT) {
            player.seq.setMicrosecondPosition(player.seq.getMicrosecondPosition() - 1000000);
        }
        
        else if (keyCode == RIGHT) {
            player.seq.setMicrosecondPosition(player.seq.getMicrosecondPosition() + 1000000);
        }
        
        if (win_labs != null && win_labs.isLooping()) {
            if (keyCode == UP) {
                player.seq.setTempoFactor(constrain(player.seq.getTempoFactor() + 0.1, 0.1, 4));
            }
            
            else if (keyCode == DOWN) {
                player.seq.setTempoFactor(constrain(player.seq.getTempoFactor() - 0.1, 0.1, 4));
            }
        }
    }
    
    if (Character.isDigit(key)) {
        int chan = Integer.parseInt(String.valueOf(key)) - 1;
        if (chan == -1) chan = 9;
        player.set_channel_muted(!player.channels[chan].silenced, chan);
    }
}


void keyReleased() {
    show_key_hints = false;
}


void mousePressed() {
    if (mouseButton == LEFT) {
        for (Button b : media_buttons.buttons.values()) {
            if (b.icon_filename.equals("pause") || b.icon_filename.equals("stop")) continue;
            if (b.collided()) curr_mid_pressed = b;
        }
        for (Button b : setting_buttons.buttons.values()) {
            if (b.collided()) curr_mid_pressed = b;
        }
        if (player.disp.b_metadata.collided()) curr_mid_pressed = player.disp.b_metadata;
        else if (player.disp.b_prev.collided()) curr_mid_pressed = player.disp.b_prev;
        else if (player.disp.b_next.collided()) curr_mid_pressed = player.disp.b_next;
        
        if (curr_mid_pressed != null) curr_mid_pressed.set_pressed(true);
    }
}


void mouseReleased() {
    show_key_hints = false;
    
    if (mouseButton == LEFT) {
        if (curr_mid_pressed != null) {
            curr_mid_pressed.set_pressed(false);
            curr_mid_pressed = null;
        }
        
        if(media_buttons.collided("Stop")) {
            if (player.playing_state == -1) return;
            player.set_playing_state(-1);
            if (win_plist != null) win_plist.set_current_item(-1);
        }
        
        else if(media_buttons.collided("Pause")) {
            if (player.playing_state == -1) return;
            Button b = media_buttons.get_button("Pause");
            player.set_playing_state( b.pressed ? 1 : 0 );
        }
        
        else if(media_buttons.collided("Replay")) {
            player.reload_curr_file();
        }
        
        else if(setting_buttons.collided("Config")) {
            open_config_dialog();
        }
        
        else if(setting_buttons.collided("Help")) {
            /*ui.showList(
                "Thanks for using P3synth (v" + VERCODE + ")!\nChoose a help topic:",
                "Guide",
                new SelectElementListener() {public void onSelected(ListElement e) {
                    show_help_topic(e.getTitle().charAt(0));}},
                new ListElement("1 • Basic usage", "Play MIDI files using the built-in synthesizer.\n​"),
                new ListElement("2 • Visualization", "Overview of the different MIDI messages that are supported.\n​"),
                new ListElement("3 • Advanced usage", "Use custom soundfonts and instrument banks.\n​"),
                new ListElement("4 • Settings", "Description of the values in the settings dialog.\n​"),
                new ListElement("5 • Labs dialog", "Other experimental options.\n​"),
                new ListElement("6 • About the project", "What, how, who?\n​")
            );*/
            boolean go = ui.showConfirmDialog(
                "Thanks for using P3synth (v" + VERCODE + ")!\n"+
                "Drag and drop a MIDI file in the main window or hold 'ALT' to see available key shortcuts.\n"+
                "vlcoo.net  |  github.com/vlcoo/p3synth\n" +
                "\nThe guide is available online. Open?",
                "Help"
            );
            if (go) open_web_url("https://github.com/vlcoo/P3synth/wiki");
        }
        
        else if(player.disp.collided_metamsg_rect() && player != null) {
            if (dialog_meta_msgs != null) dialog_meta_msgs.close();
            dialog_meta_msgs = ui.showWaitingDialog(
                "These are lyrics, comments, or other text in the MIDI file.",
                "Meta message history", player.history_text_messages
            );
        }
        
        else if(setting_buttons.collided("Update")) {
            cursor(WAIT);
            //WaitingDialog wd = ui.showWaitingDialog("Checking for updates...", "Please wait");
            float v = check_if_newer_ver();
            cursor(ARROW);
            //wd.close();
            
            if (v > 0) {
                ui.showConfirmDialog(
                    "There is a newer release available. Download it?", "Update",
                    new Runnable() { public void run() { download_latest_ver(); } },
                    new Runnable() { public void run() {} }
                );
            }
            else if (v == 0) ui.showInfoDialog("You're running the latest release of P3synth.", "Update");
            else if (v == -1000) ui.showErrorDialog("GitHub could not be reached. Try again later.", "Update");
            else ui.showInfoDialog(
                "You're running a version that's ahead of the latest release,\n" +
                "so this may be the nightly source or a fork of P3synth.",
                "Update"
            );
        }
        
        else if(b_labs.collided()) {
            toggle_labs_win();
        }
        
        else if (player.disp.collided_sfload_rect()) {
            if (!player.system_synth && player.sf_filename.equals("Default") && !prefs.getBoolean("dismiss sf tip", false)) {
                ui.showInfoDialog(
                    "Bonus: drag and drop SF2/DLS file in that box to load it!\n",
                    "Switching modes"
                );
                prefs.putBoolean("dismiss sf tip", true);
            }
            cursor(WAIT);
            player.set_seq_synth(!player.system_synth);
            cursor(ARROW);
        }
        
        else if (player.disp.collided_queue_rect()) {
            toggle_playlist_win();
        }
    }
    
    player.disp.check_buttons(mouseButton);
    player.check_chan_disp_buttons(mouseButton);   // check for any presses on the channel display
}


void mouseDragged() {
    if (mouseButton == LEFT) {
        player.disp.check_buttons(mouseButton, true);
    }
}


void mouseMoved() {
    if (player.disp.collided_sfload_rect() ||
        player.disp.collided_metamsg_rect() ||
        player.disp.collided_queue_rect()
    ) cursor(HAND);
    else cursor(ARROW);
}


// this doesn't stand for dungeons and dragons
class DnDMidListener extends DropListener {
    boolean draggedOnto = false;
    int PADDING = 64;
    
    DnDMidListener() {
        setTargetRect(PADDING, PADDING, width-PADDING*2, height-PADDING*2);
    }
    
    void dropEnter() {
        draggedOnto = true;
    }
    
    void dropLeave() {
        draggedOnto = false;
    }
    
    void dropEvent(DropEvent e) {
        cursor(WAIT);
        if (try_play_file(e.file())) {
            media_buttons.get_button("Pause").set_pressed(false);
        }
        cursor(ARROW);
    }
}


class DnDSfListener extends DropListener {
    boolean draggedOnto = false;
    int PADDING = 64;
    
    DnDSfListener() {
        setTargetRect(width-138, 8, 106, 48);
    }
    
    void dropEnter() {
        draggedOnto = true;
    }
    
    void dropLeave() {
        draggedOnto = false;
    }
    
    void dropEvent(DropEvent e) {
        cursor(WAIT);
        try_load_sf(e.file());
        cursor(ARROW);
    }
}


boolean try_play_file(File selection, boolean invoked_from_playlist) {
    if (selection != null) {
        String s = selection.getAbsolutePath();
        String response = player.play_file(s);
        
        if (!response.equals("")) {
            ui.showErrorDialog(response, "Can't play");
            return false;
        }
        if (player.vu_anim_val >= 0.0) player.vu_anim_val = -1.0;
        if (!invoked_from_playlist && win_plist != null) win_plist.set_current_item(-1);
        return true;
    }
    return false;
}


boolean try_play_file(File selection) {
    return try_play_file(selection, false);
}


boolean try_load_sf(File selection) {
    if (selection != null) {
        String response = player.load_soundfont(selection);
        
        if (!response.equals("")) {
            ui.showErrorDialog(response, "Can't load");
            return false;
        }
        return true;
    }
    return false;
}


void try_play_from_args(String sf, String mid) {
    if (!sf.equals("")) try_load_sf(new File(sf));
    try_play_file(new File(mid));
}
