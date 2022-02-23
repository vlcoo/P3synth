import beads.*;
import java.lang.reflect.InvocationTargetException;


String program_to_osc(int prog) {
    if (prog >= 1 && prog <= 8) return "Square";
    if (prog >= 9 && prog <= 16) return "Sine";
    if (prog >= 17 && prog <= 24) return "Triangle";
    if (prog >= 25 && prog <= 32) return "Square";
    if (prog >= 33 && prog <= 40) return "Triangle";
    if (prog >= 41 && prog <= 48) return "Saw";
    if (prog >= 49 && prog <= 56) return "Saw";
    if (prog >= 57 && prog <= 64) return "Saw";
    return "Square";
}


class ChannelBeads extends Channel{
    HashMap<Integer, WavePlayer> current_notes = new HashMap<Integer, WavePlayer>();
    AudioContext AC = AudioContext.getDefaultContext();
    Buffer b;
    Gain gain = new Gain(1, 0.05f);
    
    
    ChannelBeads(Wave32 wave) {
        empty();
        b = wave.generateBuffer(32);
        AC.out.addInput(gain);
        AC.start();
    }
    
    
    void play(int freq, int vel) {
    if(silent) {
      return;
    }
    
    //println(current_notes.toString());
    stop(freq);
    WavePlayer s = current_notes.get(freq);
    last_freq = freq;
    
    if (s == null) {
      s = new WavePlayer(AC, freq, b);
      gain.addInput(s);
    }
    else {
      s.pause(false);
    }
    //SawOsc s = new SawOsc(PARENT);
    //s.freq(freq);
    //s.amp(map(vel, 0, 127, 0, 1) / 2);
    //s.play();
    current_notes.put(freq, s);
  }
  
  
  void bend(int d1, int d2) {
    if(last_freq == 0) return;
    
    int b = (d2 * 128) + d1;
    if(b == 8192) {
      //current_notes.get(last_freq).rate(1);
      current_notes.get(last_freq).setFrequency(last_freq);
      return;
    }
    
    int f = bend_to_freq(last_freq, b);
    //float r = float(f)/float(last_freq);
    //current_notes.get(last_freq).rate(r);
    current_notes.get(last_freq).setFrequency(f);
    /*
    for(AudioSample s : current_notes.values()) {
      s.rate(d1 + d2);
    }
    */
  }
  
  
  void stop(int freq) {
    //println(current_notes.toString());
    WavePlayer s = current_notes.get(freq);
    if (s == null) {
      return;
    }
    
    s.pause(true);
    //current_notes.remove(freq);
  }
  
  
    void init_display(int x, int y, int id) {
        disp = new ChannelDisplay(x, y, id);
    }
  
  
  void empty() {
    for(int freq : current_notes.keySet()) {
        stop(freq);
    }
    current_notes.clear();
  }
  
  
  String toString() {return String.valueOf(current_notes.size());}
}


class ChannelDrum extends Channel {
    processing.sound.Noise noi;
    HashMap<Integer, processing.sound.Noise> current_notes = new HashMap<Integer, processing.sound.Noise>();
    
    ChannelDrum(processing.sound.Noise noise) {
        empty();
        noi = noise;
    }
    
    
    void set_noi(processing.sound.Noise noise) {
        empty();
        noi = noise;
    }
    
    
    void play(int freq, int vel) {
        if(silent) {
          return;
        }
        
        stop(freq);
        processing.sound.Noise s = current_notes.get(freq);
        last_vel = vel;
        
        if (s == null) {
            try {
                Class[] cargs = new Class[1];
                cargs[0] = processing.core.PApplet.class;
                s = (processing.sound.Noise) noi.getClass().getDeclaredConstructor(cargs).newInstance(PARENT);
            }
            catch(NoSuchMethodException nsm) {println(nsm.toString());}
            catch(InstantiationException ie) {println("ie");}
            catch(IllegalAccessException iae) {println("iae");}
            catch(InvocationTargetException ite) {println("ite");}
        }
        //println(last_o);
        last_freq = freq;
        
        s.amp(constrain(map(freq, 0, 100, 0, 1), 0, 1));
        current_notes.put(freq, s);
        s.play();
        delay(15);
        stop(freq);
    }
  
  
  void stop(int freq) {
    //println(current_notes.toString());
    processing.sound.Noise s = current_notes.get(freq);
    last_freq = 0;
    last_vel = 0;
    //last_o = 0.0;
    if (s == null) {
      return;
    }
    
    s.stop();
    //current_notes.remove(freq);
  }
  
  
    void init_display(int x, int y, int id) {
        disp = new ChannelDisplay(x, y, id);
    }
  
  
  void empty() {
    for(int freq : current_notes.keySet()) {
        stop(freq);
    }
    current_notes.clear();
  }
  
  
  String toString() {return String.valueOf(current_notes.size());}
}



class ChannelOsc extends Channel {
    Oscillator osc;
    HashMap<Integer, Oscillator> current_notes = new HashMap<Integer, Oscillator>();
    
    
    ChannelOsc(Oscillator oscillator) {
        empty();
        osc = oscillator;
    }
    
    
    void set_osc(Oscillator oscillator) {
        empty();
        osc = oscillator;
    }
    
    
    void play(int freq, int vel) {
        if(silent) {
          return;
        }
        
        stop(freq);
        Oscillator s = current_notes.get(freq);
        last_vel = vel;
        
        if (s == null) {
            try {
                Class[] cargs = new Class[1];
                cargs[0] = processing.core.PApplet.class;
                s = (Oscillator) osc.getClass().getDeclaredConstructor(cargs).newInstance(PARENT);
            }
            catch(NoSuchMethodException nsm) {println(nsm.toString());}
            catch(InstantiationException ie) {println("ie");}
            catch(IllegalAccessException iae) {println("iae");}
            catch(InvocationTargetException ite) {println("ite");}
        }
        //println(last_o);
        last_freq = freq;
        
        s.freq(freq);
        s.amp(map(vel, 0, 127, 0, 1) / 6);
        s.play();
        current_notes.put(freq, s);
    }
  
  
  void bend(int d1, int d2) {
    if(last_freq == 0) return;
    
    int b = (d2 * 128) + d1;
    if(b == 8192) {
      //current_notes.get(last_freq).rate(1);
      current_notes.get(last_freq).freq(last_freq);
      return;
    }
    
    int f = bend_to_freq(last_freq, b);
    //float r = float(f)/float(last_freq);
    //current_notes.get(last_freq).rate(r);
    current_notes.get(last_freq).freq(f);
    last_bend = f - last_freq;
    /*
    for(AudioSample s : current_notes.values()) {
      s.rate(d1 + d2);
    }
    */
  }
  
  
  void stop(int freq) {
    //println(current_notes.toString());
    Oscillator s = current_notes.get(freq);
    last_freq = 0;
    last_vel = 0;
    //last_o = 0.0;
    if (s == null) {
      return;
    }
    
    s.stop();
    //current_notes.remove(freq);
  }
  
  
    void init_display(int x, int y, int id) {
        //if (disp != null) return;
        disp = new ChannelDisplay(x, y, id);
    }
  
  
  void empty() {
    for(int freq : current_notes.keySet()) {
        stop(freq);
    }
    current_notes.clear();
  }
  
  
  String toString() {return String.valueOf(current_notes.size());}
}



class Channel {
    int extended_sample_factor = 1;    // 1 is original size of wave32
    float[] wave_data = new float[extended_sample_factor * 32];
    HashMap<Integer, AudioSample> current_notes = new HashMap<Integer, AudioSample>();
    boolean silent = false;
    int last_freq = 0;
    int last_vel = 0;
    int last_bend = 0;
    ChannelDisplay disp;
    Amplitude o_analyzer = new Amplitude(PARENT);
    
    
    Channel() {
        
    }
    
    
    Channel(Wave32 wave) {
        empty();
        if (wave == null) return;
        float[] non_ext_wave = wave.get_wave();
        // e x t e n d    sample so AudioSample doesn't loop so frequently...
        for(int i = 0; i < extended_sample_factor * 32; i++) {
            wave_data[i] = non_ext_wave[i % 32];
        }
    }
    
    
    void play(int freq, int vel) {
        if(silent) {
            return;
        }
        
        //println(current_notes.toString());
        stop(freq);
        AudioSample s = current_notes.get(freq);
        last_freq = freq;
        
        if (s == null) {
            s = new AudioSample(PARENT, wave_data, freq * 32);
        }
        
        s.loop();
        //SawOsc s = new SawOsc(PARENT);
        //s.freq(freq);
        s.amp(map(vel, 0, 127, 0, 1) / 4);
        //s.play();
        current_notes.put(freq, s);
    }
    
    
    private int freq_to_midi(int freq) {
        return int( 69 + 12 * (log(freq / 440.0)/log(2)) );
    }
    
    
    protected int bend_to_freq(int freq, int pitchbend) {
        int note_code = freq_to_midi(freq);
        float df = 100.0/8192.0/1200.0;
        return int( (440/64.0) * pow(2, ((note_code+3)/12.0 + df*(pitchbend))) );
        //return int( 440 * pow(2, ((note_code-69) / 12.0) + ((pitchbend-8192) / (4096.0*12.0))) );
    }
    
    
    void bend(int d1, int d2) {
        if(last_freq == 0) return;
        
        int b = (d2 * 128) + d1;
        if(b == 8192) {
            current_notes.get(last_freq).rate(1);
            return;
        }
        
        int f = bend_to_freq(last_freq, b);
        float r = float(f)/float(last_freq);
        current_notes.get(last_freq).rate(r);
        /*
        for(AudioSample s : current_notes.values()) {
            s.rate(d1 + d2);
        }
        */
    }
    
    
    void stop(int freq) {
        //println(current_notes.toString());
        AudioSample s = current_notes.get(freq);
        if (s == null) {
            return;
        }
        
        s.stop();
        //current_notes.remove(freq);
    }
    
    
    void init_display(int x, int y, int id) {
        disp = new ChannelDisplay(x, y, id);
    }
    
    
    void empty() {
        for(int freq : current_notes.keySet()) {
            stop(freq);
        }
        current_notes.clear();
    }
    
    
    @Override
    String toString() {
        return String.valueOf(current_notes.size());
    }
} 
