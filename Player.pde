import javax.sound.midi.*;
import java.net.*;
import java.util.LinkedHashMap;


void readMIDIn() {
    try {
        while (player.midi_in_mode) {
            String in = player.stdIn.readLine();
            if (in != null) {
                if (in.equals("goodbye")) break;
                try {
                    ArrayList<Integer> codes = new ArrayList<Integer>();
                    for(String s : in.split(" ")) codes.add(Integer.valueOf(s));
                    ShortMessage msg = new ShortMessage(
                        codes.get(1),
                        codes.get(0),
                        codes.get(2),
                        codes.get(3)
                    );
                    long t = 0;
                    player.event_listener.send(msg, t);
                }
                catch (InvalidMidiDataException imde) {
                    println(imde);
                }
            }
        }
        
        player.stop_midi_in();
    }
    catch (IOException e) { 
        println("no socket???");
        player.stop_midi_in();
    }
}


class Player {
    final int LENGTH_THRESHOLD = 90000000;
    final int TEMPO_LIMIT = 1000;
    final String DEFAULT_STOPPED_MSG = "Drag and drop a file to play...";
    
    boolean new_engine = false;
    Sequencer seq;
    javax.sound.midi.Synthesizer alt_syn;
    MidiFileFormat metadata;
    KeyTransformer ktrans;
    Thread sent;
    Socket sock;
    BufferedReader stdIn;
    PlayerDisplay disp;
    int midi_resolution;
    int meta_channel_prefix = 0;
    int meta_curr_track = 0;
    int num_tracks = 0;
    ChannelOsc[] channels;
    long prev_position;
    String curr_filename = DEFAULT_STOPPED_MSG;
    String sf_filename = "Default";
    int curr_rpn = 0;
    int curr_bank = 0;
    int mid_rootnote = 0;      // C
    int mid_scale = 0;         // major
    int playing_state = -1;    // -1 no loaded, 0 paused, 1 playing
    boolean midi_in_mode = false;
    boolean system_synth = false;
    float vu_anim_val = 0.0;
    boolean vu_anim_returning = false;
    
    // values to be read by the display...
    String history_text_messages = "";              // keeping track of every text (meta) msg gotten
    String last_text_message = "- no message -";    // default text if nothing received
    float last_freqDetune = 0.0;
    float last_noteDetune = 0.0;
    String custom_info_msg = "";
    boolean file_is_GM = false;
    boolean file_is_GM2 = false;
    boolean file_is_XG = false;
    boolean file_is_GS = false;
    HashMap<String, String> metadata_map;
    long epoch_at_begin = 0;
    
    
    Player() {
        ktrans = new KeyTransformer();
        final int nChannels = 16;
        channels = new ChannelOsc[nChannels];
        metadata_map = new LinkedHashMap();
        
        for (int i = 0; i < nChannels; i++) {
            channels[i] = new ChannelOsc(-1);
            if (i == 9) channels[i] = new ChannelOsc(4);
            
            channels[i].create_display(12 + 180 * (i / 4), 64 + 72 * (i % 4), i);
            channels[i].disp.redraw(false);    // draw meters at value 0
        }
        
        create_display(0, 318);
        set_seq_synth(prefs.getBoolean("system synth", false));
        if (system_synth) load_soundfont(new File(prefs.get("sf path", "")), false);
    }
    
    
    void create_display(int x, int y) {
        PlayerDisplay d;
        if (demo_ui) d = new PlayerDisplayDemo(x, y, this);
        else d = new PlayerDisplay(x, y, this);
        this.disp = d;
    }
    
    
    protected String bytes_to_text(byte[] arr) {
        String text = "";
        
        for (byte b : arr) {
            if (b >= 0) text += Character.toString((char) b);
        }
        
        return text.trim().replace("\n", "");
    }
    
    
    protected void set_params_from_sysex(byte[] arr) {
        print("syse...");
        int man_id = arr[0];
        switch(man_id) {
            case 67:        // Yamh, XG
            file_is_XG = true;
            break;
            
            case 65:        // Rold, GS
            file_is_GS = true;
            break;
            
            default:        // check if GM or GM2
            if (arr[2] == 9) {
                file_is_GM = arr[3] == 1 ? true : false;
                file_is_GM2 = arr[3] == 3 ? true : false;
            }
            break;
        }
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
        return play_file(filename, false);
    }
    
    
    String play_file(String filename, boolean keep_paused) {
        if (filename.toLowerCase().endsWith("wav")) {
            play_wav(filename);
            return "";
        }
        
        if (midi_in_mode) stop_midi_in();
        File file = new File(filename);
        if (system_synth && prefs.getBoolean("autoload sf", true)) try_match_soundfont(filename);
        
        try {
            Sequence mid = prep_javax_midi(MidiSystem.getSequence(file), false);
            num_tracks = mid.getTracks().length;
            set_playing_state(-1);
            seq.setSequence(mid);
            if (seq.getTempoInBPM() >= TEMPO_LIMIT) throw new InvalidMidiDataException();
            
            midi_resolution = mid.getResolution();
            curr_filename = filename;
            setTicks(0);
            set_playing_state(keep_paused ? 0 : 1);
            epoch_at_begin = java.time.Instant.now().getEpochSecond();
        }
        catch(InvalidMidiDataException imde) {
            return "Invalid MIDI data!";
        }
        catch(IOException ioe) {
            return "I/O Error!";
        }
        
        return "";
    }
    
    
    void play_wav(String filename) {
        // no
        set_playing_state(-1);
        File file = new File(filename);
        load_soundfont(file);
        //prep_javax_midi();
        try {
            event_listener.send(new ShortMessage(128, 0, 48, 127), 0);
            event_listener.send(new ShortMessage(192, 0, 0, 0), 0);
            event_listener.send(new ShortMessage(144, 0, 48, 127), 0);
        }
        catch (InvalidMidiDataException imde) {
            println("imde on wav");
        }
    }
    
    
    boolean is_song_long() {
        return seq.getMicrosecondLength() > LENGTH_THRESHOLD;
    }
    
    
    Sequence prep_javax_midi() {
        // bruteforce my way in
        return prep_javax_midi(null, true);   
    }
    
    
    Sequence prep_javax_midi(Sequence mid, boolean right_now) {
        try {
            int n = mid == null ? 16 : mid.getTracks().length;
            for (int i = 0; i < n; i++) {
                // msgs: remove reverb, soften volume
                if (mid != null) {
                    mid.getTracks()[i].add(new MidiEvent(new ShortMessage(176, i, 91, 0), 0));
                    mid.getTracks()[i].add(new MidiEvent(new SysexMessage(
                        new byte[] {(byte)0xf0, 0x7f, 0x7f, 0x04, 0x01, 0x00, (byte)0x2f, (byte)0xf7}, 8)
                    , 0));
                }
                
                if (right_now) {
                    event_listener.send(new ShortMessage(176, i, 91, 0), 0);
                    event_listener.send(new SysexMessage(
                        new byte[] {(byte)0xf0, 0x7f, 0x7f, 0x04, 0x01, 0x00, (byte)0x2f, (byte)0xf7}, 8)
                    , 0);
                }
            }
        }
        catch (InvalidMidiDataException imde) {
            println("can't adjust system synth (imde)");
        }
        
        return mid;
    }
    
    
    void reload_curr_file() {
        setTicks(0);
        epoch_at_begin = java.time.Instant.now().getEpochSecond();
    }
    
    
    void try_match_soundfont(String mid_filename) {
        mid_filename = mid_filename.replaceFirst("[.][^.]+$", "");
        File f = new File(mid_filename + ".dls");
        if (!f.exists() || f.isDirectory()) {
            f = new File(mid_filename + ".sf2");
        }
        if (f.exists() && !f.isDirectory()) {
            load_soundfont(f);
        }
        else return;
    }
    
    
    String load_soundfont(File file) {
        return load_soundfont(file, true);
    }
    
    
    String load_soundfont(File file, boolean switch_mode) {
        try {
            Soundbank sf = MidiSystem.getSoundbank(file);
            if (switch_mode) set_seq_synth(true);
            alt_syn.loadAllInstruments(sf);
            sf_filename = check_and_shrink_string(file.getName().replaceFirst("[.][^.]+$", ""), 16);
            
            metadata_map.put("SF Name", sf.getName());
            metadata_map.put("SF Description", sf.getDescription());
            metadata_map.put("SF Vendor", sf.getVendor());
        }
        catch (InvalidMidiDataException imd) {
            return "Invalid SF data!";
        }
        catch (IOException ioe) {
            return "I/O Error!";
        }
        return "";
    }
    
    
    void set_seq_synth(boolean is_system) {
        int playing_state_before = playing_state;
        String prev_filename = curr_filename;
        int prev_ticks = seq == null ? 0 : int(seq.getTickPosition());
        long[] prev_looppoints = null;
        if (seq != null) prev_looppoints = new long[] {seq.getLoopStartPoint(), seq.getLoopEndPoint()};
        set_playing_state(-1);
        
        try {
            if (seq != null) seq.close();
            seq = MidiSystem.getSequencer(false);
            seq.open();
            seq.setLoopCount(disp.b_loop.pressed ? -1 : 0);
            seq.addMetaEventListener(meta_listener);
            Transmitter transmitter = seq.getTransmitter();
            if (is_system) {
                if (alt_syn == null) {
                    alt_syn = MidiSystem.getSynthesizer();
                    alt_syn.open();
                }
            }
            transmitter.setReceiver(event_listener);
            
            system_synth = is_system;
            new Sound(PARENT).volume(is_system ? 0 : OVERALL_VOL);
        }
        catch (MidiUnavailableException mue) {
            println("Midi device unavailable!");
        }
        
        if (playing_state_before >= 0) {
            prep_javax_midi();
            play_file(prev_filename, playing_state_before == 0);
            seq.setLoopStartPoint(prev_looppoints[0]);
            seq.setLoopEndPoint(prev_looppoints[1]);
            setTicks(prev_ticks);
            if (playing_state_before == 0) set_playing_state(0); // keep paused if it was
        }
    }
    
    
    void start_midi_in() {
        try { sock = new Socket("localhost",7723); }
        catch (UnknownHostException uhe) { println("host???"); }
        catch (IOException ioe) { 
            ui.showErrorDialog("MIDIn Server not started!", "Can't switch modes");
            return;
        }

        sent = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    stdIn = new BufferedReader(
                        new InputStreamReader(
                            sock.getInputStream()
                        )
                    );
                    thread("readMIDIn");
                }
                catch (IOException e) { println("no socket???"); }
            }
        });

        sent.start();
        try { sent.join(); }
        catch (InterruptedException e) { println("interrupted???"); }

        set_playing_state(-1);
        midi_in_mode = true;
    }
    
    
    void stop_midi_in() {
        midi_in_mode = false;
        sent.interrupt();
        try {
            sock.close();
            stdIn.close();
        }
        catch (IOException ioe) { println("ioe on close???"); }
        ui.showInfoDialog("MIDI In disconnected!", "Switching modes");
        set_playing_state(-1);
    }
    
    
    void reset_looppoints() {
        seq.setLoopEndPoint(-1);
        seq.setLoopStartPoint(0);
    }
    
    
    void set_all_freqDetune(float freq_detune) {
        last_freqDetune = freq_detune;
        for (ChannelOsc c : channels) {
            c.set_all_oscs_freqDetune(freq_detune);
        }
    }
    
    void set_all_noteDetune(float note_detune) {
        last_noteDetune = note_detune;
        for (ChannelOsc c : channels) {
            c.set_all_oscs_noteDetune(note_detune);
        }
    }
    
    
    void set_all_osc_types(float osc_type) {
        for (ChannelOsc c : channels) {
            c.set_osc_type(osc_type);
        }
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
    
    
    void setTicks(long ticks) {
        seq.setTickPosition(ticks);
        meta_curr_track = 1;
    }
    
    
    void set_playing_state(int how) {
        if (seq == null) return;
        
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
        request_media_buttons_refresh();
    }
    
    
    void shut_up_all() {
        for (ChannelOsc c : channels) c.shut_up();
    }
    
    
    void reset_all_params() {
        for (ChannelOsc c : channels) c.reset_params();
        setTicks(0);
        
        last_text_message = "- no message -";
        history_text_messages = "";
        clear_metadata_map_keep_sf();
        if (dialog_meta_msgs != null) dialog_meta_msgs.setLargeMessage("");
        curr_rpn = 0;
        curr_bank = 0;
        mid_rootnote = 0;
        mid_scale = 0;
        curr_filename = DEFAULT_STOPPED_MSG;
        epoch_at_begin = 0;
        
        reset_looppoints();
        
        file_is_GM = false;
        file_is_GM2 = false;
        file_is_XG = false;
        file_is_GS = false;
    }
    
    
    void clear_metadata_map_keep_sf() {
        String n = metadata_map.get("SF Name");
        String d = metadata_map.get("SF Description");
        String v = metadata_map.get("SF Vendor");
        
        metadata_map.clear();
        
        metadata_map.put("SF Name", n);
        metadata_map.put("SF Description", d);
        metadata_map.put("SF Vendor", v);
    }
    
    
    void set_channel_muted(boolean how, int chan) {
        channels[chan].set_muted(how);
        if (alt_syn != null) alt_syn.getChannels()[chan].setMute(how);
    }
    
    
    void set_channel_solo(boolean how, int chan) {
        if (how) {
            for (ChannelOsc c : channels) {
                if (c.id == chan) set_channel_muted(false, c.id);
                else set_channel_muted(true, c.id);
            }
        }
        else {
            for (ChannelOsc c : channels) {
                set_channel_muted(!c.silenced, c.id);
            }
        }
    }
    
    
    String[][] get_metadata_table() {
        if (metadata_map == null) return null;
        int size = metadata_map.size();
        String[][] t = new String[size][2];
        
        int i = 0;
        for (Entry e : metadata_map.entrySet()) {
            if (e.getValue() == null ||((String) e.getValue()).equals("")) continue;
            if (!system_synth && (((String) e.getKey()).contains("SF"))) continue;
            
            t[i] = new String[] {(String) e.getKey(), (String) e.getValue()};
            i++;
        }
        
        return t;
    }
    
    
    void check_chan_disp_buttons(int mButton) {
        for (ChannelOsc c : channels) c.disp.check_buttons(mButton);
    }
    
    
    void redraw() {
        for (ChannelOsc c : channels) {
            c.redraw_playing();
        }
        
        this.disp.redraw(true);
    }
    
    
    Receiver event_listener = new Receiver() {
        void send(MidiMessage msg, long timeStamp) {
            if (system_synth) {
                try {
                    alt_syn.getReceiver().send(msg, timeStamp);
                }
                catch (MidiUnavailableException mue) { println("mue on system synth"); }
            }
            
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
                    if (chan == 9) {
                        channels[chan].set_osc_type(4);
                    }
                    else {
                        channels[chan].set_osc_type(program_to_osc(data1));
                    }
                    channels[chan].midi_program = data1;
                }
                
                else if (comm == ShortMessage.PITCH_BEND) {
                    channels[chan].set_bend(data1, data2);
                }
                
                else if (comm == ShortMessage.CONTROL_CHANGE) {
                    switch (data1) {
                        case 0:                              // bank select
                        curr_bank = data2;
                        break;
                        
                        case 7:
                        channels[chan].set_volume(data2);    // chan vol
                        break;
                        
                        case 10:                             // chan pan
                        channels[chan].set_pan(data2);
                        break;
                        
                        case 11:                             // chan expression
                        channels[chan].set_expression(data2);
                        break;
                        
                        case 100:
                        curr_rpn = data2;                    // rpn set
                        break;
                        
                        case 98:
                        curr_rpn = data2;
                        break;
                        
                        case 6:
                        set_rpn_param_val(chan, data2);      // data entry
                        break;
                        
                        case 64:                             // hold pedal
                        channels[chan].set_hold(data2);
                        break;
                        
                        case 66:                             // sostenuto pedal
                        channels[chan].set_sostenuto(data2);
                        break;
                        
                        case 67:                             // soft pedal
                        channels[chan].set_soft(data2);
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
            
            if (type == 32) {        // Channel prefix
                meta_channel_prefix = (int) data[0];
            }
            
            else if (type == 2) {        // Copyright
                metadata_map.put("Copyright", bytes_to_text(data));
            }
            
            else if (type == 3) {        // Track name
                metadata_map.put(
                    num_tracks == 1 ? "Sequence title" : 
                    "Track " + meta_curr_track + " name",
                bytes_to_text(data));
                meta_curr_track++;
            }
            
            else if (type == 4) {        // Instrument name
                metadata_map.put("Instrument " + meta_channel_prefix + " name", bytes_to_text(data));
            }
            
            else if (type == 1 || type == 5 || type == 6) {        // Lyrics or text
                String text = bytes_to_text(data);
                if (!text.equals("")) {
                    last_text_message = text;
                    history_text_messages += text + "\n";
                    dialog_meta_msgs.addToLargeMessage(text);
                }
            }
            
            else if (type == 89) {        // Key signature
                mid_scale = data[data.length - 1];
                if (mid_scale == 0) mid_rootnote = major_rootnotes[data[0] + 7];
                else if (mid_scale == 1) mid_rootnote = minor_rootnotes[data[0] + 7];
                return;
            }
            
            else if (type == 47) {        // End
                set_playing_state(-1);
                if (win_plist != null && win_plist.active) win_plist.set_current_item(win_plist.current_item + 1);
                return;
            }
        }
    };
}
