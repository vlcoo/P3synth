import javax.swing.JFrame;


public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    int voice_index = 0;
    
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        this.size(210, 240);
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
        
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        this.textAlign(CENTER, CENTER);
        this.text("Experimental options!\nUse at your own risk.", this.width/2, 22);
        
        this.textFont(fonts[1]);
        this.text(player.last_freqDetune, 179, 60);
        this.text(player.last_noteDetune, 179, 99);
        this.text(String.format("x%.1f", player.seq.getTempoFactor()), 179, 138);
        this.text((player.midi_in_mode ? "On" : "Off"), 179, 216);
        
        all_buttons.redraw(this);
    }
    
    
    void setup_buttons() {
        Button b1 = new Button("freqDetune", "freqDetune");
        b1.show_label = false;
        Button b2 = new Button("noteDetune", "noteDetune");
        b2.show_label = false;
        Button b3 = new Button("tempo", "tempo");
        b3.show_label = false;
        Button b7 = new Button("overrideOscs", "overrideOscs");
        b7.show_label = false;
        Button b6 = new Button("midiIn", "midiIn");
        b6.show_label = false;
        Button[] bs = new Button[] {b1, b2, b3, b7, b6};
        all_buttons = new ButtonToolbar(8, 45, 0, 1.4, bs);
        
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
    
    
    void mouseClicked() {
        if (mouseButton == LEFT) {
            if (all_buttons.collided("freqDetune", this)) {
                try {
                    float val = Float.parseFloat(ui.showTextInputDialog("New detune in Hz?"));
                    player.set_all_freqDetune(val);
                    player.setTicks((int)player.seq.getTickPosition());
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 3, -10.2, 0, 67.74", "Can't");
                }
                catch (NullPointerException npe) {}
            }
        
            else if (all_buttons.collided("noteDetune", this)) {
                try {
                    float val = Float.parseFloat(ui.showTextInputDialog("New transpose in semitones?"));
                    player.set_all_noteDetune(val);
                    player.setTicks((int)player.seq.getTickPosition());
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 4, -1.2, 0, 8.74", "Can't");
                }
                catch (NullPointerException npe) {}
            }
            
            else if (all_buttons.collided("tempo", this)) {
                try {
                    float val = Float.parseFloat(ui.showTextInputDialog("New speed factor?"));
                    if (val <= 0 || val > 4) throw new NumberFormatException();
                    player.seq.setTempoFactor(val);
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 0.1, 0.5, 1, 2.8", "Can't");
                }
                catch (NullPointerException npe) {}
            }
            
            else if (all_buttons.collided("overrideOscs", this)) {
                String selection = ui.showSelectionDialog(
                    "Override all channels with which oscillator?",
                    "LabsModule",
                    Arrays.asList("Pulse W0.125", "Pulse W0.25", "Pulse W0.5", "Pulse W0.75", "Triangle", "Sine", "Saw", "Drums")
                );
                
                if (selection != null) {
                    if (selection.equals("Pulse W0.125")) player.set_all_osc_types(0.125);
                    if (selection.equals("Pulse W0.25")) player.set_all_osc_types(0.25);
                    if (selection.equals("Pulse W0.5")) player.set_all_osc_types(0.5);
                    if (selection.equals("Pulse W0.75")) player.set_all_osc_types(0.75);
                    if (selection.equals("Triangle")) player.set_all_osc_types(1);
                    if (selection.equals("Sine")) player.set_all_osc_types(2);
                    if (selection.equals("Saw")) player.set_all_osc_types(3);
                    if (selection.equals("Drums")) player.set_all_osc_types(4);
                }
            }
            
            else if (all_buttons.collided("midiIn", this)) {
                if (!player.midi_in_mode) player.start_midi_in();
                else player.stop_midi_in();
            }
        }
        
        //this.redraw_all();
    }
    
    
    void mouseMoved() {
        if (all_buttons.collided("freqDetune", this) ||
            all_buttons.collided("noteDetune", this) ||
            all_buttons.collided("tempo", this) ||
            all_buttons.collided("overrideOscs", this) ||
            all_buttons.collided("midiIn", this)
            ) {
            this.cursor(HAND);
        }
        else {
            this.cursor(ARROW);
        }
    }
    
    
    public boolean altered_values() {
        return ( player.last_freqDetune != 0 || player.last_noteDetune != 0);
    }
}
