import processing.sound.*;


public class ChannelOsc {
    HashMap<Integer, SoundObject> current_notes;    // Pairs <note midi code, oscillator object>
    float curr_global_amp = 1;    // channel volume
    boolean silenced = false;
    int osc_type;
    Oscillator osc;
    ChannelDisplay disp;
    
    // values to be read by the display...:
    float last_amp = 0.0;
    float last_freq = 0;
    
    
    ChannelOsc() {
        current_notes = new HashMap<Integer, SoundObject>();
    }
    
    
    ChannelOsc(int osc_type) {
        current_notes = new HashMap<Integer, SoundObject>();
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
        
        float freq = midi_to_freq(note_code);
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        Oscillator s = (Oscillator) current_notes.get(note_code);
        if (s == null) {
            s = get_new_osc(this.osc_type);
            current_notes.put(note_code, s);
        }
        
        s.amp(amp * 0.16);
        s.freq(freq);
        s.play();
        
        last_amp = amp;
        last_freq = freq;
    }
    
    
    void stop_note(int note_code) {
        SoundObject s = current_notes.get(note_code);
        if (s == null) return;
        s.stop();
        
        last_amp = 0.0;
        last_freq = 0.0;
    }
    
    
    void set_osc_type(int osc_type) {
        reset();
        this.osc_type = osc_type;
    }
    
    
    void set_volume(int volume) {
        float amp = map(volume, 0, 127, 0.0, 1.0);
        for (SoundObject s : current_notes.values()) {
            ((Oscillator) s).amp(0.16 * amp);
        }
        curr_global_amp = amp;
    }
    
    
    void reset() {
        for (int note_code : current_notes.keySet()) {
            stop_note(note_code);
        }
        current_notes.clear();
        last_amp = 0.0;
        last_freq = 0;
    }
}



class ChannelOscDrum extends ChannelOsc {
    ChannelOscDrum() {
        super();
    }
    
    
    void play_note(int note_code, int velocity) {
        if (curr_global_amp <= 0 || silenced) return;
        stop_note(note_code);
        
        float freq = midi_to_freq(note_code);
        float amp = map(velocity, 0, 127, 0.0, 1.0);
        
        processing.sound.Noise s = (processing.sound.Noise) current_notes.get(note_code);
        if (s == null) {
            s = get_new_noise(note_code);
            current_notes.put(note_code, s);
        }
        
        s.amp(constrain(map(freq, 0, 100, 0.0, 1.0), 0.0, 1.0) * amp);
        s.play();
        delay(15);
        stop_note(note_code);
        
        last_amp = amp;
        last_freq = freq;
    }
}


void threaded_drum_hit(processing.sound.Noise s, int note_code, ChannelOscDrum ch) {
    s.play();
    delay(15);
    ch.stop_note(note_code);
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


processing.sound.Noise get_new_noise(int note_code) {
    return new WhiteNoise(PARENT);
}
