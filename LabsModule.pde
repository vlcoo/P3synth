import javax.swing.JFrame;


public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    String curr_transform = "None";
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        if (osname.contains("Windows")) this.size(210, 364);
        else this.size(210, 320);
        
    }
    
    
    public void exit() {
        toggle_labs_win();
    }
    
    
    public void setup() {
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        
        this.setup_buttons();
        this.selfFrame = ( (PSurfaceAWT.SmoothCanvas)this.surface.getNative() ).getFrame();
        ((JFrame) this.selfFrame).setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        
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
        Button b6 = new Button("midiIn", "midiIn");
        b6.show_label = false;
        Button b8 = new Button("rtEngine", "rtEngine");
        b8.show_label = false;
        Button b9 = new Button("demoUi", "demoUi");
        b9.show_label = false;
        Button[] bs = new Button[] {b1, b2, b3, b7, b6, b8, b9};
        all_buttons = new ButtonToolbar(8, 45, 0, 1.4, bs);
        
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
            
            else if (all_buttons.collided("midiIn", this)) {
                if (!player.midi_in_mode) player.start_midi_in();
                else player.stop_midi_in();
            }
            
            else if (all_buttons.collided("rtEngine", this)) {
                player.shut_up_all();
                NO_REALTIME = !NO_REALTIME;
            }
            
            else if (all_buttons.collided("demoUi", this)) {
                Form form = ui.createForm("Customize demo UI")
                .addText("Title")
                .addTextArea("Description")
                .addText("Format")
                .addSelection(
                    "Pulse 1 width",
                    Arrays.asList("Unchanged", "0.125", "0.25", "0.5", "0.75")
                )
                .addSelection(
                    "Pulse 2 width",
                    Arrays.asList("Unchanged", "0.125", "0.25", "0.5", "0.75")
                )
                .addButton("Toggle demo UI", new Runnable() { public void run() {
                    ui.showInfoDialog("Setting will take effect on next program restart.", "Setting saved");
                }})
                .setCloseListener(new FormCloseListener() { public void onClose(Form form) {
                    String t = form.getByIndex(0).asString();
                    String d = form.getByIndex(1).asString();
                    String f = form.getByIndex(2).asString();
                    String w1 = (String) form.getByIndex(3).getValue();
                    String w2 = (String) form.getByIndex(4).getValue();
                    
                    if (!t.equals("")) demo_title = t;
                    if (!d.equals("")) demo_description = d;
                    if (!f.equals("")) demo_layout = f;
                    if (!w1.equals("Unchanged")) player.channels[0].set_osc_type(Float.parseFloat(w1));
                    if (!w2.equals("Unchanged")) player.channels[1].set_osc_type(Float.parseFloat(w2));
                }})
                .run();
                
                form.getByIndex(0).setValue(demo_title);
                form.getByIndex(1).setValue(demo_description);
                form.getByIndex(2).setValue(demo_layout);
                
                form.getWindow().setSize(240, 520);
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
            all_buttons.collided("midiIn", this) ||
            all_buttons.collided("rtEngine", this) ||
            all_buttons.collided("demoUi", this)
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
        this.text((player.midi_in_mode ? "On" : "Off"), 179, 255);
        this.text((NO_REALTIME ? "Off" : "On"), 179, 294);
        
        all_buttons.redraw(this);
    }
    
    
    public boolean altered_values() {
        return ( player.last_freqDetune != 0 || player.last_noteDetune != 0 || !player.ktrans.transform.equals(player.ktrans.available_transforms.get("None")));
    }
}
