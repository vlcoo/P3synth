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
    String label_note = "";
    int label_osc_type = -1;
    int label_midi_program = 1;
    float label_pulse_width = 0.5;
    float meter_bend = 0.0;
    float meter_pan = 0.0;
    boolean label_hold_pedal = false;
    boolean label_sostenuto_pedal = false;
    boolean label_soft_pedal = false;
    
    final float METER_LERP_QUICKNESS = 0.5;
    final int METER_VU_LENGTH = 30;
    final String[] NOTE_NAMES = new String[] {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};
    
    
    ChannelDisplay(int x, int y, int id, ChannelOsc parent) {
        this.x = x;
        this.y = y;
        this.id = id;
        this.parent = parent;
        
        button_mute = new Button(x+5, y+37, "mute", "");
    }
    
    
    private void update_all_values() {
        meter_vu_target = parent.curr_global_amp * parent.amp_multiplier * parent.last_amp;
        
        if (meter_vu_lerped < meter_vu_target) meter_vu_lerped += METER_LERP_QUICKNESS * abs(meter_vu_lerped - meter_vu_target);
        if (meter_vu_lerped > meter_vu_target) meter_vu_lerped -= METER_LERP_QUICKNESS/2 * abs(meter_vu_lerped - meter_vu_target);
        //if (abs(meter_vu_lerped - meter_vu_target) < METER_LERP_QUICKNESS)
        //    meter_vu_lerped = meter_vu_target;
        
        // stop if silenced... not worth it updating the rest of the stuff
        if (parent.silenced) return;
        
        meter_ch_volume = parent.curr_global_amp * parent.amp_multiplier;
        meter_velocity = parent.last_amp;
        label_osc_type = parent.osc_type;
        label_hold_pedal = parent.hold_pedal;
        label_sostenuto_pedal = parent.sostenuto_pedal;
        label_soft_pedal = parent.soft_pedal;
        
        int notecode = parent.last_notecode - 21;
        if (label_osc_type == 4) { if (notecode <= -1) label_note = "|  |"; else label_note = "/  \\"; }
        else {
            if (notecode < 0) label_note = "-";
            else {
                int octave = int(notecode / 12) + 1;
                label_note = NOTE_NAMES[notecode % 12] + octave;
                if (win_labs != null && win_labs.altered_values()) label_note += "?";
            }
        }
        
        label_pulse_width = parent.osc_type == 0 ? parent.pulse_width : -1;
        meter_bend = parent.curr_global_bend / parent.curr_bend_range;    // transform +/- channel's curr_bend_range, we need +/- 1.0
        meter_pan = parent.curr_global_pan;
    }
    
    
    void check_buttons(int mButton) {
        if (button_mute.collided()) {
            if (mButton == LEFT) parent.set_muted(!button_mute.pressed);
            else if (mButton == RIGHT) player.set_channel_solo(!button_mute.pressed, parent.id);
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
            rect(x+36, y+52, 56, 8, 4);
            fill(t.theme[3]);
            noStroke();
            rect(x+37, y+53, 55 * meter_ch_volume, 7, 4);
        
        // Freq label
            fill(t.theme[0]);
            textFont(fonts[0]);
            text(label_note, x+113, y+10);
        
        // Velocity meter
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x+98, y+17, 28, 8, 4);
            fill(t.theme[3]);
            noStroke();
            rect(x+99, y+18, 27 * meter_velocity, 7, 4);
        
        // Osc type label
            fill(t.theme[0]);
            int auxY = 0;
            if (label_pulse_width != -1) {
                auxY = -5;
                stroke(t.theme[0]);
                fill(t.theme[1]);
                rect(x+130, y+23, 28, 4, 4);
                fill(t.theme[3]);
                noStroke();
                rect(x+131, y+24, 27 * label_pulse_width, 3, 4);
            }
            image(osc_type_textures[label_osc_type+1], x+133, y+5+auxY);
        
        // Pitch bend curve
            stroke(t.theme[0]);
            strokeWeight(2);
            noFill();
            if (label_osc_type != 4) bezier(x+104, y+42, x+104 + 12 * meter_bend, y+42 + -12 * meter_bend, x+120 + 12 * meter_bend, y+56 + -12 * meter_bend, x+120, y+56);
            else text("x", x+113, y+48);    // no bend for drums...
        
        // Panning meter
            strokeWeight(1);
            textFont(fonts[0]);
            fill(t.theme[1]);
            triangle(x+134, y+38, x+134, y+58, x+144, y+48);
            triangle(x+154, y+38, x+154, y+58, x+144, y+48);
            noStroke();
            fill(t.theme[3]);
            if (meter_pan != 0) triangle(x+144 + 9 * meter_pan, y+48 - 9 * abs(meter_pan), x+144 + 9 * meter_pan, y+48 + 9 * abs(meter_pan), x+144, y+48);
            //text(meter_pan, x+145, y+48);
        
        // Pedals
            textFont(fonts[0]);
            fill(t.theme[4]);
            if (label_hold_pedal) text("H", x+64, y+8);
            if (label_sostenuto_pedal) text("S", x+72, y+8);
            if (label_soft_pedal) text("s", x+80, y+8);
        
        button_mute.redraw();
    }
}


class PlayerDisplay {
    int x, y;
    Player parent;
    
    final int POS_X_POSBAR = 50;
    final int POS_Y_POSBAR = 64;
    final int POS_X_MESSAGEBAR = 366;
    final int WIDTH_POSBAR = 308;
    final int WIDTH_MESSAGEBAR = 308;
    final int HEIGHT_POSBAR = 18;
    
    float label_labs = 0.0;
    String label_filename = "";
    float meter_midi_pos = 0.0;
    String label_message = "- no message -";
    float meter_loop_begin = 0.0;
    float meter_loop_end = 1.0;
    float meter_loop_begin_X = 0.0;
    float meter_loop_end_X = 0.0;
    int meter_loop_begin_Y = 0;
    int meter_loop_end_Y = 0;
    String label_timestamp = "-:--";
    String label_timelength = "-:--";
    boolean label_GM = false;
    boolean label_GM2 = false;
    boolean label_XG = false;
    boolean label_GS = false;
    
    
    PlayerDisplay(int x, int y, Player parent) {
        this.x = x;
        this.y = y;
        this.parent = parent;
        
        meter_loop_begin_Y = y + POS_Y_POSBAR;
        meter_loop_end_Y = y + POS_Y_POSBAR + HEIGHT_POSBAR;
    }
    
    
    private void update_all_values() {
        if (parent.custom_info_msg.equals("")) {
            label_filename = java.nio.file.Paths.get(parent.curr_filename)
                .getFileName().toString().replaceFirst("[.][^.]+$", "");
                // what a mess... but it works
            label_filename = check_and_shrink_string(label_filename, 68);
        }
        else label_filename = parent.custom_info_msg;
        
        if (parent.seq.getTickLength() > 0) meter_midi_pos = map(parent.seq.getTickPosition(), 0, parent.seq.getTickLength(), 0.0, 1.0);
        label_message = player.last_text_message;    
        label_message = check_and_shrink_string(label_message, 36);    // we don't want it to get out of the rectangle...
        //label_labs = parent.curr_detune;
        
        if (parent.playing_state != -1) {
            meter_loop_begin = map(parent.seq.getLoopStartPoint(), 0, player.seq.getTickLength(), 0.0, 1.0);
            if (parent.seq.getLoopEndPoint() == -1) meter_loop_end = 1.0;
            else meter_loop_end = map(parent.seq.getLoopEndPoint(), 0, player.seq.getTickLength(), 0.0, 1.0);
            
            long secPos = player.seq.getMicrosecondPosition() / 1000000;
            long secLen = player.seq.getMicrosecondLength() / 1000000;
            this.label_timestamp = secPos / 60 + ":" + String.format("%02d", secPos % 60);
            this.label_timelength = secLen / 60 + ":" + String.format("%02d", secLen % 60);
        }
        else {
            meter_loop_begin = 0.0;
            meter_loop_end = 1.0;
            
            this.label_timestamp = "-:--";
            this.label_timelength = "-:--";
        }
        meter_loop_begin_X = x + POS_X_POSBAR + (WIDTH_POSBAR * meter_loop_begin);
        meter_loop_end_X = x + POS_X_POSBAR + (WIDTH_POSBAR * meter_loop_end);
        
        label_GM = parent.file_is_GM;
        label_GM2 = parent.file_is_GM2;
        label_XG = parent.file_is_XG;
        label_GS = parent.file_is_GS;
    }
    
    
    void check_buttons(int mButton) {
        if (mButton == LEFT) {
            if (parent.playing_state == -1) return;
            
            if (collided_posbar()) {
                if (parent.playing_state == -1) return;
                int new_pos = int( map(_mouseX, x + POS_X_POSBAR, x + POS_X_POSBAR + WIDTH_POSBAR, 0, parent.seq.getTickLength()) );
                parent.setTicks(new_pos);
                return;
            }
            
            int handle_no = collided_loopset_bar();
            try {
                if (handle_no == -1) {
                    int new_pos = int( map(_mouseX, x + POS_X_POSBAR, x + POS_X_POSBAR + WIDTH_POSBAR, 0, parent.seq.getTickLength()) );
                    parent.seq.setLoopStartPoint(new_pos);
                }
                
                else if (handle_no == 1) {
                    int new_pos = int( map(_mouseX, x + POS_X_POSBAR, x + POS_X_POSBAR + WIDTH_POSBAR, 0, parent.seq.getTickLength()) );
                    parent.seq.setLoopEndPoint(new_pos);
                }
            }
            catch (IllegalArgumentException iae) { }
        }
    }
    
    
    void redraw(boolean renew_values) {
        if (renew_values) update_all_values();
        
        fill(t.theme[2]);
        noStroke();
        rect(58, y+42, 600, 20);
        
        // Pos meter
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x + POS_X_POSBAR, y + POS_Y_POSBAR, WIDTH_POSBAR, HEIGHT_POSBAR, 4);
            noStroke();
            fill(t.theme[3]);
            rect(x+1 + POS_X_POSBAR, y+1 + POS_Y_POSBAR, (WIDTH_POSBAR-1) * meter_midi_pos, HEIGHT_POSBAR-1, 4);
        
        // Song pos and length labels
            textAlign(CENTER, CENTER);
            fill(t.theme[4]);
            textFont(fonts[1]);
            int auxX = x + POS_X_POSBAR + WIDTH_POSBAR/2;
            int auxY = y + POS_Y_POSBAR + 9;
            outlinedText(label_timestamp + " / " + label_timelength, auxX, auxY, t.theme[4], t.theme[0] - color(0x40000000));
        
        // Loop set meter
            fill(parent.seq.getLoopCount() == 0 ? t.theme[1] : t.theme[3]);
            stroke(t.theme[0]);
            triangle(meter_loop_begin_X, meter_loop_begin_Y, meter_loop_begin_X - 4, meter_loop_begin_Y - 16, meter_loop_begin_X + 4, meter_loop_begin_Y - 16);
            triangle(meter_loop_end_X, meter_loop_end_Y, meter_loop_end_X - 4, meter_loop_end_Y + 16, meter_loop_end_X + 4, meter_loop_end_Y + 16);
            
        // File name label
            fill(t.theme[0]);
            textFont(fonts[3]);
            text(label_filename, 362, y + POS_Y_POSBAR - 12);
        
        // Messages label
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x + POS_X_MESSAGEBAR, y + POS_Y_POSBAR, WIDTH_MESSAGEBAR, HEIGHT_POSBAR, 4);    // reusing some dimensions...
            fill(t.theme[4]);
            textFont(fonts[1]);
            text(label_message,  x + POS_X_MESSAGEBAR + WIDTH_MESSAGEBAR/2, y + POS_Y_POSBAR + 9);
        
        // Manufacturers / MIDI formats
            fill(t.theme[0]);
            textFont(fonts[0]);
            if (label_GM) text("GM", x + 660, y - 300);
            if (label_GM2) text("GM2", x + 660, y - 290);
            if (label_XG) text("XG", x + 660, y - 280);
            if (label_GS) text("GS", x + 660, y - 270);
        
        /*
        fill(t.theme[2]);
        noStroke();
        rect(44, 10, 80, 50);
        textAlign(LEFT);
        fill(t.theme[0]);
        textFont(fonts[0]);
        text(label_labs, 44, 32);*/
    }
    
    
    boolean collided_posbar() {
        return (_mouseX > x + POS_X_POSBAR && _mouseX < WIDTH_POSBAR + x + POS_X_POSBAR) && (_mouseY > y + POS_Y_POSBAR && _mouseY < HEIGHT_POSBAR + y + POS_Y_POSBAR);
    }
    
    
    int collided_loopset_bar() {
        int which = 0;    // 0 is not pressed
        if (parent.seq.getLoopCount() == 0) return 0;
        
        if ((_mouseX > x + POS_X_POSBAR && _mouseX < WIDTH_POSBAR + x + POS_X_POSBAR + 4) && (_mouseY > y + POS_Y_POSBAR - 16 && _mouseY < y + POS_Y_POSBAR)) {
            which = -1;    // -1 is begin
        }
        else if ((_mouseX > x + POS_X_POSBAR && _mouseX < WIDTH_POSBAR + x + POS_X_POSBAR + 4) && (_mouseY > y + POS_Y_POSBAR + HEIGHT_POSBAR && _mouseY < y + POS_Y_POSBAR + HEIGHT_POSBAR + 16)) {
            which = 1;    // 1 is end
        }
        
        return which;
    }
}



class Button {
    int x, y, width, height;
    String icon_filename, label;
    PImage texture;
    boolean pressed = false;
    boolean show_label = true;
    
    
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
            texture_path = "buttons/" + icon_filename + "Down.png";
        } else {
            texture_path = "buttons/" + icon_filename + "Up.png";
        }
        
        texture = loadImage(texture_path);
        this.width = texture.width;
        this.height = texture.height;
    }
    
    
    void redraw() {
        image(texture, x, y);
        fill(t.theme[0]);
        textAlign(CENTER);
        textFont(fonts[0], 12);
        if (show_label) text(label, x + this.width / 2, y - 2);
    }
    
    void redraw(PApplet win) {
        win.image(texture, x, y);
        win.fill(t.theme[0]);
        win.textAlign(CENTER);
        win.textFont(fonts[0], 12);
        if (show_label) win.text(label, x + this.width / 2, y - 2);
    }


    boolean collided() {
        return (_mouseX > this.x && _mouseX < this.width + this.x) && (_mouseY > this.y && _mouseY < this.height + this.y);
    }
    
    boolean collided(PApplet win) {
        return (win.mouseX > this.x && win.mouseX < this.width + this.x) && (win.mouseY > this.y && win.mouseY < this.height + this.y);
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
            if (b == null) continue;
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
    
    void redraw(PApplet win) {
        for (Button b : buttons.values()) b.redraw(win);
    }


    boolean collided(String b_name) {
        Button b = this.buttons.get(b_name);
        if (b == null) return false;
        return b.collided();
    }
    
    
    boolean collided(String b_name, PApplet win) {
        Button b = this.buttons.get(b_name);
        if (b == null) return false;
        return b.collided(win);
    }
}



void outlinedText(String text, int x, int y, color cFill, color cStroke) {
    push();
    
    fill(cStroke);
    for (int i = -1; i < 2; i++) {
        text(text, x+i, y);
        text(text, x, y+i);
    }
    
    fill(cFill);
    text(text, x, y);
    
    pop();
}
