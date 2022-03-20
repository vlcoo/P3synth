public class LabsModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    Button b_test;
    
    LabsModule(Frame f) {
        this.parentFrame = f;
    }
    
    
    public void settings() {
        this.size(200, 260);
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
        b_test = new Button(30, 80, "labs", "Freq. detune");
    }
    
    
    void reposition() {
        int x = this.parentFrame.getX();
        int y = this.parentFrame.getY();
        this.getSurface().setLocation((x < this.width ? x + parentFrame.getWidth() + 8: x - this.width), (y));
        this.getSurface().setIcon(logo_icon);
    }
    
    
    void mouseClicked() {
        if (mouseButton == LEFT) {
            if (b_test.collided(this)) {
                try {
                    float val = Float.parseFloat(ui.showTextInputDialog("New detune in frequency?"));
                    player.set_all_detune(val);
                }
                catch (NumberFormatException nfe) {
                    ui.showErrorDialog("Invalid value. Examples: 10, -90.2, 0, 167.74", "Can't");
                }
                catch (NullPointerException npe) {}
            }
        }
        
        this.redraw_all();
    }
    
    
    public void redraw_all() {
        this.background(t.theme[2]);
            
        this.push();
        this.noFill();
        this.strokeWeight(2);
        this.stroke(t.theme[0]);
        this.rect(1, 1, this.width-2, this.height-2);
        this.pop();
        
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        this.textAlign(LEFT);
        this.text("Welcome to P3synth's\nexperimenting module!", 4, 20);
        this.text(player.curr_detune, 10, 60);
        
        b_test.redraw(this);
    }
}
