class RTSoundObject {
    Oscillator osc;
    int playing = 0;
    int osc_type;
    float amp = 1.0;
    float freq = 0.0;
    float enved_amp = 0.0;
    float modded_freq = 0.0;
    float amp_env_start_ticks = 1.0;
    float amp_env_start_curtick = 0.0;
    float amp_env_start_mod = 1.0;
    float amp_env_mid_amp = 1.0;
    float amp_env_end_ticks = 4.0;
    float amp_env_end_curtick = 0.0;
    float amp_env_end_mod = 0.2;
    float freq_mod_mod = 2.0;
    float freq_mod_startafter = 16.0;
    float freq_mod_limit = 4.0;
    float freq_mod_curdir = 1.0;
    float freq_mod_curtick = 0.0;
    
    
    RTSoundObject(Oscillator osc) {
        this.osc = osc;
    }
    
    
    void tick() {
        if (NO_REALTIME || playing == 0) return;
        
        if (freq_mod_curtick >= freq_mod_startafter) {
            modded_freq += freq_mod_mod * freq_mod_curdir;
            if (modded_freq > freq + freq_mod_limit || modded_freq < freq - freq_mod_limit) freq_mod_curdir *= -1;
            osc.freq(modded_freq);
        }
        
        if (playing == 1) {
            if (amp_env_start_curtick <= amp_env_start_ticks) {
                enved_amp += amp_env_start_mod;
                amp_env_start_curtick++;
            }
            else if (enved_amp != amp_env_mid_amp) enved_amp = amp_env_mid_amp;
            osc.amp(constrain(enved_amp, 0, 1) * amp);
        }
        
        else if (playing == -1) {
            if (amp_env_end_curtick <= amp_env_end_ticks) {
                enved_amp -= amp_env_end_mod;
                amp_env_end_curtick++;
                osc.amp(constrain(enved_amp, 0, 1) * amp);
            }
            else {
                osc.stop();
                playing = 0;
                reset_mods_and_envs();
            }
        }
        
        freq_mod_curtick++;
    }
    
    
    void freq(float f) {
        this.freq = f;
        this.modded_freq = f;
        osc.freq(f);
    }
    
    
    void pan(float p) {
        osc.pan(p);
    }
    
    
    void amp(float a) {
        this.amp = a;
        this.enved_amp = 0;
    }
    
    
    void reset_mods_and_envs() {
        osc.freq(freq);
        enved_amp = 0;
        modded_freq = freq;
        amp_env_start_curtick = 0.0;
        amp_env_end_curtick = 0.0;
        freq_mod_curdir = 1.0;
        freq_mod_curtick = 0.0;
    }
    
    
    void play() {
        reset_mods_and_envs();
        if (NO_REALTIME) osc.amp(amp);
        else osc.amp(0);
        osc.play();
        playing = 1;
    }
    
    
    void stop() {
        stop(false);
    }
    
    
    void stop(boolean force) {
        if (force || NO_REALTIME) {
            osc.stop();
            reset_mods_and_envs();
        }
        else playing = -1;
    }
}
