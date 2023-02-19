import processing.sound.*;
import java.util.Stack;
import java.util.ConcurrentModificationException;


public class ChannelOsc {
    int id;
    HashMap<Integer, RTSoundObject> current_notes;    // Pairs <note midi code, oscillator object>
    float curr_global_amp = 1.0;    // channel volume (0.0 to 1.0)
    float amp_multiplier = 1.0;     // basically expression
    float curr_global_bend = 0.0;   // channel pitch bend (-curr_bend_range to curr_bend_range semitones)
    float bend_freq_ratio = 1.0;
    float curr_global_pan = 0.0;    // channel stereo panning (-1.0 to 1.0)
    float curr_bend_range = 2.0;    // channel pitch bend range +/- semitones... uh, sure.
    boolean hold_pedal = false;
    boolean sostenuto_pedal = false;
    boolean soft_pedal = false;
    ArrayList<Integer> curr_holding;
    ArrayList<Integer> curr_sostenuting;
    float curr_freqDetune = 0.0;
    float curr_noteDetune = 0.0;
    boolean silenced = false;       // mute button
    int osc_type;
    Oscillator osc;
    float pulse_width = 0.5;
    ChannelDisplay disp;
    
    // values to be read by the display...:
    float last_amp = 0.0;
    float last_freq = 0;
    int last_notecode = -1;
    int midi_program = 0;
    
    
    ChannelOsc() {
        current_notes = new HashMap<Integer, RTSoundObject>();
        curr_holding = new ArrayList();
        curr_sostenuting = new ArrayList();
    }
    
    
    ChannelOsc(int osc_type) {
        current_notes = new HashMap<Integer, RTSoundObject>();
        curr_holding = new ArrayList();
        curr_sostenuting = new ArrayList();
        set_osc_type(osc_type);
    }
    
    
    void create_display(int x, int y, int id) {
        ChannelDisplay d;
        d = new ChannelDisplay(x, y, id, this);
        this.disp = d;
        this.id = id;
    }
    
    
    void redraw_playing() {
        this.disp.redraw(true);    // draw meters with updated values
        try {
            for (RTSoundObject s : current_notes.values()) {
                s.tick();
            }
        }
        catch (ConcurrentModificationException cme) {
            print("cme");
            return;
        }
    }
    
    
    protected float midi_to_freq(float note_code) {
        return (440 / 32.0) * pow(2, ((note_code - 9) / 12.0));
    }

    protected int freq_to_midi(int freq) {
        return int( 69 + 12 * (log(freq / 440.0)/log(2)) );
    }
    
    
    void play_note(int note_code, int velocity) {
        if (curr_global_amp <= 0 || silenced) return;
        if (osc_type == -1) {
            set_osc_type(1);
            println("P3synth warning: a note was played on a channel with no instrument.");
        }
        if (osc_type == 4) {
            play_drum(note_code, velocity);
            return;
        }
        stop_note(note_code);
        
        float mod_note_code = note_code + curr_noteDetune;
        float freq = midi_to_freq(mod_note_code);
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        RTSoundObject s = current_notes.get(note_code);
        if (s == null) {
            s = new RTSoundObject(get_new_osc(this.osc_type));
            s.freq((freq + curr_freqDetune) * bend_freq_ratio);
            current_notes.put(note_code, s);
        }
        s.pan(curr_global_pan);
        s.amp(amp * (osc_type == 1 || osc_type == 2 ? 0.12 : 0.05) * curr_global_amp * amp_multiplier * (soft_pedal ? 0.5 : 1) * player.osc_synth_volume_mult);    // give a volume boost to TRI and SIN
        if (osc_type == 0) ((Pulse) s.osc).width(pulse_width);
        
        s.play();
        
        last_amp = amp;
        last_freq = freq;
        last_notecode = floor(mod_note_code);
    }
    
    
    void play_drum(int note_code, int velocity) {
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        int sample_code = note_code_to_percussion(note_code);
        SoundFile s = (SoundFile) samples[sample_code-1];
        if (s == null) return;
        if (s.isPlaying()) s.stop();
        
        s.pan(curr_global_pan);
        s.amp(amp * 0.2 * curr_global_amp * amp_multiplier * (soft_pedal ? 0.5 : 1) * player.osc_synth_volume_mult);
        s.play();
        
        last_amp = amp;
        last_freq = sample_code;
        last_notecode = note_code;
    }
    
    
    void stop_note(int note_code) {
        stop_note(note_code, false);
    }
    
    
    void stop_note(int note_code, boolean force) {
        /* if (hold_pedal) {
            curr_holding.add(note_code);
            return;
        }
        if (sostenuto_pedal && curr_sostenuting.contains(note_code)) {
            return;
        } */ // really disliking how this sounds lol
        
        if (osc_type != 4) {
            RTSoundObject s = current_notes.get(note_code);
            if (s == null) return;
            s.stop(force);
        }
        
        last_amp = 0.0;
        last_freq = 0.0;
        last_notecode = -1;
    }
    
    
    void set_hold(int value) {
        if (osc_type == 4) return;
        hold_pedal = value < 63 ? false : true;
        if (!hold_pedal) {
            for (int note_code : curr_holding) {
                stop_note(note_code);
            }
            curr_holding.clear();
        }
    }
    
    
    void set_sostenuto(int value) {
        if (osc_type == 4) return;
        sostenuto_pedal = value < 63 ? false : true;
        if (sostenuto_pedal) {
            for (Entry<Integer, RTSoundObject> s : this.current_notes.entrySet()) {
                if (s.getValue().osc.isPlaying()) {
                    curr_sostenuting.add(s.getKey());
                }
            }
        }
        else {
            for (int note_code : curr_sostenuting) {
                stop_note(note_code);
            }
            curr_sostenuting.clear();
        }
    }
    
    
    void set_soft(int value) {
        soft_pedal = value < 63 ? false : true;
        set_all_oscs_amp();
    }
    
    
    void set_osc_type(float osc_type) {    // if 0.0 < value < 1.0, then pulse osc
        shut_up();
        current_notes.clear();
        
        if (osc_type > 0.0 && osc_type < 1.0) {
            this.osc_type = 0;
            this.pulse_width = constrain(osc_type, 0.1, 0.9);    // pulse width can only be in this range...
        }
        else this.osc_type = int(osc_type);
    }
    
    
    void set_expression(int value) {
        if (value <= 0) shut_up();
        
        amp_multiplier = map(value, 0, 127, 0.0, 1.0);
        if (osc_type != 4) set_all_oscs_amp();
    }
    
    
    void set_volume(int value) {
        curr_global_amp = map(value, 0, 127, 0.0, 1.0);
        if (osc_type != 4) set_all_oscs_amp();
    }
    
    
    void set_all_oscs_freqDetune(float value) {
        shut_up();
        current_notes.clear();
        curr_freqDetune = value;
    }
    
    void set_all_oscs_noteDetune(float value) {
        shut_up();
        current_notes.clear();
        curr_noteDetune = value;
    }
    
    
    void set_all_oscs_amp() {
        for (RTSoundObject s : current_notes.values()) {
            s.amp((osc_type == 1 || osc_type == 2 ? 0.12 : 0.05) * curr_global_amp * amp_multiplier * (soft_pedal ? 0.5 : 1) * last_amp);
        }
    }
    
    
    void set_bend(int bits_lsb, int bits_msb) {
        if (osc_type == 4) return; // no bend for drums...
        
        int value = (bits_msb << 7) + bits_lsb;
        curr_global_bend = map(value, 0, 16383, -1.0, 1.0) * curr_bend_range;
        bend_freq_ratio = (float) Math.pow(2, curr_global_bend / 12.0); 
        
        for (Entry<Integer, RTSoundObject> s_pair : current_notes.entrySet()) {
            float new_freq = midi_to_freq(s_pair.getKey() + curr_noteDetune) * bend_freq_ratio;
            s_pair.getValue().freq(new_freq + curr_freqDetune);
            last_freq = new_freq;
        }
    }
    
    
    void set_pan(int value) {
        curr_global_pan = map(value, 0, 127, -1.0, 1.0);
        
        for (RTSoundObject s : current_notes.values()) {
            s.pan(curr_global_pan);
        }
    }
    
    
    void set_muted(boolean how) {
        if (how) shut_up();
        disp.button_mute.set_pressed(how);
        silenced = how;
        
    }
    
    
    void shut_up() {
        set_hold(0);
        set_sostenuto(0);
        set_soft(0);
        for (int note_code : current_notes.keySet()) stop_note(note_code, true);
    }
    
    
    void reset_params() {
        current_notes.clear();
        curr_holding.clear();
        curr_sostenuting.clear();
        last_amp = 0.0;
        last_freq = 0;
        last_notecode = -1;
        if (id == 9) osc_type = 4;
        else osc_type = -1; 
        pulse_width = 0.5;
        curr_global_amp = 1.0;
        amp_multiplier = 1.0;
        curr_global_bend = 0.0;
        curr_global_pan = 0.0;
        curr_bend_range = 2.0;
        bend_freq_ratio = 1.0;
    }
}



Oscillator get_new_osc(int osc_type) {
    // This notation will be used
    switch (osc_type) {
        case 0:
            return new Pulse(PARENT);
        case 1:
            return new TriOsc(PARENT);
        case 2:
            return new SinOsc(PARENT);
        case 3:
            return new SawOsc(PARENT);
        default:
            return null;
    }
}
