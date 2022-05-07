import processing.sound.*;
import java.util.Stack;


public class ChannelOsc {
    int id;
    HashMap<Integer, SoundObject> current_notes;    // Pairs <note midi code, oscillator object>
    float curr_global_amp = 1.0;    // channel volume (0.0 to 1.0)
    float amp_multiplier = 1.0;     // basically expression
    float curr_global_bend = 0.0;   // channel pitch bend (-curr_bend_range to curr_bend_range semitones)
    float curr_global_pan = 0.0;    // channel stereo panning (-1.0 to 1.0)
    float curr_bend_range = 2.0;    // channel pitch bend range +/- semitones... uh, sure.
    boolean hold_pedal = false;
    boolean sostenuto_pedal = false;
    boolean soft_pedal = false;
    ArrayList<Integer> curr_holding;
    ArrayList<Integer> curr_sostenuting;
    float curr_freqDetune = 0.0;
    float curr_noteDetune = 0.0;
    String please_how_many_midi_params_are_there = "dw, around 100+";    // darn.
    boolean silenced = false;       // mute button
    int osc_type;
    Oscillator osc;
    float pulse_width = 0.5;
    ChannelDisplay disp;
    
    final int CIRCULAR_ARR_SIZE = 16;
    
    // values to be read by the display...:
    float last_amp = 0.0;
    float last_freq = 0;
    int last_notecode = -1;
    int midi_program = 0;
    
    
    ChannelOsc() {
        current_notes = new HashMap<Integer, SoundObject>();
        curr_holding = new ArrayList();
        curr_sostenuting = new ArrayList();
    }
    
    
    ChannelOsc(int osc_type) {
        current_notes = new HashMap<Integer, SoundObject>();
        curr_holding = new ArrayList();
        curr_sostenuting = new ArrayList();
        set_osc_type(osc_type);
    }
    
    
    void create_display(int x, int y, int id) {
        ChannelDisplay d = new ChannelDisplay(x, y, id, this);
        this.disp = d;
        this.id = id;
    }
    
    
    void redraw_playing() {
        this.disp.redraw(true);    // draw meters with updated values
    }
    
    
    protected float midi_to_freq(float note_code) {
        return (440 / 32.0) * pow(2, ((note_code - 9) / 12.0));
    }

    protected int freq_to_midi(int freq) {
        return int( 69 + 12 * (log(freq / 440.0)/log(2)) );
    }
    
    
    void play_note(int note_code, int velocity) {
        if (curr_global_amp <= 0 || silenced || osc_type == -1) return;
        if (osc_type == 4) {
            play_drum(note_code, velocity);
            return;
        }
        stop_note(note_code);
        
        float mod_note_code =  note_code + curr_noteDetune + player.ktrans.transform[(note_code - 2 + player.mid_rootnote) % 12];
        float freq = midi_to_freq(mod_note_code);
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        Oscillator s = (Oscillator) current_notes.get(note_code);
        if (s == null) {
            s = get_new_osc(this.osc_type);
            s.freq(freq + curr_freqDetune);
            current_notes.put(note_code, s);
        }
        s.pan(curr_global_pan);
        s.amp(amp * (osc_type == 1 || osc_type == 2 ? 0.12 : 0.05) * curr_global_amp * amp_multiplier * (soft_pedal ? 0.5 : 1));    // give a volume boost to TRI and SIN
        if (osc_type == 0) ((Pulse) s).width(pulse_width);
        
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
        if (s.isPlaying()) stop_note(note_code);
        
        s.amp(amp * 0.32 * curr_global_amp * amp_multiplier * (soft_pedal ? 0.5 : 1));
        s.play();
        
        last_amp = amp;
        last_freq = sample_code;
        last_notecode = note_code;
    }
    
    
    void stop_note(int note_code) {
        if (hold_pedal) {
            curr_holding.add(note_code);
            return;
        }
        if (sostenuto_pedal && curr_sostenuting.contains(note_code)) {
            return;
        }
        
        if (osc_type != 4) {
            SoundObject s = current_notes.get(note_code);
            if (s == null) return;
            s.stop();
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
            for (Entry<Integer, SoundObject> s : this.current_notes.entrySet()) {
                if (((Oscillator) s.getValue()).isPlaying()) {
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
        for (SoundObject s : current_notes.values()) {
            ((Oscillator) s).amp((osc_type == 1 || osc_type == 2 ? 0.12 : 0.05) * curr_global_amp * amp_multiplier * (soft_pedal ? 0.5 : 1));
        }
    }
    
    
    void set_bend(int bits_lsb, int bits_msb) {
        if (osc_type == 4) return; // no bend for drums...
        
        int value = (bits_msb << 7) + bits_lsb;
        curr_global_bend = map(value, 0, 16383, -1.0, 1.0) * curr_bend_range;
        float freq_ratio = (float) Math.pow(2, curr_global_bend / 12.0); 
        
        for (Entry<Integer, SoundObject> s_pair : current_notes.entrySet()) {
            float new_freq = midi_to_freq(s_pair.getKey() + curr_noteDetune) * freq_ratio;
            ((Oscillator) s_pair.getValue()).freq(new_freq + curr_freqDetune);
            last_freq = new_freq;
        }
    }
    
    
    void set_pan(int value) {
        curr_global_pan = map(value, 0, 127, -1.0, 1.0);
        
        for (SoundObject s : current_notes.values()) {
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
        for (int note_code : current_notes.keySet()) stop_note(note_code);
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
