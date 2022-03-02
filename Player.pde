import javax.sound.midi.*;


class Player {
    Sequencer seq;
    PlayerDisplay disp;
    int midi_resolution;
    ChannelOsc[] channels;
    long prev_position;
    String curr_filename;
    boolean stopped = true;
    float vu_anim_val = 0.0;
    boolean vu_anim_returning = false;
    
    
    Player() {
        channels = new ChannelOsc[16];
        
        for (int i = 0; i < 16; i++) {
            channels[i] = new ChannelOsc(-1);
            if (i == 9) channels[i] = new ChannelOscDrum();
            
            channels[i].create_display(12 + 180 * (i / 4), 64 + 72 * (i % 4), i);
            channels[i].disp.redraw(false);    // draw meters at value 0
        }
        
        create_display(12, 400);
    }
    
    
    void create_display(int x, int y) {
        PlayerDisplay d = new PlayerDisplay(x, y, this);
        this.disp = d;
    }
    
    
    String play_file(String filename) {
        if (!stopped) stop_all();
        File file = new File(filename);
        
        try {
            seq = MidiSystem.getSequencer(false);
            seq.open();
            seq.setLoopCount(-1);
            
            Transmitter transmitter = seq.getTransmitter();
            transmitter.setReceiver(event_listener);
            
            Sequence mid = MidiSystem.getSequence(file);
            seq.setSequence(mid);
            seq.start();
            
            midi_resolution = mid.getResolution();
            stopped = false;
            curr_filename = filename;
        }
        catch(MidiUnavailableException mue) {
            seq = null;
            return "Midi device unavailable!";
        }
        catch(InvalidMidiDataException imde) {
            seq = null;
            return "Invalid Midi data!";
        }
        catch(IOException ioe) {
            seq = null;
            return "I/O Error!";
        }
        
        return "";
    }
    
    
    void vu_anim_step() {
        for (ChannelOsc c : channels) {
            c.disp.meter_vu_lerped = vu_anim_val;
            c.disp.redraw(false);
        }
        if (!vu_anim_returning && vu_anim_val <= 1.0) vu_anim_val += 0.1;
        else vu_anim_returning = true;
        if (vu_anim_returning) vu_anim_val -= 0.05;
    }
    
    
    boolean set_paused(boolean paused) {
        if (paused) {
            if (seq == null) return false;
            prev_position = seq.getTickPosition();
            stop_all();
        }
        
        else {
            play_file(curr_filename);
            seq.setTickPosition(prev_position);
        }
        
        return true;
    }
    
    
    void stop_all() {
        for (ChannelOsc c : channels) c.reset();
        if (seq != null) {
            seq.stop();
            seq.close();
            seq = null;
        }
        
        stopped = true;
    }
    
    
    void check_chan_disp_buttons() {
        for (ChannelOsc c : channels) c.disp.check_buttons();
    }
    
    
    void redraw() {
        if (seq != null) {
            for (ChannelOsc c : channels) {
                c.redraw_playing();
            }
            
            this.disp.redraw(true);
        }
        
        else {
            for (ChannelOsc c : channels) {
                c.disp.redraw(false);
            }
        }
    }
    
    
    Receiver event_listener = new Receiver() {
        void send(MidiMessage msg, long timeStamp) {
            if (msg instanceof ShortMessage) {
                ShortMessage event = (ShortMessage) msg;
                int chan = event.getChannel();
                int comm = event.getCommand();
                int data1 = event.getData1();
                int data2 = event.getData2();
            
                if (comm == ShortMessage.NOTE_ON && data2 > 0) {
                    channels[chan].play_note(data1, data2);
                    //println(channels[chan].toString());
                }
                
                else if (comm == ShortMessage.NOTE_OFF || (comm == ShortMessage.NOTE_ON && data2 <= 0)) {
                    channels[chan].stop_note(data1);
                }
                
                else if (comm == ShortMessage.PROGRAM_CHANGE) {
                    if (data1 >= 112) channels[chan].curr_global_amp = 0.0;
                    else channels[chan].set_osc_type(program_to_osc(data1));
                }
                
                else if (comm == ShortMessage.PITCH_BEND) {
                    //channels[chan].bend(data1, data2);
                }
                
                else if (comm == ShortMessage.CONTROL_CHANGE && data1 == 7) { // data1 == 7 is channel volume...
                    channels[chan].set_volume(data2);
                }
            }
        }
        
        
        void close() {}
    };
}



int program_to_osc(int prog) {
    if (prog >= 1 && prog <= 8) return 0;
    if (prog >= 9 && prog <= 16) return 2;
    if (prog >= 17 && prog <= 24) return 1;
    if (prog >= 25 && prog <= 32) return 0;
    if (prog >= 33 && prog <= 40) return 1;
    if (prog >= 41 && prog <= 48) return 3;
    if (prog >= 49 && prog <= 56) return 3;
    if (prog >= 57 && prog <= 64) return 3;
    return 0;
}
