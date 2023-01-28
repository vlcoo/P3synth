import javax.swing.JFrame;


public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    int voice_index = 0;
    
    Knob knob1;
    Knob curr_knob = null;
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
        
        knob1.redraw(this);
    }
    
    
    void setup_buttons() {
        knob1 = new Knob(24, 24, "ow");
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
        
        if (knob1.collided(this)) {
            curr_knob = knob1;
            curr_knob.show_value_hint = true;
        }
    }
    
    
    void mouseReleased() {
        if (curr_knob != null) {
            curr_knob.show_value_hint = false;
            curr_knob = null;
        }
        cursor(ARROW);
    }
    
    
    void mouseMoved() {
        if (curr_knob != null || knob1.collided(this)) this.cursor(MOVE);
        else this.cursor(ARROW);
    }
    
    
    void mouseDragged() {
        if (curr_knob != null) {
            curr_knob.value = constrain(map(this.mouseY, starting_knob_mouse_Ypos + 64, starting_knob_mouse_Ypos - 64, curr_knob.value-1.0, curr_knob.value+1.0), -1.0, 1.0);
            player.seq.setTempoFactor(knob1.value);
        }
    }
    
    
    public boolean altered_values() {
        return false;
    }
}
