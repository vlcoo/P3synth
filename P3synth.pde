processing.core.PApplet PARENT = this;


Player player;
PImage[] logo_anim;
PImage[] osc_type_textures;
PFont[] fonts;
ThemeEngine t;
ButtonToolbar media_buttons;
ButtonToolbar setting_buttons;

void setup() {
    SinOsc warmup = new SinOsc(PARENT);
    warmup.freq(100);
    warmup.amp(0.2);
    warmup.play();    // has to be done so the audio driver is prepared for what we're about to do to 'em...
    
    size(724, 480);
    t = new ThemeEngine("Hot Red");
    surface.setTitle("vlco_o P3synth");
    
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
    
    setup_fonts();
    setup_buttons();
    
    player = new Player();
    
    warmup.stop();
    warmup = null;
    redraw_all();
    
    ui.showInfoDialog(
        "Welcome! Press PLAY to begin.\n\n" + 
        "Please mind the flashing lights and glitching audio."
    );
}


void draw() {
    if (!player.stopped) {
        player.redraw();
        int n = (int) (player.seq.getTickPosition() / (player.midi_resolution/4)) % 8;
        image(logo_anim[n], 12, 10);
    }
    else {
        if (player.vu_anim_val >= 0.0) {
            player.vu_anim_step();
        }
    }
}


void redraw_all() {
    background(t.theme[2]);
    media_buttons.redraw();
    setting_buttons.redraw();
    image(logo_anim[0], 12, 10);
    player.redraw();
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
    Button[] buttons_set = {b1};
    setting_buttons = new ButtonToolbar(300, 16, 1.2, 0, buttons_set);
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
        
        else if(setting_buttons.collided("Help")) {
            ui.showInfoDialog(
                "Thanks for getting P3synth.\n\n" + 
                
                "PLAY: Open a new MIDI file to play.\n" +
                "PAUSE: pause any playing music or resume if paused.\n" +
                "EXIT: safely close the program.\n\n" +
                
                "This is proof of concept software. Beware of the bugs.\n" +
                "For more, check out: https://vlcoo.github.io"
            );
        }
        
        else player.check_chan_disp_buttons();
    }
    
    media_buttons.redraw();
    setting_buttons.redraw();
}


boolean try_play_file(File selection) {
    if (selection != null) {
        String filename = selection.getAbsolutePath();
        String response = player.play_file(filename);
        redraw_all();
        return true;
    }
    return false;
}
