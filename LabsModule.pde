public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        this.size(210, 220);
    }
    
    
    public void setup() {
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        
        this.setup_buttons();
        
        this.selfFrame = ( (PSurfaceAWT.SmoothCanvas)this.surface.getNative() ).getFrame();
        reposition();
        redraw_all();
    }
    
    
    public void draw() {
        
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
        Button[] bs = new Button[] {b1, b2, b3, b4};
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
                    float val = Float.parseFloat(ui.showTextInputDialog("New detune in frequency?"));
                    player.set_all_freqDetune(val);
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 10, -90.2, 0, 167.74", "Can't");
                }
                catch (NullPointerException npe) {}
            }
        
            else if (all_buttons.collided("noteDetune", this)) {
                try {
                    float val = Float.parseFloat(ui.showTextInputDialog("New detune in semitones?"));
                    player.set_all_noteDetune(val);
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 4, -10.2, 0, 8.74", "Can't");
                }
                catch (NullPointerException npe) {}
            }
            
            else if (all_buttons.collided("tempo", this)) {
                try {
                    int val = Integer.parseInt(ui.showTextInputDialog("New tempo in BPM?"));
                    if (val <= 0 || val > player.TEMPO_LIMIT) throw new NumberFormatException();
                    player.seq.setTempoInBPM(val);
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 120, 90, 200", "Can't");
                }
                catch (NullPointerException npe) {}
            }
            
            else if (all_buttons.collided("transform", this)) {
                String selection = new UiBooster().showSelectionDialog(
                    "New mode?",
                    "LabsModule",
                    new ArrayList(player.ktrans.available_transforms.keySet())
                );
                
                if (selection != null) {
                    player.ktrans.set_transform(selection);
                    player.setTicks((int)player.seq.getTickPosition());    // this applies the changes...?
                    curr_transform = selection;
                }
            }
        }
        
        this.redraw_all();
    }
    
    
    void mouseMoved() {
        if (all_buttons.collided("freqDetune", this) || 
            all_buttons.collided("noteDetune", this) || 
            all_buttons.collided("tempo", this) || 
            all_buttons.collided("transform", this)
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
        this.text("Welcome to P3synth's\nexperimenting module!", this.width/2, 22);
        
        this.textFont(fonts[1]);
        this.text(player.last_freqDetune, 179, 60);
        this.text(player.last_noteDetune, 179, 99);
        this.text(floor(player.seq.getTempoInBPM()), 179, 138);
        this.text(curr_transform, 179, 177);
        
        all_buttons.redraw(this);
    }
    
    
    public boolean altered_values() {
        return ( player.last_freqDetune != 0 || player.last_noteDetune != 0 || !player.ktrans.transform.equals(player.ktrans.available_transforms.get("None")));
    }
}
