import javax.swing.JFrame;


public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    int voice_index = 0;
    
    Knob k_player_speed;
    Knob k_pitchbend;
    
    Knob[] all_knobs;
    Knob curr_knob = null;
    float starting_knob_value = 0; 
    int starting_knob_mouse_Ypos = 0;
    
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        this.size(210, 320);
    }
    
    
    public void exit() {
        toggle_labs_win();
    }
    
    
    public void setup() {
        this.selfFrame = ( (PSurfaceAWT.SmoothCanvas)this.surface.getNative() ).getFrame();
        this.selfFrame.setSize(new Dimension(210, 320));
        ((JFrame) this.selfFrame).setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        
        this.setup_buttons();
        this.reposition();
    }
    
    
    public void draw() {
        if (t.is_extended_theme) gradientRect(0, 0, this.width, this.height, (int) t.theme[2], t.theme[5], 0, this);
        else this.background(t.theme[2]);
        
        for (Knob k : all_knobs) {
            k.redraw(this);
        }
        
        if (curr_knob == null) {
            k_player_speed.value = player.seq.getTempoFactor();
            k_pitchbend.value = player.channels[15].curr_global_bend;
        }
    }
    
    
    void setup_buttons() {
        k_player_speed = new Knob(40, 40, "Playback\nspeed", 0.0, 4.0, 1.0);
        k_pitchbend = new Knob(120, 40, "Pitchbend\noverride", -1.0, 1.0, 0);
        
        all_knobs = new Knob[] {k_player_speed, k_pitchbend};
    }
    
    
    void reposition() {
        int x = this.parentFrame.getX();
        int y = this.parentFrame.getY();
        this.getSurface().setLocation((x < this.width ? x + parentFrame.getWidth() + 2 : x - this.width - 2), (y));
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
            curr_knob.value = Float.parseFloat(nf(constrain(map(this.mouseY, starting_knob_mouse_Ypos + 40, starting_knob_mouse_Ypos - 40, starting_knob_value - 1.0, starting_knob_value + 1.0), curr_knob.lower_bound, curr_knob.upper_bound), 1, 1));
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
    }
    
    
    public boolean altered_values() {
        return false;
    }
}
