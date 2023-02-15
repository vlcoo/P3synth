import javax.swing.JFrame;


public class LabsModule extends PApplet {
    final int KNOB_Y_POS = 50;
    Frame parentFrame;
    Frame selfFrame;
    
    Knob k_player_speed;
    Knob k_pitchbend;
    Knob k_volume;
    Knob k_rt_adsr;
    Knob k_rt_mod;
    
    Knob[] all_knobs;
    Knob curr_knob = null;
    float starting_knob_value = 0; 
    int starting_knob_mouse_Ypos = 0;
    
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        this.size(362, 100);
    }
    
    
    public void exit() {
        toggle_labs_win();
    }
    
    
    public void setup() {
        this.surface.setTitle("Labs module");
        this.selfFrame = ( (PSurfaceAWT.SmoothCanvas)this.surface.getNative() ).getFrame();
        ((JFrame) this.selfFrame).setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        
        this.setup_buttons();
        this.reposition();
    }
    
    
    public void draw() {
        if (player == null) return;
        
        if (t.is_extended_theme) gradientRect(0, 0, this.width, this.height, (int) t.theme[2], t.theme[5], 0, this);
        else this.background(t.theme[2]);
        this.text("x", 250, KNOB_Y_POS + 10);
        this.text("x", 320, KNOB_Y_POS + 10);
        
        for (Knob k : all_knobs) {
            if ((k == k_rt_adsr || k == k_rt_mod) && player.system_synth) continue;
            k.redraw(this);
        }
        this.fill(t.theme[0]);
        this.textFont(fonts[2]);
        this.text("Experimental options! Use at your own risk.", 181, 10);
        
        /*if (curr_knob == null) {
            k_player_speed.value = player.seq.getTempoFactor();
            k_pitchbend.value = player.channels[15].curr_global_bend / player.channels[15].curr_bend_range;
        }*/
    }
    
    
    void setup_buttons() {
        k_player_speed = new Knob(110, KNOB_Y_POS, "Playback\nspeed", 0.0, 4.0, 1.0);
        k_pitchbend = new Knob(180, KNOB_Y_POS, "Pitchbend\noverride", -1.0, 1.0, 0);
        k_volume = new Knob(40, KNOB_Y_POS, "Master\nvolume", 0.0, 2.0, 1.0);
        k_rt_adsr = new Knob(250, KNOB_Y_POS, "RT Env\nstrength", 0.0, 2.0, 0.0);
        k_rt_mod = new Knob(320, KNOB_Y_POS, "RT Mod\nstrength", 0.0, 2.0, 0.0);
        
        all_knobs = new Knob[] {k_player_speed, k_pitchbend, k_volume, k_rt_adsr, k_rt_mod};
    }
    
    
    void reposition() {
        int x = this.parentFrame.getX();
        int y = this.parentFrame.getY();
        this.getSurface().setLocation((x + 181), (y > parentFrame.getHeight() + this.height ? y - this.height - 30 : y + parentFrame.getHeight() - 18));
        this.getSurface().setIcon(logo_icon);
    }
    
    
    void keyPressed() {
        if (keyCode == 114) {        // F3
            toggle_labs_win();
        }
    }
    
    
    void mousePressed() {
        starting_knob_mouse_Ypos = this.mouseY;
        
        for (Knob k : all_knobs) {
            if (k.collided(this)) {
                curr_knob = k;
                k.show_value_hint = true;
                break;
            }
        }
        
        if (curr_knob != null) {
            starting_knob_value = curr_knob.value;
        }
    }
    
    
    void mouseClicked() {
        if (this.mouseButton == RIGHT) {
            for (Knob k : all_knobs) {
                if (k.collided(this)) {
                    curr_knob = k;
                    k.value = k.neutral_value;
                    sync_knobs_and_vals();
                    return;
                }
            }
        }
        
        else if (this.mouseButton == LEFT)
            sync_knobs_and_vals();
    }
    
    
    void mouseReleased() {
        if (curr_knob != null) {
            curr_knob.show_value_hint = false;
            curr_knob = null;
        }
        //this.cursor(ARROW);
    }
    
    
    void mouseDragged() {
        if (curr_knob != null && mouseButton == LEFT) {
            //this.cursor(MOVE);
            if ((curr_knob == k_rt_adsr || curr_knob == k_rt_adsr) && player.system_synth) return;
            curr_knob.value = Float.parseFloat(nf(constrain(map(this.mouseY, starting_knob_mouse_Ypos + knob_sensitivity, starting_knob_mouse_Ypos - knob_sensitivity, starting_knob_value - 1.0, starting_knob_value + 1.0), curr_knob.lower_bound, curr_knob.upper_bound), 1, 1));
        }
        //else this.cursor(ARROW);
        
        sync_knobs_and_vals();
    }
    
    
    void sync_knobs_and_vals() {
        if (curr_knob == k_player_speed) {
            player.seq.setTempoFactor(k_player_speed.value);
        }
        else if (curr_knob == k_pitchbend) {
            try {
                for (int i = 0; i < 16; i++) 
                    player.event_listener.send(new ShortMessage(224, i, 0, floor(map(k_pitchbend.value, -1.0, 1.0, 0, 127))), 0);
            }
            catch (InvalidMidiDataException imde) {
                println("imde on labs pbend!!");
            }
        }
        else if (curr_knob == k_volume) {
            player.osc_synth_volume_mult = k_volume.value;
            try {
                for (int i = 0; i < 16; i++) 
                    player.event_listener.send(new SysexMessage(
                        new byte[] {(byte)0xf0, 0x7f, 0x7f, 0x04, 0x01, 0x00, (byte)map(k_volume.value, 0.0, 2.0, 0x00, 0x40), (byte)0xf7}, 8)
                    , 0);
            }
            catch (InvalidMidiDataException imde) {
                println("imde on labs vol!!");
            }
        }
        else if (curr_knob == k_rt_adsr && !player.system_synth) {
            RTSoundObject.amp_env_start_ticks = (int)(k_rt_adsr.value);
            RTSoundObject.amp_env_end_ticks = (int)(k_rt_adsr.value * 6);
        }
        else if (curr_knob == k_rt_mod && !player.system_synth) {
            RTSoundObject.freq_mod_mod = k_rt_mod.value * 2.5 + 1;
            RTSoundObject.freq_mod_limit = k_rt_mod.value * 4.5 + 2;
        }
        
        RTSoundObject.enabled = k_rt_adsr.value > 0.0 || k_rt_mod.value > 0.0;
    }
    
    
    public boolean altered_values() {
        return false;
    }
}
