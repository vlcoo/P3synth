public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        if (osname.contains("Windows")) this.size(210, 395);
        else this.size(210, 369);
    }
    
    
    public void setup() {
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        
        this.setup_buttons();
        
        this.selfFrame = ( (PSurfaceAWT.SmoothCanvas)this.surface.getNative() ).getFrame();
        reposition();
        this.redraw_all();
    }
    
    
    public void draw() {
        this.redraw_all();
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
        Button b4 = new Button("transform", "transform");
        b4.show_label = false;
        Button b5 = new Button("sysSynth", "sysSynth");
        b5.show_label = false;
        Button b6 = new Button("midiIn", "midiIn");
        b6.show_label = false;
        Button b8 = new Button("rtEngine", "rtEngine");
        b8.show_label = false;
        Button[] bs = new Button[] {b1, b2, b3, b7, b4, b5, b6, b8};
        all_buttons = new ButtonToolbar(8, 45, 0, 1.3, bs);
        
    }
    
    
    void reposition() {
        int x = this.parentFrame.getX();
        int y = this.parentFrame.getY();
        this.getSurface().setLocation((x < this.width ? x + parentFrame.getWidth() + 8: x - this.width), (y));
        this.getSurface().setIcon(logo_icon);
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
            
            else if (all_buttons.collided("transform", this)) {
                String selection = new UiBooster().showSelectionDialog(
                    "New key/chord mode?",
                    "LabsModule",
                    new ArrayList(player.ktrans.available_transforms.keySet())
                );
                
                if (selection != null) {
                    player.ktrans.set_transform(selection);
                    player.setTicks((int)player.seq.getTickPosition());    // this applies the changes...?
                    curr_transform = selection;
                }
            }
            
            else if (all_buttons.collided("sysSynth", this)) {
                ui.showWarningDialog(
                    "Volume is louder and some options are not\n" + 
                    "available while System Synth is ON.\n" +
                    "Please mind the loading time.",
                    "LabsModule"
                );
                PARENT.cursor(WAIT);
                this.cursor(WAIT);
                player.set_seq_synth(!player.system_synth);
                PARENT.cursor(ARROW);
                this.cursor(ARROW);
            }
            
            else if (all_buttons.collided("midiIn", this)) {
                if (!player.midi_in_mode) player.start_midi_in();
                else player.stop_midi_in();
            }
            
            else if (all_buttons.collided("rtEngine", this)) {
                NO_REALTIME = !NO_REALTIME;
            }
        }
        
        //this.redraw_all();
    }
    
    
    void mouseMoved() {
        if (all_buttons.collided("freqDetune", this) || 
            all_buttons.collided("noteDetune", this) || 
            all_buttons.collided("tempo", this) ||
            all_buttons.collided("overrideOscs", this) || 
            all_buttons.collided("transform", this) || 
            all_buttons.collided("sysSynth", this) || 
            all_buttons.collided("midiIn", this) ||
            all_buttons.collided("rtEngine", this)
            ) {
            this.cursor(HAND);
        }
        else {
            this.cursor(ARROW);
        }
    }
    
    
    public void redraw_all() {
        this.background(t.theme[2]);
            
        this.push();
        this.noFill();
        this.strokeWeight(2);
        this.stroke(t.theme[1]);
        this.rect(1, 1, this.width-2, this.height-2);
        this.pop();
        
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        this.textAlign(CENTER, CENTER);
        this.text("Experimental options!\nUse at your own risk.", this.width/2, 22);
        
        this.textFont(fonts[1]);
        this.text(player.last_freqDetune, 179, 60);
        this.text(player.last_noteDetune, 179, 99);
        this.text("x" + player.seq.getTempoFactor(), 179, 138);
        //this.text("x", 179, 177);
        this.text(curr_transform, 179, 216);
        this.text((player.system_synth ? "On" : "Off"), 179, 255);
        this.text((player.midi_in_mode ? "On" : "Off"), 179, 294);
        this.text((NO_REALTIME ? "No" : "Yes"), 179, 333);
        
        all_buttons.redraw(this);
    }
    
    
    public boolean altered_values() {
        return ( player.last_freqDetune != 0 || player.last_noteDetune != 0 || !player.ktrans.transform.equals(player.ktrans.available_transforms.get("None")));
    }
}
