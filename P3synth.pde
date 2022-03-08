import java.io.*;
import java.util.Map.*;

final processing.core.PApplet PARENT = this;
final float VERCODE = 22.67;

Player player;
PImage[] logo_anim;
PImage[] osc_type_textures;
PImage bg_gradient;
PFont[] fonts;
ThemeEngine t;
ButtonToolbar media_buttons;
ButtonToolbar setting_buttons;
Button b_meta_msgs;
WaitingDialog dialog_meta_msgs;
HashMap<String, String> config_map;

void setup() {
    text("please wait!\nloading...", 12, 12);
    new Sound(PARENT).volume(0.7);    // oscillators at volume 1 are ridiculously loud... 
    
    SinOsc warmup = new SinOsc(PARENT);
    warmup.freq(100);
    warmup.amp(0.01);
    warmup.play();    // has to be done so the audio driver is prepared for what we're about to do to 'em...*/
    
    size(724, 420);
    surface.setTitle("vlco_o P3synth");
    
    setup_images();
    setup_fonts();
    setup_buttons();
    setup_config();
    
    t = new ThemeEngine(config_map.get("theme name"));
    player = new Player();
    
    warmup.stop();
    warmup = null;
    redraw_all();
}



void draw() {
    if (!player.stopped) {
        player.redraw();
        int n = (int) (player.seq.getTickPosition() / (player.midi_resolution/4)) % 8;
        image(logo_anim[n], 311, 10);
    }
    else {
        if (player.vu_anim_val >= 0.0) {
            player.vu_anim_step();
        }
    }
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
        ui.showWarningDialog(
            "Welcome! You may want to lower the volume.\n\n" + 
            "Press PLAY to begin or EXIT to quit at any time.",
            
            "First time warning"
        );
        save_config();
    }
    catch (IOException ioe) {
        println("load ioe");
    }
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
    stroke(t.theme[0]);
    rect(1, 1, width-2, height-2);
    pop();
    
    media_buttons.redraw();
    setting_buttons.redraw();
    image(logo_anim[0], 311, 10);
    player.redraw();
    b_meta_msgs.redraw();
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
    
    bg_gradient = loadImage("graphics/gradient.png");
    bg_gradient.resize(width, bg_gradient.height);
}


void setup_config() {
    config_map = new HashMap<String, String>();
    config_map.put("theme name", "Fresh Blue");
    
    load_config(true);
}


void setup_fonts() {
    fonts = new PFont[4];
    fonts[0] = loadFont("TerminusTTF-12.vlw");
    fonts[1] = loadFont("TerminusTTF-14.vlw");
    fonts[2] = loadFont("TerminusTTF-Bold-14.vlw");
    fonts[3] = loadFont("TerminusTTF-Bold_Italic-14.vlw");
}


void setup_buttons() {
    Button b1 = new Button("play", "Play");
    Button b2 = new Button("stop", "Exit");
    Button b3 = new Button("pause", "Pause");
    Button[] buttons_ctrl = {b1, b3, b2};
    media_buttons = new ButtonToolbar(150, 16, 1.2, 0, buttons_ctrl);
    
    b1 = new Button("info", "Help");
    b2 = new Button("confTheme", "Theme");
    b3 = new Button("update", "Update");
    Button[] buttons_set = {b2, b1, b3};
    setting_buttons = new ButtonToolbar(470, 16, 1.2, 0, buttons_set);
    
    b_meta_msgs = new Button(682, 376, "message", "Hist.");    // next to the player's message bar
}



void mouseClicked() {
    if (mouseButton == LEFT) {
        if(media_buttons.collided("Play")) {
            Button b = media_buttons.get_button("Play");
            b.set_pressed(true);
            File file = ui.showFileSelection("MIDI files", "mid", "midi");
            if (!try_play_file(file) && player.seq == null) b.set_pressed(false);
            else media_buttons.get_button("Pause").set_pressed(false);
        }
        
        else if(media_buttons.collided("Exit")) {
            media_buttons.get_button("Exit").set_pressed(true);
            ui.showWaitingDialog("Exiting...", "Please wait");
            player.stop_all();
            exit();
        }
        
        else if(media_buttons.collided("Pause")) {
            Button b = media_buttons.get_button("Pause");
            if (!player.set_paused(!b.pressed)) return;
            b.set_pressed(!b.pressed);
        }
        
        else if(setting_buttons.collided("Theme")) {
            String selection = new UiBooster().showSelectionDialog(
                "What color scheme?",
                "Config",
                Arrays.asList("Fresh Blue", "Hot Red", "Crispy Green", "GX Peach")
            );

            
            config_map.put("theme name", selection);
            save_config();
            t.set_theme(selection);
            redraw_all();
        }
        
        else if(setting_buttons.collided("Help")) {
            ui.showInfoDialog(
                "Thanks for using P3synth (v" + VERCODE + ")!\n\n" + 
                
                "PLAY: open a new MIDI file to play.\n" +
                "PAUSE: pause any playing music or resume if paused.\n" +
                "EXIT: safely close the program.\n\n" +
                
                "The other button(s) next to those can control various options.\n\n" +
                
                "Press the X on any channel to mute it.\n" +
                "You can use the lower left rectangle to control the song's position.\n" +
                "The lower right rectangle shows the last text message the MIDI sent out.\n\n" +
                
                "This is proof of concept software. Beware of the bugs.\n" +
                "For more, check out: https://vlcoo.github.io"
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
            //ui.showInfoDialog(player.history_text_messages);
        }
        
        else if(setting_buttons.collided("Update")) {
            WaitingDialog wd = ui.showWaitingDialog("Checking for updates...", "Please wait");
            boolean b = check_if_newer_ver();
            wd.close();
            
            if (b) {
                ui.showConfirmDialog(
                    "There is a newer version available. Download now?", "Update",
                    new Runnable() { public void run() { download_latest_ver(); } },
                    new Runnable() { public void run() {} }
                );
            }
            else ui.showInfoDialog("You're running the latest version of P3synth.");
        }
        
        else {
            player.disp.check_buttons();        // check for any presses on the player controls
            player.check_chan_disp_buttons();   // check for any presses on the channel display
        }
        
    }
    
    media_buttons.redraw();
    setting_buttons.redraw();
    b_meta_msgs.redraw();
}



boolean try_play_file(File selection) {
    if (selection != null) {
        String filename = selection.getAbsolutePath();
        String response = player.play_file(filename);
        redraw_all();
        
        if (!response.equals("")) {
            ui.showErrorDialog(response, "Can't play");
            return false;
        }
        return true;
    }
    return false;
}
