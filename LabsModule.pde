public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        this.size(210, 300);
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
        Button b4 = new Button("transform", "transform");
        b4.show_label = false;
        Button b5 = new Button("sysSynth", "sysSynth");
        b5.show_label = false;
        Button b6 = new Button("midiIn", "midiIn");
        b6.show_label = false;
        Button[] bs = new Button[] {b1, b2, b3, b4, b5, b6};
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
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 10, -90.2, 0, 167.74", "Can't");
                }
                catch (NullPointerException npe) {}
            }
        
            else if (all_buttons.collided("noteDetune", this)) {
                try {
                    float val = Float.parseFloat(ui.showTextInputDialog("New transpose in semitones?"));
                    player.set_all_noteDetune(val);
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 4, -10.2, 0, 8.74", "Can't");
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
        }
        
        //this.redraw_all();
    }
    
    
    void mouseMoved() {
        if (all_buttons.collided("freqDetune", this) || 
            all_buttons.collided("noteDetune", this) || 
            all_buttons.collided("tempo", this) || 
            all_buttons.collided("transform", this) || 
            all_buttons.collided("sysSynth", this) || 
            all_buttons.collided("midiIn", this)
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
        this.text("Experimental options!\nUse at own risk.", this.width/2, 22);
        
        this.textFont(fonts[1]);
        this.text(player.last_freqDetune, 179, 60);
        this.text(player.last_noteDetune, 179, 99);
        this.text("x" + player.seq.getTempoFactor(), 179, 138);
        this.text(curr_transform, 179, 177);
        this.text((player.system_synth ? "On" : "Off"), 179, 216);
        this.text((player.midi_in_mode ? "On" : "Off"), 179, 255);
        
        all_buttons.redraw(this);
    }
    
    
    public boolean altered_values() {
        return ( player.last_freqDetune != 0 || player.last_noteDetune != 0 || !player.ktrans.transform.equals(player.ktrans.available_transforms.get("None")));
    }
}
