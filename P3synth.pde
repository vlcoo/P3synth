import drop.*;

import java.io.*;
import java.util.Map.*;
import java.awt.*;
import processing.awt.PSurfaceAWT;

final processing.core.PApplet PARENT = this;
final float VERCODE = 23.28;
final float OVERALL_VOL = 0.8;
final float HIRES_MULT = 2;
boolean NO_REALTIME = true;

Frame frame;
String osname;
Player player;
LabsModule win_labs;
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
Button b_metadata;
Button b_loop;
Button b_labs;
Button curr_mid_pressed;
WaitingDialog dialog_meta_msgs;
Form dialog_settings;
boolean hi_res = false;
boolean low_frate = false;

boolean demo_ui = false;

String demo_layout = "NES (NTSC)";
String demo_title = "- No title -";
String demo_description = "- no description -\n\nUnknown composer";

float _mouseX = 0;
float _mouseY = 0;


void settings() {
    osname = System.getProperty("os.name");
    int sizeX = 724;
    int sizeY = 430;
    if (osname.contains("Windows")) sizeY = 460;
    size(sizeX, sizeY);
}


void setup() {
    new Sound(PARENT).volume(1);    // fixes crackling? (sometimes??)
    
    surface.setTitle("vlco_o P3synth");
    frame = ( (PSurfaceAWT.SmoothCanvas)surface.getNative() ).getFrame();
    
    t = new ThemeEngine();
    
    setup_config();
    setup_images();
    setup_fonts();
    setup_buttons();
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
        if (args.length > 1) try_load_sf(new File(args[1]));
        try_play_file(new File(args[0]));
    }
}
    
    
void draw() {
    if (hi_res) {
        scale(HIRES_MULT);
        _mouseX = mouseX / HIRES_MULT;
        _mouseY = mouseY / HIRES_MULT;
    }
    else {
        _mouseX = mouseX;
        _mouseY = mouseY;
    }
        
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
    background(t.theme[2]);
    
    push();
    noFill();
    strokeWeight(2);
    stroke(t.theme[1]);
    rect(1, 1, width-2, height-2);
    pop();
    
    if (!demo_ui) {
        media_buttons.redraw();
        setting_buttons.redraw();
        b_metadata.redraw();
        b_loop.redraw();
        b_labs.redraw();
    }
    player.redraw();
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
    Button b2 = new Button("stop", "Stop");
    Button b3 = new Button("pause", "Pause");
    Button[] buttons_ctrl = {b1, b3, b2};
    media_buttons = new ButtonToolbar(150, 16, 1.3, 0, buttons_ctrl);
    
    b1 = new Button("info", "Help");
    b2 = new Button("conf", "Config");
    b3 = new Button("update", "Update");
    Button[] buttons_set = {b2, b1, b3};
    setting_buttons = new ButtonToolbar(464, 16, 1.3, 0, buttons_set);
    
    b_metadata = new Button(682, 376, "metadata", "Metadata ");    // next to the player's message bar
    b_loop = new Button(12, 376, "loop", "Loop");
    b_loop.set_pressed(true);
    b_labs = new Button(12, 16, "labs", "Labs");
}


void request_media_buttons_refresh() {
    if (player == null) return;
    
    media_buttons.get_button("Pause").set_pressed(player.playing_state == 0);
    media_buttons.get_button("Stop").set_pressed(player.playing_state == -1);
}


void toggle_labs_win() {
    if (!b_labs.pressed) {
        if (win_labs == null) {
            cursor(WAIT);
            win_labs = new LabsModule(frame);
            String[] args = {""};
            runSketch(args, win_labs);
            cursor(ARROW);
        }
        else {
            win_labs.selfFrame.setVisible(true);
            win_labs.loop();
        }
    }
    
    else {
        win_labs.selfFrame.setVisible(false);
        win_labs.noLoop();
    }
    b_labs.set_pressed(!b_labs.pressed);
    win_labs.reposition();
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
        if (b_metadata.collided()) curr_mid_pressed = b_metadata;
        
        if (curr_mid_pressed != null) curr_mid_pressed.set_pressed(true);
    }
}


void mouseReleased() {
    if (mouseButton == LEFT) {
        if (curr_mid_pressed != null) {
            curr_mid_pressed.set_pressed(false);
            curr_mid_pressed = null;
        }
        
        if(media_buttons.collided("Stop")) {
            if (player.playing_state == -1) return;
            player.set_playing_state(-1);
        }
        
        else if(media_buttons.collided("Pause")) {
            if (player.playing_state == -1) return;
            Button b = media_buttons.get_button("Pause");
            player.set_playing_state( b.pressed ? 1 : 0 );
            //b.set_pressed(!b.pressed);
        }
        
        else if(media_buttons.collided("Replay")) {
            player.reload_curr_file();
        }
        
        else if(setting_buttons.collided("Config")) {
            open_config_dialog();
        }
        
        else if(setting_buttons.collided("Help")) {
            ui.showList(
                "Thanks for using P3synth (v" + VERCODE + ")!\nChoose a help topic:",
                "Guide",
                new SelectElementListener() {public void onSelected(ListElement e) {
                    show_help_topic(e.getTitle().charAt(0));}},
                new ListElement("1 • Basic usage", "Play MIDI files using the built-in synthesizer.\n​"),
                new ListElement("2 • Visualization", "Overview of the different MIDI messages that are supported.\n​"),
                new ListElement("3 • Advanced usage", "Use custom soundfonts and instrument banks.\n​"),
                new ListElement("4 • Settings", "Description of the values in the settings dialog.\n​"),
                new ListElement("5 • Labs dialog", "Other experimental options.\n​"),
                new ListElement("6 • About the project", "What, how, who?\n​"));
        }
        
        else if(player.disp.collided_metamsg_rect() && player != null) {
            if (dialog_meta_msgs != null) dialog_meta_msgs.close();
            dialog_meta_msgs = ui.showWaitingDialog(
                "These are lyrics, comments, or other text in the MIDI file.",
                "Meta message history", player.history_text_messages
            );
        }
        
        else if(b_metadata.collided()) {
            ui.showTableImmutable(player.get_metadata_table(), Arrays.asList("Parameter", "Value"), "Files' metadata");
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
            else  ui.showInfoDialog("You may be running a P3synth from source or a fork of it.", "Update");
            
        }
        
        else if(b_loop.collided()) {
            if (player.seq == null) return;
            
            int n = b_loop.pressed ? 0 : 64;
            player.seq.setLoopCount(n);
            b_loop.set_pressed(!b_loop.pressed);
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
    }
    
    else if (mouseButton == RIGHT) {
        if (b_loop.collided()) {
            player.reset_looppoints();
        }
    }
    
    player.disp.check_buttons(mouseButton);
    player.check_chan_disp_buttons(mouseButton);   // check for any presses on the channel display
}


void mouseDragged() {
    if (mouseButton == LEFT) {
        player.disp.check_buttons(mouseButton);
    }
}


void mouseMoved() {
    if (player.disp.collided_sfload_rect() ||
        player.disp.collided_metamsg_rect()
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
        setTargetRect(width-128, 8, 116, 48);
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


boolean try_play_file(File selection) {
    if (selection != null) {
        String s = selection.getAbsolutePath();
        String response = player.play_file(s);
        
        if (!response.equals("")) {
            ui.showErrorDialog(response, "Can't play");
            return false;
        }
        return true;
    }
    return false;
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
