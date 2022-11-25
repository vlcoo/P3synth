import uibooster.*;
import uibooster.components.*;
import uibooster.model.*;
import uibooster.model.formelements.*;
import uibooster.model.options.*;
import uibooster.utils.*;

import java.util.Arrays;


class ChannelDisplayDemo extends ChannelDisplay {
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
    
    final float METER_LERP_QUICKNESS = 0.4;
    final int METER_VU_LENGTH = 30;
    final String[] NOTE_NAMES = new String[] {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};
    
    
    ChannelDisplayDemo(int x, int y, int id, ChannelOsc parent) {
        super(x, y, id, parent);
        
        x = 100;
        if (id < 3) y = 60 + (78 * id);
        else if (id == 9) y = 294;
        
        this.x = x;
        this.y = y;
        this.id = id;
        this.parent = parent;
        
        button_mute = new Button(-24, -24, "mute", "");
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
        meter_bend = parent.curr_global_bend / parent.curr_bend_range * 2;
        meter_pan = parent.curr_global_pan;
    }
    
    
    void check_buttons(int mButton) {
        if (button_mute.collided()) {
            if (mButton == LEFT) parent.set_muted(!button_mute.pressed);
            else if (mButton == RIGHT) player.set_channel_solo(!button_mute.pressed, parent.id);
        }
    }
    
    
    void redraw(boolean renew_values) {
        if (demo_layout.contains("NES")) {
            if (id != 0 && id != 1 && id != 2 && id != 9) return;
        }
        
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
            line(x+128, y, x+128, y+32);
            line(x+160, y, x+160, y+64);
            line(x+96, y+32, x+160, y+32);
        
        // BGs
            noStroke();                    
            fill(t.theme[1]);
            rect(x+33, y+1, 63, 63);
            rect(x+1, y+1, 32, 31);
        
        // Ch number
            fill(t.theme[4]);
            textFont(fonts[4]);
            textAlign(CENTER, CENTER);
            text(id == 9 ? 4 : id+1, x+17, y+16);
        
        // VU meter
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
            if (label_osc_type != 4) bezier(x+104+10, y+40, x+104+10 + 12 * meter_bend, y+40 + -12 * meter_bend, x+120+22 + 12 * meter_bend, y+58 + -12 * meter_bend, x+120+22, y+58);
            else {
                fill(t.theme[0]);
                text("x", x+113+16, y+48);    // no bend for drums...
            }
        
        // Mute dim
            if (button_mute.pressed) {
                noStroke();
                fill(t.theme[2] - 0x64000000);
                rect(x, y, 161, 65);
            }
        
        button_mute.redraw();
    }
}


class PlayerDisplayDemo extends PlayerDisplay {
    int x, y;
    Player parent;
    
    final int POS_X_POSBAR = 336;
    final int POS_Y_POSBAR = -190;
    final int POS_X_MESSAGEBAR = 336;
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
    
    
    PlayerDisplayDemo(int x, int y, Player parent) {
        super(x, y, parent);
        
        this.x = x;
        this.y = y + 14;
        this.parent = parent;
        
        meter_loop_begin_Y = y + POS_Y_POSBAR;
        meter_loop_end_Y = y + POS_Y_POSBAR + HEIGHT_POSBAR;
    }
    
    
    private void update_all_values() {
        label_filename = demo_title;
        
        if (parent.seq.getTickLength() > 0) meter_midi_pos = map(parent.seq.getTickPosition(), 0, parent.seq.getTickLength(), 0.0, 1.0);
        label_message = demo_description;
        
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
        
        noFill();
        stroke(t.theme[1]);
        strokeWeight(2);
        rect(43, 32, 640, 360);
        strokeWeight(1);
        
        
        // Format label
            textAlign(CENTER, CENTER);
            textFont(fonts[4]);
            fill(t.theme[0] - color(0x40000000));
            int auxX = x + POS_X_POSBAR + WIDTH_POSBAR/2;
            int auxY = y + POS_Y_POSBAR + 133;
            text(demo_layout, auxX - 77, auxY + 8);
        
        // Pos meter
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x + POS_X_POSBAR + 166, auxY, WIDTH_POSBAR / 3, HEIGHT_POSBAR, 4);
        
        // Song pos and length labels
            fill(t.theme[4]);
            textFont(fonts[1]);
            text(label_timestamp, auxX + 67, auxY + 9);
            
        // File name label
            fill(t.theme[0]);
            textFont(fonts[5]);
            text(label_filename, 490, y + POS_Y_POSBAR - 12);
        
        // Messages label
            textAlign(CENTER, TOP);
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x + POS_X_MESSAGEBAR, y + POS_Y_POSBAR + 28, WIDTH_MESSAGEBAR, HEIGHT_POSBAR * 4, 4);    // reusing some dimensions...
            fill(t.theme[4]);
            textFont(fonts[1]);
            text(label_message,  x + POS_X_MESSAGEBAR + WIDTH_MESSAGEBAR/2, y + POS_Y_POSBAR + 9 + 28);
        
        text("DEMO mode is ON", 80, 20);
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
