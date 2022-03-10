import javax.sound.midi.*;


class Player {
    Sequencer seq;
    PlayerDisplay disp;
    int midi_resolution;
    ChannelOsc[] channels;
    long prev_position;
    String curr_filename = "- no file -";
    int curr_rpn = 0;
    int playing_state = -1;    // -1 no loaded, 0 paused, 1 playing
    float vu_anim_val = 0.0;
    boolean vu_anim_returning = false;
    
    // values to be read by the display...
    String history_text_messages = "";              // keeping track of every text (meta) msg gotten
    String last_text_message = "- no message -";    // default text if nothing received
    
    
    Player() {
        channels = new ChannelOsc[16];
        
        for (int i = 0; i < 16; i++) {
            channels[i] = new ChannelOsc(-1);
            if (i == 9) channels[i] = new ChannelOscDrum();
            
            channels[i].create_display(12 + 180 * (i / 4), 64 + 72 * (i % 4), i);
            channels[i].disp.redraw(false);    // draw meters at value 0
        }
        
        create_display(0, 318);
        
        try {
            seq = MidiSystem.getSequencer(false);
            seq.open();
            seq.setLoopCount(-1);
            
            seq.addMetaEventListener(meta_listener);
            Transmitter transmitter = seq.getTransmitter();
            transmitter.setReceiver(event_listener);
        }
        catch(MidiUnavailableException mue) {
            println("Midi device unavailable!");
        }
    }
    
    
    void create_display(int x, int y) {
        PlayerDisplay d = new PlayerDisplay(x, y, this);
        this.disp = d;
    }
    
    
    protected String bytes_to_text(byte[] arr) {
        String text = "";
        
        for (byte b : arr) {
            if (b >= 0) text += Character.toString((char) b);
        }
        
        return text.trim().replace("\n", "");
    }
    
    
    protected void set_rpn_param_val(int chan, float value) {
        switch (curr_rpn) {
            case 0:
            channels[chan].curr_bend_range = value;
            break;
            
            default:
            break;
        }
    }
    
    
    protected void add_rpn_param_val(int chan, float value, boolean negative) {
        int mult = (negative ? -1 : 1);
        
        switch (curr_rpn) {
            case 0:
            channels[chan].curr_bend_range += value * mult;
            break;
            
            default:
            break;
        }
    }
    
    
    String play_file(String filename) {
        set_playing_state(-1);
        File file = new File(filename);
        
        try {
            Sequence mid = MidiSystem.getSequence(file);
            seq.setSequence(mid);
            
            midi_resolution = mid.getResolution();
            curr_filename = filename;
            set_playing_state(1);
        }
        catch(InvalidMidiDataException imde) {
            return "Invalid Midi data!";
        }
        catch(IOException ioe) {
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
    
    
    void setTicks(int ticks) {
        //stop_all();
        seq.setTickPosition(ticks);
    }
    
    
    void set_playing_state(int how) {
        how = constrain(how, -1, 1);
        switch (how) {
            case -1:
            seq.stop();
            shut_up_all();
            reset_all_params();
            break;
            
            case 0:
            seq.stop();
            shut_up_all();
            break;
            
            case 1:
            seq.start();
            break;
        }
        playing_state = how;
    }
    
    
    void shut_up_all() {
        for (ChannelOsc c : channels) c.shut_up();
    }
    
    
    void reset_all_params() {
        for (ChannelOsc c : channels) c.reset_params();
        setTicks(0);
        
        last_text_message = "- no message -";
        history_text_messages = "";
        if (dialog_meta_msgs != null) dialog_meta_msgs.setLargeMessage("");
        curr_rpn = 0;
        curr_filename = "- no file -";
    }
    
    
    void check_chan_disp_buttons() {
        for (ChannelOsc c : channels) c.disp.check_buttons();
    }
    
    
    void redraw() {
        for (ChannelOsc c : channels) {
            c.redraw_playing();
        }
        
        this.disp.redraw(true);
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
                }
                
                else if (comm == ShortMessage.NOTE_OFF || (comm == ShortMessage.NOTE_ON && data2 <= 0)) {
                    channels[chan].stop_note(data1);
                }
                
                else if (comm == ShortMessage.PROGRAM_CHANGE) {
                    if (data1 >= 112) channels[chan].curr_global_amp = 0.0;
                    else {
                        channels[chan].set_osc_type(program_to_osc(data1));
                        //channels[chan].set_env_values(program_to_env(data1));
                    }
                }
                
                else if (comm == ShortMessage.PITCH_BEND) {
                    channels[chan].set_bend(data1, data2);
                }
                
                else if (comm == ShortMessage.CONTROL_CHANGE) {
                    switch (data1) {
                        case 7:
                        channels[chan].set_volume(data2);    // chan vol
                        break;
                        
                        case 10:
                        channels[chan].set_pan(data2);       // chan pan
                        break;
                        
                        case 100:
                        curr_rpn = data2;                    // rpn set
                        break;
                        
                        case 6:
                        set_rpn_param_val(chan, data2);      // data entry
                        break;
                        
                        case 96:
                        add_rpn_param_val(chan, data2, false);    // data increment
                        break;
                        
                        case 97:
                        add_rpn_param_val(chan, data2, true);     // data decrement
                        break;
                        
                        default:
                        break;
                    }
                }
            }
        }
        
        
        void close() {}
    };
    
    
    MetaEventListener meta_listener = new MetaEventListener() {
        void meta(MetaMessage msg) {
            int type = msg.getType();
            byte[] data = msg.getData();
            
            //if (type == 3) return;    // ignoring track names for now... actually scratch that
            
            String text = bytes_to_text(data);
            if (!text.equals("")) {
                last_text_message = text;
                history_text_messages += text + "\n";
                dialog_meta_msgs.addToLargeMessage(text);
            }
        }
    };
}
