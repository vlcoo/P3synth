import drop.*;

import java.io.*;
import java.util.Map.*;
import java.awt.*;
import processing.awt.PSurfaceAWT;

final processing.core.PApplet PARENT = this;
final float VERCODE = 23.23;
final float OVERALL_VOL = 0.7;
final float HIRES_MULT = 2;
boolean NO_REALTIME = true;

Frame frame;
String osname;
Player player;
LabsModule win_labs;
DnDListener dnd_listener;
PImage[] logo_anim;
PImage[] osc_type_textures;
PImage logo_icon;
PFont[] fonts;
SoundFile[] samples;
ThemeEngine t;
ButtonToolbar media_buttons;
ButtonToolbar setting_buttons;
Button b_meta_msgs;
Button b_loop;
Button b_labs;
WaitingDialog dialog_meta_msgs;
HashMap<String, String> config_map;
boolean hi_res = false;

float _mouseX = 0;
float _mouseY = 0;

void settings() {
    setup_config();
    try {
        int conf_hi_res = Integer.parseInt(config_map.get("high resolution"));
        hi_res = conf_hi_res == 1;
    }
    catch (NumberFormatException nfe) {}
    
    osname = System.getProperty("os.name");
    int sizeX = 724;
    int sizeY = 430;
    if (osname.contains("Windows")) sizeY = 460;
    
    if (hi_res) {
        sizeX *= HIRES_MULT;
        sizeY *= HIRES_MULT;
        noSmooth();
    }
    size(sizeX, sizeY);
}


void setup() {
    new Sound(PARENT).volume(OVERALL_VOL);    // oscillators at volume 1 are ridiculously loud... 
    
    SinOsc warmup = new SinOsc(PARENT);
    warmup.freq(100);
    warmup.amp(0.1);
    Env warmup_env = new Env(PARENT);
    warmup_env.play(warmup, 0.01, 0.08, 0.1, 0.04); 
    
    surface.setTitle("vlco_o P3synth");
    frame = ( (PSurfaceAWT.SmoothCanvas)surface.getNative() ).getFrame();
    
    t = new ThemeEngine();
    
    setup_images();
    setup_fonts();
    setup_buttons();
    setup_samples();
    t.set_theme(config_map.get("theme name"));
    
    player = new Player();
    SDrop drop = new SDrop(PARENT);
    dnd_listener = new DnDListener();
    drop.addDropListener(dnd_listener);
    
    warmup_env = null;
    warmup = null;
    redraw_all();
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
    
    if (player.playing_state == 1) {
        int n = (int) (player.seq.getTickPosition() / (player.midi_resolution/4)) % 8;
        image(logo_anim[abs(n)], 311, 10);
    }
    else {
        if (player.vu_anim_val >= 0.0) {
            player.vu_anim_step();
        }
    }
    
    if (dnd_listener.draggedOnto) player.custom_info_msg = "OK!";
    else player.custom_info_msg = "";
}



void load_config(boolean just_opened) {
    try {
        BufferedReader br = new BufferedReader(new FileReader("P3synth config"));
        while (br.ready()) {
            String param_n = br.readLine();
            String param_v = br.readLine();
            if (!param_n.equals("") && param_n != null && !param_v.equals("") && param_v != null) config_map.put(param_n, param_v);
        }
        br.close();
    }
    catch (FileNotFoundException fnfe) {
        println("load fnfe");
        ui.showInfoDialog(
            "Welcome! Please check your audio levels.\n\n" +
            
            "For help on advanced usage, check the HELP button or\n" +
            "the project's website at https://vlcoo.github.io/p3synth\n"
        );
        save_config();
    }
    catch (IOException ioe) {
        println("load ioe");
    }
    
    try {
        String s = config_map.get("custom theme");
        if (s != null && !s.equals("") && s.split(",").length == 5) {
            int[] colors = new int[5];
            for (int i = 0; i < 5; i++) {
                colors[i] = unhex(s.split(",")[i]);
            }
            t.available_themes.put("Custom loaded", colors);
        }
    }
    catch (NumberFormatException nfe) { ui.showErrorDialog("Custom theme data is invalid.", "Can't load custom theme"); }
}



void save_config() {
    try {
        PrintStream f = new PrintStream(new File("P3synth config"));
        for (Entry<String, String> config_pair : config_map.entrySet()) {
            f.println(config_pair.getKey());
            f.println(config_pair.getValue());
        }
        f.flush();
        f.close();
    }
    catch (IOException ioe) {
        println("save ioe");
    }
}



void redraw_all() {
    background(t.theme[2]);
    
    push();
    noFill();
    strokeWeight(2);
    stroke(t.theme[1]);
    rect(1, 1, width-2, height-2);
    pop();
    
    media_buttons.redraw();
    setting_buttons.redraw();
    image(logo_anim[0], 311, 10);
    player.redraw();
    b_meta_msgs.redraw();
    b_loop.redraw();
    b_labs.redraw();
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
    
    logo_icon = loadImage("graphics/icon.png");
    surface.setIcon(logo_icon);
}


void setup_config() {
    config_map = new HashMap<String, String>();
    config_map.put("theme name", "Fresh Blue");
    
    load_config(true);
}


void setup_fonts() {
    fonts = new PFont[5];
    fonts[0] = loadFont("TerminusTTF-12.vlw");
    fonts[1] = loadFont("TerminusTTF-14.vlw");
    fonts[2] = loadFont("TerminusTTF-Bold-14.vlw");
    fonts[3] = loadFont("TerminusTTF-Bold_Italic-14.vlw");
    fonts[4] = loadFont("RobotoCondensed-BoldItalic-16.vlw");
}


void setup_buttons() {
    Button b1 = new Button(12, 376, "reload", "Replay");
    Button b2 = new Button("stop", "Exit");
    Button b3 = new Button("pause", "Pause");
    Button[] buttons_ctrl = {b1, b3, b2};
    media_buttons = new ButtonToolbar(150, 16, 1.3, 0, buttons_ctrl);
    
    b1 = new Button("info", "Help");
    b2 = new Button("confTheme", "Theme");
    b3 = new Button("update", "Update");
    Button[] buttons_set = {b2, b1, b3};
    setting_buttons = new ButtonToolbar(464, 16, 1.3, 0, buttons_set);
    
    b_meta_msgs = new Button(682, 376, "message", "Hist.");    // next to the player's message bar
    b_loop = new Button(12, 376, "loop", "Loop");
    b_loop.set_pressed(true);
    b_labs = new Button(12, 16, "labs", "Labs");
}



void mouseClicked() {
    if (mouseButton == LEFT) {
        if(media_buttons.collided("Exit")) {
            cursor(WAIT);
            media_buttons.get_button("Exit").set_pressed(true);
            //ui.showWaitingDialog("Exiting...", "Please wait");
            player.set_playing_state(-1);
            if (player.midi_in_mode) player.stop_midi_in();
            player.seq.close();
            exit();
        }
        
        else if(media_buttons.collided("Pause")) {
            if (player.playing_state == -1) return;
            Button b = media_buttons.get_button("Pause");
            player.set_playing_state( b.pressed ? 1 : 0 );
            b.set_pressed(!b.pressed);
        }
        
        else if(media_buttons.collided("Replay")) {
            player.reload_curr_file();
        }
        
        else if(setting_buttons.collided("Theme")) {
            String selection = new UiBooster().showSelectionDialog(
                "What color scheme?",
                "Config",
                new ArrayList(t.available_themes.keySet())
            );
            if (selection == null) return;
            
            config_map.put("theme name", selection);
            save_config();
            t.set_theme(selection);
            redraw_all();
        }
        
        else if(setting_buttons.collided("Help")) {
            ui.showInfoDialog(
                "Thanks for using P3synth (v" + VERCODE + ")!\n\n" + 
                
                "Drag and drop a new MIDI file to play.\n" +
                "REPLAY: skip back to the beginning of the song.\n" +
                "PAUSE: pause any playing music or resume if paused.\n" +
                "EXIT: safely close the program.\n\n" +
                
                "The Labs menu has experimental playback/tinkering options!\n" +
                "The buttons on the other side provide some info and configs.\n\n" +
                
                "Left click the X on any channel to mute it, or right click it to solo.\n" +
                "You can use the lower left rectangle to control the song's position.\n" +
                "The arrows above and below it control the loop start and end positions!\n" +
                "The lower right rectangle shows the last text message the MIDI sent out.\n\n" +
                
                "Please beware of the bugs.\n" +
                "vlcoo.net  |  github.com/vlcoo/P3synth"
            );
        }
        
        else if(b_meta_msgs.collided() && player != null) {
            if(!b_meta_msgs.pressed) {
                b_meta_msgs.set_pressed(true);
                dialog_meta_msgs = ui.showWaitingDialog(
                    "These are lyrics, comments, or other text in the MIDI file.",
                    "Meta message history", player.history_text_messages, false
                );
            }
            else if(b_meta_msgs.pressed && dialog_meta_msgs != null) {
                b_meta_msgs.set_pressed(false);
                dialog_meta_msgs.close();
            }
        }
        
        else if(setting_buttons.collided("Update")) {
            cursor(WAIT);
            //WaitingDialog wd = ui.showWaitingDialog("Checking for updates...", "Please wait");
            float v = check_if_newer_ver();
            cursor(ARROW);
            //wd.close();
            
            if (v > 0) {
                ui.showConfirmDialog(
                    "There is a newer release available. Download now?", "Update",
                    new Runnable() { public void run() { download_latest_ver(); } },
                    new Runnable() { public void run() {} }
                );
            }
            else if (v == 0) ui.showInfoDialog("You're running the latest release of P3synth.");
            else  ui.showInfoDialog("You're running P3synth from source newer than the latest release.");
            
        }
        
        else if(b_loop.collided()) {
            if (player.seq == null) return;
            
            int n = b_loop.pressed ? 0 : 64;
            player.seq.setLoopCount(n);
            b_loop.set_pressed(!b_loop.pressed);
        }
        
        else if(b_labs.collided()) {
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
                }
            }
            
            else {
                win_labs.selfFrame.setVisible(false);
            }
            b_labs.set_pressed(!b_labs.pressed);
            win_labs.reposition();
        }
    }
    
    player.disp.check_buttons(mouseButton);
    player.check_chan_disp_buttons(mouseButton);   // check for any presses on the channel display
    
    media_buttons.redraw();
    setting_buttons.redraw();
    b_meta_msgs.redraw();
    b_labs.redraw();
}


void mouseDragged() {
    if (mouseButton == LEFT) {
        player.disp.check_buttons(mouseButton);
    }
}


// this doesn't stand for dungeons and dragons
class DnDListener extends DropListener {
    boolean draggedOnto = false;
    int PADDING = 64;
    
    DnDListener() {
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


boolean try_play_file(File selection) {
    if (selection != null) {
        String filename = selection.getAbsolutePath();
        String response = player.play_file(filename);
        
        if (!response.equals("")) {
            ui.showErrorDialog(response, "Can't play");
            return false;
        }
        return true;
    }
    return false;
}
