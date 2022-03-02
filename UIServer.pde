import uibooster.*;
import uibooster.components.*;
import uibooster.model.*;
import uibooster.model.formelements.*;
import uibooster.model.options.*;
import uibooster.utils.*;

import java.util.Arrays;


UiBooster ui = new UiBooster();


class ChannelDisplay {
    int x, y;
    int id;
    ChannelOsc parent;
    Button button_mute;
    
    // meter values to be drawn...:
    float meter_vu_target = 0.0;
    float meter_vu_lerped = 0.0;
    float meter_ch_volume = 1.0;    // aka channel's curr_global_amp
    float meter_velocity = 0.0;     // aka channel's last_amp
    int label_frequency = 0;
    int label_osc_type = 0;
    
    final float METER_LERP_QUICKNESS = 0.1;
    final int METER_VU_LENGTH = 30;
    
    
    ChannelDisplay(int x, int y, int id, ChannelOsc parent) {
        this.x = x;
        this.y = y;
        this.id = id;
        this.parent = parent;
        
        button_mute = new Button(x+5, y+37, "mute", "");
    }
    
    
    private void update_all_values() {
        meter_vu_target = parent.curr_global_amp * parent.last_amp;
        
        if (meter_vu_lerped < meter_vu_target) meter_vu_lerped += METER_LERP_QUICKNESS;
        if (meter_vu_lerped > meter_vu_target) meter_vu_lerped -= METER_LERP_QUICKNESS;
        if (abs(meter_vu_lerped - meter_vu_target) < METER_LERP_QUICKNESS)
            meter_vu_lerped = meter_vu_target;
        
        meter_ch_volume = parent.curr_global_amp;
        meter_velocity = parent.last_amp;
        label_frequency = int(parent.last_freq);
        label_osc_type = parent.osc_type;
    }
    
    
    void check_buttons() {
        if (button_mute.collided()) {
            boolean curr_pressed = button_mute.pressed;
            button_mute.set_pressed(!curr_pressed);
            parent.silenced = !curr_pressed;
        }
    }
    
    
    void redraw(boolean renew_values) {
        if (renew_values) update_all_values();
        
        // drawing all the meters here...
        // try to use as little changing functions as possible (reuse)
        fill(t.theme[2]);
        noStroke();
        rect(x+1, y+1, 160, 63);
        
        // Lines
            strokeWeight(1);
            stroke(t.theme[0]);
            // top, bottom, col1, mid1-2, col2, col3, col4, col5, mid3-4-5
            line(x, y, x+160, y);
            line(x+32, y+64, x+160, y+64);
            line(x, y, x, y+32);
            line(x, y+32, x+32, y+32);
            line(x+32, y+32, x+32, y+64);
            line(x+96, y, x+96, y+64);
            line(x+128, y, x+128, y+64);
            line(x+160, y, x+160, y+64);
            line(x+96, y+32, x+160, y+32);
        
        // Ch number
            noStroke();
            fill(t.theme[1]);
            rect(x+1, y+1, 32, 31);
            fill(t.theme[0]);
            textAlign(CENTER, CENTER);
            fill(t.theme[4]);
            textFont(fonts[2]);
            text(id+1, x+16, y+16);
        
        // VU meter
            fill(t.theme[1]);
            rect(x+33, y+1, 63, 63);
            stroke(#00ff00);
            line(x+48, y+32, x+48, y+36);
            stroke(#ff0000);
            line(x+48+32, y+32, x+48+32, y+36);
            stroke(t.theme[4]);
            fill(t.theme[4]);
            circle(x+48+16, y+40, 4);
            stroke(t.theme[0]);
            strokeWeight(2);
            float angle = radians( map(meter_vu_lerped, 0.0, 1.0, -150, -30) );
            line(x+48+16, y+40, x+48+16 + METER_VU_LENGTH*cos(angle), y+40 + METER_VU_LENGTH*sin(angle));
        
        // Volume meter
            strokeWeight(1);
            noFill();
            rect(x+36, y+52, 56, 8);
            fill(t.theme[3]);
            noStroke();
            rect(x+37, y+53, 55 * meter_ch_volume, 7);
        
        // Freq label
            fill(t.theme[0]);
            textFont(fonts[0]);
            if (id == 9) text(label_frequency == 0 ? "-  -" : "-ts-", x+113, y+10);
            else text(label_frequency, x+113, y+10);
        
        // Velocity meter
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x+98, y+17, 28, 8);
            fill(t.theme[3]);
            noStroke();
            rect(x+99, y+18, 27 * meter_velocity, 7);
        
        // Osc type label
            fill(t.theme[0]);
            if (id == 9) {
                image(osc_type_textures[5], x+133, y+5);
            }
            else {
                image(osc_type_textures[label_osc_type+1], x+133, y+5);
            }
        
        // more to come...
            textFont(fonts[0]);
            text("x", x+113, y+48);
            text("x", x+145, y+48);
        
        button_mute.redraw();
    }
}


class PlayerDisplay {
    int x, y;
    Player parent;
    
    String label_filename;
    float meter_midi_pos;
    
    
    PlayerDisplay(int x, int y, Player parent) {
        this.x = x;
        this.y = y;
        this.parent = parent;
    }
    
    
    private void update_all_values() {
        label_filename = parent.curr_filename;
        meter_midi_pos = map(parent.seq.getTickPosition(), 0, parent.seq.getTickLength(), 0.0, 1.0);
    }
    
    
    void redraw(boolean renew_values) {
        if (renew_values) update_all_values();
        
        fill(t.theme[2]);
        noStroke();
        rect(x+1, y+1, 720, 63);
        
        fill(t.theme[0]);
        textFont(fonts[3]);
        text(label_filename, x, y+48);
        
        // Pos meter
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x, y, 300, 16);
            noStroke();
            fill(t.theme[3]);
            rect(x+1, y+1, 299 * meter_midi_pos, 15);
    }
}



class Button {
    int x, y, width, height;
    String icon_filename, label;
    PImage texture;
    boolean pressed = false;
    
    
    Button(String icon, String label) {
        this.icon_filename = icon;
        this.label = label;
        set_pressed(false);
    }
    
    
    Button(int x, int y, String icon, String label) {
        this.x = x;
        this.y = y;
        this.icon_filename = icon;
        this.label = label;
        set_pressed(false);
    }
    
    
    void set_pressed(boolean pressed) {
        this.pressed = pressed;
        
        String texture_path = "";
        if (pressed) {
            texture_path = "data/buttons/" + icon_filename + "Down.png";
        } else {
            texture_path = "data/buttons/" + icon_filename + "Up.png";
        }
        
        texture = loadImage(texture_path);
        this.width = texture.width;
        this.height = texture.height;
    }
    
    
    void redraw() {
        image(texture, x, y);
        fill(t.theme[0]);
        textAlign(LEFT);
        textFont(fonts[0], 12);
        text(label, x, y - 2);
    }


    boolean collided() {
        return (mouseX > this.x && mouseX < this.width + this.x) && (mouseY > this.y && mouseY < this.height + this.y);
    }
}



class ButtonToolbar {
    int x, y;
    float x_sep, y_sep = 1;
    HashMap<String, Button> buttons = new HashMap<String, Button>();

    ButtonToolbar(int x, int y, float x_sep, float y_sep, Button[] buttons) {
        this.x_sep = x_sep;
        this.y_sep = y_sep;
        this.x = x;
        this.y = y;

        int i = 0;
        for (Button b : buttons) {
            this.buttons.put(b.label, b);
            b.x = int(i * (b.width * this.x_sep) + x);
            b.y = int(i * (b.height * this.y_sep) + y);
            i++;
        }
    }


    Button get_button(String name) {
        return this.buttons.get(name);
    }
    
    
    void redraw() {
        for (Button b : buttons.values()) b.redraw();
    }


    boolean collided(String b_name) {
        return this.buttons.get(b_name).collided();
    }
}
