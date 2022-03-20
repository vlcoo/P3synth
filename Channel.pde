import processing.sound.*;


public class ChannelOsc {
    HashMap<Integer, SoundObject> current_notes;    // Pairs <note midi code, oscillator object>
    Env[] circular_array_envs;
    int curr_env_index = 0;
    float curr_global_amp = 1.0;    // channel volume (0.0 to 1.0)
    float amp_multiplier =  1.0;    // basically expression
    float curr_global_bend = 0.0;   // channel pitch bend (-curr_bend_range to curr_bend_range semitones)
    float curr_global_pan = 0.0;    // channel stereo panning (-1.0 to 1.0)
    float curr_bend_range = 2.0;    // channel pitch bend range +/- semitones... uh, sure.
    float curr_detune = 0.0;
    String please_how_many_midi_params_are_there = "dw, around 100+";    // darn.
    boolean silenced = false;       // mute button
    int osc_type;
    float[] env_values;
    Oscillator osc;
    float pulse_width = 0.5;
    ChannelDisplay disp;
    
    final int CIRCULAR_ARR_SIZE = 32;
    
    // values to be read by the display...:
    float last_amp = 0.0;
    float last_freq = 0;
    int last_notecode = -1;
    
    
    ChannelOsc() {
        current_notes = new HashMap<Integer, SoundObject>();
        circular_array_envs = new Env[CIRCULAR_ARR_SIZE];
    }
    
    
    ChannelOsc(int osc_type) {
        current_notes = new HashMap<Integer, SoundObject>();
        circular_array_envs = new Env[CIRCULAR_ARR_SIZE];
        set_osc_type(osc_type);
    }
    
    
    void create_display(int x, int y, int id) {
        ChannelDisplay d = new ChannelDisplay(x, y, id, this);
        this.disp = d;
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
        if (curr_global_amp <= 0 || silenced) return;
        stop_note(note_code);
        
        float freq = midi_to_freq(note_code);
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        Oscillator s = (Oscillator) current_notes.get(note_code);
        if (s == null) {
            s = get_new_osc(this.osc_type);
            s.freq(freq + curr_detune);
            s.pan(curr_global_pan);
            s.amp(amp * (osc_type == 1 || osc_type == 2 ? 0.12 : 0.05) * curr_global_amp * amp_multiplier);    // give a volume boost to TRI and SIN
            current_notes.put(note_code, s);
        }
        
        /*Env e = circular_array_envs[curr_env_index];
        if (e == null) {
            e = new Env(PARENT);
            circular_array_envs[curr_env_index] = e;
        }*/
        if (osc_type == 0) ((Pulse) s).width(pulse_width);
        
        if (env_values != null && env_values.length == 3) {
            Env e = new Env(PARENT);
            e.play(s, env_values[0], env_values[1], 1.0, env_values[2]);    // will come back to envelopes... great potential but buggy :(
        }
        else s.play();
        
        last_amp = amp;
        last_freq = freq;
        last_notecode = note_code;
        /*curr_env_index++;
        if (curr_env_index >= CIRCULAR_ARR_SIZE) curr_env_index = 0;*/
    }
    
    
    void stop_note(int note_code) {
        SoundObject s = current_notes.get(note_code);
        if (s == null) return;
        s.stop();
        
        last_amp = 0.0;
        last_freq = 0.0;
        last_notecode = -1;
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
    
    void set_env_values(float[] env_values) {
        this.env_values = env_values;
    }
    
    
    void set_expression(int value) {
        amp_multiplier = map(value, 0, 127, 0.0, 1.0);
        set_all_oscs_amp();
    }
    
    
    void set_volume(int value) {
        curr_global_amp = map(value, 0, 127, 0.0, 1.0);
        set_all_oscs_amp();
    }
    
    
    void set_all_oscs_detune(float value) {
        shut_up();
        current_notes.clear();
        curr_detune = value;
    }
    
    
    void set_all_oscs_amp() {
        for (SoundObject s : current_notes.values()) {
            ((Oscillator) s).amp((osc_type == 1 || osc_type == 2 ? 0.12 : 0.05) * curr_global_amp * amp_multiplier);
        }
    }
    
    
    void set_bend(int bits_lsb, int bits_msb) {
        // i can't believe i finally achieved this...
        int value = (bits_msb << 7) + bits_lsb;
        curr_global_bend = map(value, 0, 16383, -1.0, 1.0) * curr_bend_range;
        float freq_ratio = (float) Math.pow(2, curr_global_bend / 12.0); 
        
        for (Entry<Integer, SoundObject> s_pair : current_notes.entrySet()) {
            float new_freq = midi_to_freq(s_pair.getKey()) * freq_ratio;
            ((Oscillator) s_pair.getValue()).freq(new_freq + curr_detune);
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
        silenced = how;
        disp.button_mute.set_pressed(how);
    }
    
    
    void shut_up() {
        for (int note_code : current_notes.keySet()) stop_note(note_code);
    }
    
    
    void reset_params() {
        current_notes.clear();
        last_amp = 0.0;
        last_freq = 0;
        last_notecode = -1;
        osc_type = -1; 
        pulse_width = 0.5;
        curr_global_amp = 1.0;
        amp_multiplier = 1.0;
        curr_global_bend = 0.0;
        curr_global_pan = 0.0;
        curr_bend_range = 2.0;
    }
}



class ChannelOscDrum extends ChannelOsc {
    SoundFile[] samples;
    
    
    ChannelOscDrum() {
        super();
        
        // preloading samples...
        samples = new SoundFile[4];
        for (int i = 1; i <= samples.length; i++) {
            samples[i-1] = new SoundFile(PARENT, "samples/" + i + ".wav");
        }
    }
    
    
    void play_note(int note_code, int velocity) {
        if (curr_global_amp <= 0 || silenced) return;
        
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        int sample_code = note_code_to_percussion(note_code);
        SoundFile s = (SoundFile) samples[sample_code-1];
        if (s == null || s.isPlaying()) return;
        
        s.amp(amp * 0.22 * curr_global_amp);
        s.play();
        
        last_amp = amp;
        last_freq = sample_code;
        last_notecode = note_code;
    }
    
    
    void stop_note(int note_code) {
        last_amp = 0.0;
        last_freq = 0;
        last_notecode = -1;
    }
    
    
    void set_volume(int volume) {
        curr_global_amp = map(volume, 0, 127, 0.0, 1.0);
    }
    
    
    void set_bend(int bits_lsb, int bits_msb) {}    // no bend for drums!!
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
        default:
            return new SawOsc(PARENT);
    }
}
