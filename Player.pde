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
        
        create_display(0, 380);
    }
    
    
    void create_display(int x, int y) {
        PlayerDisplay d = new PlayerDisplay(x, y, this);
        this.disp = d;
    }
    
    
    protected String bytes_to_text(byte[] arr) {
        String text = "";
        
        for (byte b : arr) {
            text += Character.toString((char) b);
        }
        
        return text.trim();
    }
    
    
    String play_file(String filename) {
        if (!stopped) stop_all();
        File file = new File(filename);
        
        try {
            seq = MidiSystem.getSequencer(false);
            seq.open();
            seq.setLoopCount(-1);
            
            seq.addMetaEventListener(meta_listener);
            Transmitter transmitter = seq.getTransmitter();
            transmitter.setReceiver(event_listener);
            
            Sequence mid = MidiSystem.getSequence(file);
            //last_text_message = (String) mid.getTracks()[0];
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
    
    
    void setTicks(int ticks) {
        //stop_all();
        seq.setTickPosition(ticks);
    }
    
    
    void stop_all() {
        for (ChannelOsc c : channels) c.reset();
        if (seq != null) {
            seq.stop();
            seq.close();
            seq = null;
        }
        
        last_text_message = "- no message -";
        history_text_messages = "";
        if (dialog_meta_msgs != null) dialog_meta_msgs.setLargeMessage("");
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
                }
                
                else if (comm == ShortMessage.NOTE_OFF || (comm == ShortMessage.NOTE_ON && data2 <= 0)) {
                    channels[chan].stop_note(data1);
                }
                
                else if (comm == ShortMessage.PROGRAM_CHANGE) {
                    if (data1 >= 112) channels[chan].curr_global_amp = 0.0;
                    else {
                        channels[chan].set_osc_type(program_to_osc(data1));
                        channels[chan].set_env_values(program_to_env(data1));
                    }
                }
                
                else if (comm == ShortMessage.PITCH_BEND) {
                    channels[chan].set_bend(data1, data2);
                }
                
                else if (comm == ShortMessage.CONTROL_CHANGE && data1 == 7) { // data1 == 7 is channel volume...
                    channels[chan].set_volume(data2);
                }
                
                else if (comm == ShortMessage.CONTROL_CHANGE && data1 == 10) { // data1 == 10 is channel pan...
                    channels[chan].set_pan(data2);
                }
            }
            
            else if (msg instanceof MetaMessage) {
                //MetaMessage event = (MetaMessage) msg;
                //int type = event.getType();
                //byte[] data = event.getData();
                println("m");
                /*
                if (type == 5) {
                    println("lyrics!");
                }
                
                else if (type == 3) {
                    println("tracc");
                }
                
                else if (type == 1) {
                    println("text!");
                }*/
            }
        }
        
        
        void close() {}
    };
    
    
    MetaEventListener meta_listener = new MetaEventListener() {
        void meta(MetaMessage msg) {
            int type = msg.getType();
            // if (type == 3) return;    // ignoring track names for now... actually, keep them in
            
            byte[] data = msg.getData();
            String text = bytes_to_text(data);
            if (!text.equals("")) {
                last_text_message = text;
                history_text_messages += text + "\n";
                dialog_meta_msgs.addToLargeMessage(text);
            }
        }
    };
}
