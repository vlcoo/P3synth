import uibooster.*;
import uibooster.components.*;
import uibooster.model.*;
import uibooster.model.formelements.*;
import uibooster.model.options.*;
import uibooster.utils.*;

import java.util.Arrays;


UiBooster ui = new UiBooster();

enum ChannelDisplayTypes {
    ORIGINAL, VERTICAL_BARS
}


class ChannelDisplay {
    int x, y;
    int id;
    ChannelOsc parent;
    Button button_mute;
    
    // meter values to be drawn...:
    float meter_vu_target = 0.0;
    float meter_ch_volume = 1.0;    // aka channel's curr_global_amp
    float meter_velocity = 0.0;     // aka channel's last_amp
    String label_note = "";
    int label_osc_type = -1;
    int label_midi_program = -1;
    float label_pulse_width = 0.5;
    float meter_bend = 0.0;
    float meter_pan = 0.0;
    boolean label_hold_pedal = false;
    boolean label_sostenuto_pedal = false;
    boolean label_soft_pedal = false;
    
    final String[] NOTE_NAMES = new String[] {"A", "A#", "B", "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#"};
    
    
    ChannelDisplay(int id, ChannelOsc parent) {
        this.id = id;
        this.parent = parent;
    }
    
    
    private void update_all_values() {
        //if (abs(meter_vu_lerped - meter_vu_target) < METER_LERP_QUICKNESS)
        //    meter_vu_lerped = meter_vu_target;
        
        // stop if silenced... not worth it updating the rest of the stuff
        if (parent.silenced) {
            label_note = "-";
            meter_velocity = 0.0;
            return;
        }
        
        meter_ch_volume = parent.curr_global_amp * parent.amp_multiplier;
        meter_velocity = parent.last_amp;
        
        label_osc_type = parent.osc_type;
        if (player.system_synth) label_midi_program = parent.midi_program;
        else label_midi_program = -1;
        
        label_hold_pedal = parent.hold_pedal;
        label_sostenuto_pedal = parent.sostenuto_pedal;
        label_soft_pedal = parent.soft_pedal;
        
        int notecode = parent.last_notecode - 21;
        if (label_osc_type == 4) { if (notecode <= -1) label_note = "| |"; else label_note = "/\\"; }
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
    
    
    void redraw(boolean renew_values) {
        
    }
    
    
    void check_buttons(int mButton) {
        if (button_mute.collided()) {
            if (mButton == LEFT) player.set_channel_muted(!button_mute.pressed, parent.id);
            else if (mButton == RIGHT) player.set_channel_solo(!button_mute.pressed, parent.id);
        }
    }
}


class ChannelDisplayOriginal extends ChannelDisplay {
    float meter_vu_lerped = 0.0;
    
    float METER_LERP_QUICKNESS;
    float METER_LERP_DECAYNESS;
    final int METER_VU_LENGTH = 30;
    
    ChannelDisplayOriginal(int id, ChannelOsc parent) {
        super(id, parent);
        x = 12 + 180 * (id / 4);
        y = 64 + 72 * (id % 4);
        
        button_mute = new Button(x+4, y+37, "mute", "");
        if (id < 10) {
            int hint = id + 1;
            if (id == 9) hint = 0;
            button_mute.set_key_hint(Integer.toString(hint));
        }
        recalc_quickness_from_settings();
    }
    
    
    private void update_all_values() {
        meter_vu_target = parent.curr_global_amp * parent.amp_multiplier * parent.last_amp;
        
        if (METER_LERP_QUICKNESS > 0) {
            if (meter_vu_lerped < meter_vu_target) meter_vu_lerped += METER_LERP_QUICKNESS * abs(meter_vu_lerped - meter_vu_target);
            if (meter_vu_lerped > meter_vu_target) meter_vu_lerped -= METER_LERP_QUICKNESS/METER_LERP_DECAYNESS * abs(meter_vu_lerped - meter_vu_target);
        }
        else meter_vu_lerped = meter_vu_target;
        
        super.update_all_values();
    }
    
    
    void redraw(boolean renew_values) {
        if (renew_values) update_all_values();
        
        // drawing all the meters here...
        // try to use as little changing functions as possible (reuse)
        /*fill(t.theme[2]);
        noStroke();
        rect(x+1, y+1, 160, 63);*/
        // Lines
            strokeWeight(1);
            stroke(t.theme[0]);
            noFill();
            // top, bottom, col1, mid1-2, col2, col3, col4, col5, mid3-4-5
            line(x, y, x+160, y);
            line(x+32, y+64, x+160, y+64);
            line(x, y, x, y+32);
            line(x, y+32, x+32, y+32);
            line(x+32, y+32, x+32, y+64);
            line(x+96, y, x+96, y+64);
            line(x+128, y+1, x+128, y+64);
            line(x+160, y, x+160, y+64);
            line(x+96, y+32, x+160, y+32);
            
        
        // BGs
            fill(t.theme[1]);
            noStroke();
            rect(x+33, y+1, 63, 63);
            rect(x+1, y+1, 32, 31);
        
        // Ch number
            fill(t.theme[4]);
            textFont(fonts[4]);
            textAlign(CENTER, CENTER);
            text(id+1, x+17, y+16);
        
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
            if (label_midi_program >= 0) {
                if (label_osc_type == -1) image(osc_type_textures[0], x+133, y+5);
                else {
                    textFont(fonts[0]);
                    text(label_midi_program, x+152, y+25);
                    image(label_osc_type == 4 ? osc_type_textures[5] : midi_program_icon, x+129, y+1);
                }
            }
            else {
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
            }
        
        // Pitch bend curve
            stroke(t.theme[0]);
            strokeWeight(2);
            noFill();
            if (label_osc_type != 4) bezier(x+104, y+42, x+104 + 12 * meter_bend, y+42 + -12 * meter_bend, x+120 + 12 * meter_bend, y+56 + -12 * meter_bend, x+120, y+56);
            else text("x", x+113, y+48);    // no bend for drums...
        
        // Pedals
            fill(t.theme[0]);
            textFont(fonts[0]);
            if (label_osc_type != 4) {
                if (label_soft_pedal) text("~", x+77, y+10);
                if (label_sostenuto_pedal) text("*", x+84, y+6);
                if (label_hold_pedal) text("•", x+90, y+6);
            }
        
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
        
        // Mute dim
            if (button_mute.pressed) {
                noStroke();
                fill(t.theme[2] - 0x64000000);
                rect(x, y, 161, 33);
                rect(x+32, y+33, 129, 33);
            }
        
        button_mute.redraw();
    }
    
    
    void recalc_quickness_from_settings() {
        String md = prefs.get("meter decay", "Smooth");
        float value = md.equals("Instant") ? 0.5 : md.equals("Slow") ? 6 : 2;
        
        METER_LERP_DECAYNESS = value;
        if (value < 1) METER_LERP_QUICKNESS = -1;
        else METER_LERP_QUICKNESS = 0.5;
    }
}


class ChannelDisplayVBars extends ChannelDisplay {
    float meter_vu_lerped = 0.0;
    
    float METER_LERP_QUICKNESS;
    float METER_LERP_DECAYNESS;
    
    ChannelDisplayVBars(int id, ChannelOsc parent) {
        super(id, parent);
        x = 11 + 44 * id;
        y = 66;
        
        button_mute = new Button(x+20, y+5, "mute", "");
        if (id < 10) {
            int hint = id + 1;
            if (id == 9) hint = 0;
            button_mute.set_key_hint(Integer.toString(hint));
        }
        recalc_quickness_from_settings();
    }
    
    
    private void update_all_values() {
        meter_vu_target = parent.curr_global_amp * parent.amp_multiplier * parent.last_amp;
        
        if (METER_LERP_QUICKNESS > 0) {
            if (meter_vu_lerped < meter_vu_target) meter_vu_lerped += METER_LERP_QUICKNESS * abs(meter_vu_lerped - meter_vu_target);
            if (meter_vu_lerped > meter_vu_target) meter_vu_lerped -= METER_LERP_QUICKNESS/METER_LERP_DECAYNESS * abs(meter_vu_lerped - meter_vu_target);
        }
        else meter_vu_lerped = meter_vu_target;
        
        super.update_all_values();
    }
    
    
    void redraw(boolean renew_values) {
        if (renew_values) update_all_values();
        
        stroke(t.theme[0]);
        fill(t.theme[1]);
        rect(x, y, 44, 32);
        fill(t.theme[4]);
        textFont(fonts[4]);
        textAlign(CENTER, CENTER);
        text(id+1, x+11, y+16);
        
        noFill();
        rect(x, y+32, 44, 20);
        
        fill(t.theme[0]);
        if (label_midi_program >= 0) {
            if (label_osc_type == -1) image(osc_type_textures[0], x+11, y+31);
            else {
                textFont(fonts[0]);
                text(label_midi_program, x+33, y+43);
                image(label_osc_type == 4 ? osc_type_textures[5] : midi_program_icon, x+2, y+31);
            }
        }
        else {
            if (label_pulse_width != -1) {
                image(osc_type_textures[label_osc_type+1], x+2, y+31);
                stroke(t.theme[0]);
                fill(t.theme[1]);
                rect(x+24, y+39, 15, 6, 4);
                fill(t.theme[3]);
                noStroke();
                rect(x+25, y+40, 14 * label_pulse_width, 5, 4);
            }
            else image(osc_type_textures[label_osc_type+1], x+11, y+31);
        }
        
        fill(t.theme[3]);
        stroke(t.theme[0]);
        rect(x+13, y+52, 18, 150);
        noStroke();
        fill(#ff0000);
        rect(x+14, y+53, 2, 150);
        fill(#ffff00);
        rect(x+14, y+63, 2, 140);
        fill(#00ff00);
        rect(x+14, y+93, 2, 110);
        fill(t.theme[1]);
        rectMode(CORNERS);
        rect(x+14, y+53, x+31, y+203 - 150*meter_vu_lerped);
        rectMode(CORNER);
        
        noFill();
        stroke(t.theme[0]);
        rect(x, y+202, 44, 80);
        for (int i = 0; i < 4; i++) 
            line(x, y+202+i*20, x+44, y+202+i*20);
        
        fill(t.theme[1]);
        rect(x+4, y+208, 36, 8, 4);
        fill(t.theme[3]);
        noStroke();
        rect(x+5, y+209, 35 * meter_ch_volume, 7, 4);
        
        fill(t.theme[0]);
        textFont(fonts[0]);
        text(label_note, x+23, y+202+27);
        fill(t.theme[1]);
        stroke(t.theme[0]);
        rect(x+4, y+234, 36, 5, 2);
        fill(t.theme[3]);
        noStroke();
        rect(x+5, y+235, 35 * meter_velocity, 4, 2);
        
        fill(t.theme[0]);
        stroke(t.theme[0]);
        strokeWeight(2);
        noFill();
        if (label_osc_type != 4) bezier(x+8, y+202+50, x+10, y+202+50 - 10*meter_bend, x+34, y+202+50 - 10*meter_bend, x+36, y+202+50);
        else text("x", x+23, y+202+50);    // no bend for drums...
        
        strokeWeight(1);
        fill(t.theme[1]);
        triangle(x+8, y+202+64, x+8, y+202+76, x+22, y+202+70);
        triangle(x+22, y+202+70, x+36, y+202+76, x+36, y+202+64);
        noStroke();
        fill(t.theme[3]);
        if (meter_pan != 0) triangle(x+22.5 + 14 * meter_pan, y+203+70 - 6 * abs(meter_pan), x+22.5 + 14 * meter_pan, y+202+70 + 6 * abs(meter_pan), x+22.5, y+202.5+70);
        
        if (button_mute.pressed) {
            noStroke();
            fill(t.theme[2] - 0x64000000);
            rect(x+1, y, 44, 283);
        }
        
        button_mute.redraw();
    }
    
    
    void recalc_quickness_from_settings() {
        String md = prefs.get("meter decay", "Smooth");
        float value = md.equals("Instant") ? 0.5 : md.equals("Slow") ? 6 : 2;
        
        METER_LERP_DECAYNESS = value;
        if (value < 1) METER_LERP_QUICKNESS = -1;
        else METER_LERP_QUICKNESS = 0.5;
    }
}


class PlayerDisplay {
    int x, y;
    Player parent;
    Button b_metadata;
    Button b_loop;
    Button b_next;
    Button b_prev;
    
    final int POS_X_POSBAR = 50;
    final int POS_Y_POSBAR = 64;
    final int POS_X_MESSAGEBAR = 376;
    final int WIDTH_POSBAR = 294;
    final int WIDTH_MESSAGEBAR = 294;
    final int HEIGHT_POSBAR = 18;
    
    String label_filename = "";
    String label_dnd_msg = "";
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
    String queue_bottom_str = "Empty";
    
    
    PlayerDisplay(int x, int y, Player parent) {
        this.x = x;
        this.y = y;
        this.parent = parent;
        
        meter_loop_begin_Y = y + POS_Y_POSBAR;
        meter_loop_end_Y = y + POS_Y_POSBAR + HEIGHT_POSBAR;
        
        b_metadata = new Button(682, 376, "metadata", "Metadata ");    // next to the player's message bar
        b_metadata.set_key_hint("m");
        b_loop = new Button(12, 376, "loop", "Loop");
        b_loop.set_key_hint("l");
        b_loop.set_pressed(true);
        b_next = new Button(104, 25, "next", "");
        b_next.show_label = false;
        b_next.set_key_hint("PGDN");
        b_prev = new Button(30, 25, "previous", "");
        b_prev.show_label = false;
        b_prev.set_key_hint("PGUP");
    }
    
    
    private void update_all_values() {
        if (show_key_hints) {
            label_filename = "Press 'o' to open a file to play...";
        }
        else {
            if (parent.custom_info_msg.equals("")) {
                label_filename = java.nio.file.Paths.get(parent.curr_filename)
                    .getFileName().toString().replaceFirst("[.][^.]+$", "");
                    // what a mess... but it works
                label_filename = check_and_shrink_string(label_filename, 70, true);
            }
            else label_filename = parent.custom_info_msg;
        }
        
        if (parent.seq.getTickLength() > 0) meter_midi_pos = map(parent.seq.getTickPosition(), 0, parent.seq.getTickLength(), 0.0, 1.0);
        label_message = player.last_text_message;    
        label_message = check_and_shrink_string(label_message, 34);    // we don't want it to get out of the rectangle...
        
        if (parent.playing_state != -1) {
            meter_loop_begin = map(parent.seq.getLoopStartPoint(), 0, player.seq.getTickLength(), 0.0, 1.0);
            if (parent.seq.getLoopEndPoint() == -1) meter_loop_end = 1.0;
            else meter_loop_end = map(parent.seq.getLoopEndPoint(), 0, player.seq.getTickLength(), 0.0, 1.0);
            
            long secLen = player.seq.getMicrosecondLength() / 1000000;
            long secPos = player.seq.getMicrosecondPosition() / 1000000;
            //this.label_timestamp = ((secPos < 0 && secPos > -60) ? "-" : "") + secPos / 60 + ":" + String.format("%02d", Math.abs(secPos % 60));
            this.label_timestamp = remaining_instead_of_elapsed ? 
                ("-" + (secPos - secLen) / -60 + ":" + String.format("%02d", -(secPos - secLen) % 60)) : 
                (secPos / 60 + ":" + String.format("%02d", secPos % 60));
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
        
        /*label_GM = parent.file_is_GM;
        label_GM2 = parent.file_is_GM2;
        label_XG = parent.file_is_XG;
        label_GS = parent.file_is_GS;*/
        
        if (win_plist != null) {
            if (win_plist.items.isEmpty()) queue_bottom_str = "Empty";
            else {
                if (!win_plist.active) queue_bottom_str = "Off";
                else queue_bottom_str = (win_plist.current_item+1) + " of " + win_plist.items.size();
            }
        }
    }
    
    
    void check_buttons(int mButton) {
        check_buttons(mButton, false);
    }
    
    
    void check_buttons(int mButton, boolean dragged) {
        if (mButton == LEFT) {
            if(b_loop.collided() && !dragged) {
                if (parent.seq == null) return;
                
                int n = b_loop.pressed ? 0 : -1;
                parent.seq.setLoopCount(n);
                b_loop.set_pressed(!b_loop.pressed);
            }
            
            if (parent.playing_state == -1) return;
            
            if (collided_posbar()) {
                if (parent.playing_state == -1) return;
                int new_pos = int( map(mouseX, x + POS_X_POSBAR, x + POS_X_POSBAR + WIDTH_POSBAR, 0, parent.seq.getTickLength()) );
                int snap = snap_pos_mult * (player.is_song_long() ? 2 : 1);
                parent.setTicks(snap_number(new_pos, player.midi_resolution*snap));
                return;
            }
            
            int handle_no = collided_loopset_bar();
            try {
                int snap = snap_loop_mult * (player.is_song_long() ? 2 : 1);
                
                if (handle_no == -1) {
                    int new_pos = int( map(mouseX, x + POS_X_POSBAR, x + POS_X_POSBAR + WIDTH_POSBAR, 0, parent.seq.getTickLength()) );
                    parent.seq.setLoopStartPoint(snap_number(new_pos, player.midi_resolution*snap));
                }
                
                else if (handle_no == 1) {
                    int new_pos = int( map(mouseX, x + POS_X_POSBAR, x + POS_X_POSBAR + WIDTH_POSBAR, 0, parent.seq.getTickLength()) );
                    parent.seq.setLoopEndPoint(snap_number(new_pos, player.midi_resolution*snap));
                }
            }
            catch (IllegalArgumentException iae) { }
            
            if (b_metadata.collided() && !dragged) {
                ui.showTableImmutable(parent.get_metadata_table(), Arrays.asList("Parameter", "Value"), "Files' metadata");
            }
            
            if (win_plist != null && !dragged) {
                if (b_prev.collided()) {
                    win_plist.previous();
                }
                
                else if (b_next.collided()) {
                    win_plist.next();
                }
            }
        }
        
        else if (mouseButton == RIGHT) {
            if (b_loop.collided() && !dragged) {
                parent.reset_looppoints();
            }
        }
    }
    
    
    void redraw(boolean renew_values) {
        if (renew_values) update_all_values();
        
        /*fill(t.theme[2]);
        noStroke();
        rect(58, y+42, 600, 20);
        strokeWeight(1);*/
        
        // Pos meter
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x + POS_X_POSBAR, y + POS_Y_POSBAR, WIDTH_POSBAR, HEIGHT_POSBAR, 6);
            noStroke();
            fill(t.theme[3]);
            rect(x+1 + POS_X_POSBAR, y+1 + POS_Y_POSBAR, (WIDTH_POSBAR-1) * meter_midi_pos, HEIGHT_POSBAR-1, 6);
        
        // Song pos and length labels
            textAlign(CENTER, CENTER);
            fill(t.theme[4]);
            textFont(fonts[4]);
            int auxX = x + POS_X_POSBAR + WIDTH_POSBAR/2;
            int auxY = y + POS_Y_POSBAR + 9;
            outlinedText(label_timestamp + " / " + label_timelength, auxX, auxY, t.theme[4], t.theme[0] - color(0x40000000));
            if (show_key_hints) {
                textFont(fonts[0]);
                text("<-      ->", auxX - 29, auxY + 11);
            }
        
        // Loop set meter
            fill(parent.seq.getLoopCount() == 0 ? t.theme[1] : t.theme[3]);
            stroke(t.theme[0]);
            triangle(meter_loop_begin_X, meter_loop_begin_Y, meter_loop_begin_X - 4, meter_loop_begin_Y - 16, meter_loop_begin_X + 4, meter_loop_begin_Y - 16);
            triangle(meter_loop_end_X, meter_loop_end_Y, meter_loop_end_X - 4, meter_loop_end_Y + 16, meter_loop_end_X + 4, meter_loop_end_Y + 16);
            
        // File name label
            fill(t.theme[0]);
            textFont(fonts[5]);
            text(label_filename, 362, y + POS_Y_POSBAR - 18);
        
        // Messages label
            stroke(t.theme[0]);
            fill(t.theme[1]);
            rect(x + POS_X_MESSAGEBAR, y + POS_Y_POSBAR, WIDTH_MESSAGEBAR, HEIGHT_POSBAR, 6);    // reusing some dimensions...
            fill(t.theme[4]);
            textFont(fonts[1]);
            text(label_message, x + POS_X_MESSAGEBAR + WIDTH_MESSAGEBAR/2, auxY);
            if (show_key_hints) {
                textFont(fonts[0]);
                text("n", x + POS_X_MESSAGEBAR + WIDTH_MESSAGEBAR/2, auxY + 11, t.theme[4]);
            }
        
        // SF2 load DnD section
            fill(t.theme[1] - 0x7f000000);
            stroke(t.theme[0]);
            rect(width-138, 8, 116, 48, 6);
            fill(t.theme[4]);
            textFont(fonts[0]);
            textAlign(CENTER, TOP);
            text(
                "• Soundfont load •\n" + 
                (parent.system_synth ? ("Java synth:\n" + player.sf_filename) : "\nOsc synth"),
                width-80, 16
            );
            if (show_key_hints) text("F4 / s", width-80, 52);
        
        // Playlist section
            fill(t.theme[1] - 0x7f000000);
            rect(40, 8, 70, 48, 6);
            fill(t.theme[4]);
            text("• Queue •\n\n" + queue_bottom_str, 75, 16);
            if (show_key_hints) text("F5", 75, 52);
        
        b_metadata.redraw();
        b_loop.redraw();
        b_prev.redraw();
        b_next.redraw();
    }
    
    
    boolean collided_posbar() {
        return (mouseX > x + POS_X_POSBAR && mouseX < WIDTH_POSBAR + x + POS_X_POSBAR) && (mouseY > y + POS_Y_POSBAR && mouseY < HEIGHT_POSBAR + y + POS_Y_POSBAR);
    }
    
    int collided_loopset_bar() {
        int which = 0;    // 0 is not pressed
        if (parent.seq.getLoopCount() == 0) return 0;
        
        if ((mouseX > x + POS_X_POSBAR - 6 && mouseX < WIDTH_POSBAR + x + POS_X_POSBAR + 6) && (mouseY > y + POS_Y_POSBAR - 16 && mouseY < y + POS_Y_POSBAR)) {
            which = -1;    // -1 is begin
        }
        else if ((mouseX > x + POS_X_POSBAR - 6 && mouseX < WIDTH_POSBAR + x + POS_X_POSBAR + 6) && (mouseY > y + POS_Y_POSBAR + HEIGHT_POSBAR && mouseY < y + POS_Y_POSBAR + HEIGHT_POSBAR + 16)) {
            which = 1;    // 1 is end
        }
        
        return which;
    }
    
    
    boolean collided_sfload_rect() {
        return (mouseX > width-138 && mouseX < width-20) && (mouseY > 8 && mouseY < 56);
    }
    
    boolean collided_queue_rect() {
        return (mouseX > 48 && mouseX < 102) && (mouseY > 8 && mouseY < 56);
    }
    
    boolean collided_metamsg_rect() {
        return (mouseX > x + POS_X_MESSAGEBAR && mouseX < width-50) && (mouseY > y + POS_Y_POSBAR && mouseY < y + POS_Y_POSBAR + HEIGHT_POSBAR);
    }
}


class Knob {
    int x, y;
    boolean show_label = true;
    boolean show_value_hint = false;
    String label;
    float value = 0;
    float lower_bound, upper_bound, neutral_value;
    
    int METER_LENGTH = 12;
    int METER_LENGTH_EXTRA = 16;
    
    
    Knob(int x, int y, String label, float lower_bound, float upper_bound, float neutral_value) {
        this.x = x;
        this.y = y;
        this.label = label;
        
        this.lower_bound = lower_bound;
        this.upper_bound = upper_bound;
        this.neutral_value = neutral_value;
        this.value = neutral_value;
    }
    
    
    void set_value(int value) {
        this.value = value;
    }
    
    
    void redraw() {
        redraw(PARENT);
    }
    
    
    void redraw(PApplet win) {
        win.fill(t.theme[0]);
        win.textAlign(CENTER, BOTTOM);
        win.textFont(fonts[0], 12);
        if (show_label) win.text(label, x, y - 2);
        
        win.ellipseMode(CENTER);
        win.fill(t.theme[1]);
        win.stroke(t.theme[0]);
        win.strokeWeight(2);
        win.circle(x, y+16, 32);
        win.strokeWeight(1);
        win.line(x, y, x, y + 6);
        win.stroke(t.theme[3]);
        win.strokeWeight(3);
        float angle = radians( map(value - neutral_value, -1.0, 1.0, -150, -30) );
        win.line(x, y+16, x + METER_LENGTH*cos(angle), y+16 + METER_LENGTH*sin(angle));
        
        win.textAlign(CENTER, CENTER);
        win.fill(#00ff00);
        angle = radians( map(lower_bound - neutral_value, -1.0, 1.0, -150, -30) );
        win.text("•", x + METER_LENGTH_EXTRA*cos(angle), y+16 + METER_LENGTH_EXTRA*sin(angle));
        win.fill(#ff0000);
        angle = radians( map(upper_bound - neutral_value, -1.0, 1.0, -150, -30) );
        win.text("•", x + METER_LENGTH_EXTRA*cos(angle), y+16 + METER_LENGTH_EXTRA*sin(angle));
        
        if (show_value_hint) {
            win.fill(t.theme[0]);
            win.text(nf(value, 1, 1), x, y + 40);
        }
    }
    
    
    boolean collided() {
        return collided(PARENT);
    }
    
    boolean collided(PApplet win) {
        return (win.mouseX > this.x-16 && win.mouseX < + this.x+16) && (win.mouseY > this.y && win.mouseY < + this.y+32);
    }
}


class Button {
    int x, y, width, height;
    String icon_filename, label;
    String shortcut = "";
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
    
    
    void set_key_hint(String shortcut) {
        this.shortcut = shortcut;
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
        redraw(PARENT);
    }
    
    
    void redraw(PApplet win) {
        win.image(texture, x, y);
        win.fill(t.theme[0]);
        win.textAlign(CENTER, BOTTOM);
        win.textFont(fonts[0], 12);
        if (show_label) win.text(label, x + this.width / 2, y - 2);
        if (show_key_hints) {
            win.fill(t.theme[4]);
            win.text(shortcut, x + this.width / 2 + 1, y + this.height + 4);
        }
    }
    
    
    void redraw_at_pos(int x, int y) {
        redraw_at_pos(x, y, PARENT);
    }
    
    
    void redraw_at_pos(int x, int y, PApplet win) {
        this.x = x;
        this.y = y;
        redraw(win);
    }


    boolean collided() {
        return collided(PARENT);
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
        redraw(PARENT);
    }
    
    void redraw(PApplet win) {
        for (Button b : buttons.values()) b.redraw(win);
    }


    boolean collided(String b_name) {
        return collided(b_name, PARENT);
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


void gradientRect(int x, int y, int w, int h, int c1, int c2, int axis, PApplet win) {
    win.noFill();

    if (axis == 0) {  // Top to bottom gradient
      for (int i = y; i <= y+h; i++) {
        float inter = map(i, y, y+h, 0, 1);
        color c = lerpColor(c1, c2, inter);
        win.stroke(c);
        win.line(x, i, x+w, i);
      }
    }
    
    else if (axis == 1) {  // Left to right gradient
      for (int i = x; i <= x+w; i++) {
        float inter = map(i, x, x+w, 0, 1);
        color c = lerpColor(c1, c2, inter);
        win.stroke(c);
        win.line(i, y, i, y+h);
      }
    }
}

// could be worse...
int marquee_timer = 0;
int marquee_start = 0;
int MARQUEE_MAX_LENGTH = 148;
boolean marquee_awaiting_return = true;
String last_txt = "";
void marqueeText(String txt, int x, int y, PApplet win) {
    if (!txt.equals(last_txt)) {
        marquee_start = 0;
        marquee_awaiting_return = true;
        last_txt = txt;
    }
    if (MARQUEE_MAX_LENGTH > text_width(txt)) {
        win.text(txt, x, y);
        return;        
    }
    win.text(txt, x - marquee_start, y);
    
    if (marquee_timer > (marquee_awaiting_return ? 60 : 1)) {
        marquee_timer = 0;
        marquee_start++;
        if (marquee_start >= text_width(txt) - MARQUEE_MAX_LENGTH || marquee_awaiting_return) {
            if (!marquee_awaiting_return) marquee_awaiting_return = true;
            else {
                if (marquee_start <= 1) marquee_awaiting_return = false;
                marquee_start = 0;
            }
        }
    }
    marquee_timer++;
}


int text_width(String txt) {
    return txt.length() * 8;
}
