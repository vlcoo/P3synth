import uibooster.*;
import uibooster.components.*;
import uibooster.model.*;
import uibooster.model.formelements.*;
import uibooster.model.options.*;
import uibooster.utils.*;

import processing.sound.*;
import javax.sound.midi.*;
import drop.*;

processing.core.PApplet PARENT = this;
int VER_CODE = 10;


// Custom waveform of width 32 and height 16 (will be normalized)
class Wave32 extends BufferFactory {
  float[] data = new float[32];
  boolean normalized = false;
  
  
  Wave32() {}
  
  
  Wave32(int[] data) {
    for (int i = 0; i < this.data.length; i++) {
      this.data[i] = constrain(data[i], -7, 7);
    }
    normalize();
  }
  
  
  float[] get_wave() {
    return data;
  }
  
  
  public String getName() {
      return "wave32";
  }
  
  
  private void normalize() {
    for (int i = 0; i < this.data.length; i++) {
      data[i] = map(data[i], -7, 7, -1, 1);
    }
    normalized = true;
  }
  
  
  public Buffer generateBuffer(int bufferSize) {
      Buffer b = new Buffer(32);
      for(int i = 0; i < 32; i++) {
          b.buf[i] = data[i];
      }
      return b;
  }
  
  
  @Override
  String toString() {
    String s = "[";
    
    for (float i : data) {
      s += i + " ";
    }
    
    return s;
  }
}



class Player {
    Sequencer seq;
    int tempo_res = 0;
    int channel_num = 16;
    Channel[] channels = new Channel[channel_num];
    Wave32[] wave32_list;
    long prev_ticks;
    String curr_filename;
    // midi file...
    
    
    int midi_to_freq(int note_code) {
        //return int((440 / 32) * pow(2, ((note_code - 9) / 12)));
        return int( 440 * pow(2, (note_code - 69) / 12.0) );
    }
    
    
    Receiver listener = new Receiver() {
        @Override
        void send(MidiMessage msg, long timeStamp) {
            if (msg instanceof ShortMessage) {
                ShortMessage event = (ShortMessage) msg;
                int chan = event.getChannel();
                int comm = event.getCommand();
                int data1 = event.getData1();
                int data2 = event.getData2();
                //println(chan + " " + comm + " " + data1 + " " + data2);
            
                if(comm == ShortMessage.NOTE_ON && data2 > 0) {
                    channels[chan].play(midi_to_freq(data1), data2);
                    //println(channels[chan].toString());
                }
                else if(comm == ShortMessage.NOTE_OFF || (comm == ShortMessage.NOTE_ON && data2 <= 0)) {
                    channels[chan].stop(midi_to_freq(data1));
                }
                else if(comm == ShortMessage.PROGRAM_CHANGE) {
                    //println(chan + " " + data1);
                    if (data1 >= 112) channels[chan].silent = true;    //if program change to percussion, silence (TODO)
                    else {
                        init_chan_osc(chan, program_to_osc(data1));
                    }
                }
                else if(comm == ShortMessage.PITCH_BEND) {
                    channels[chan].bend(data1, data2);
                }
            }
            else if (msg instanceof MetaMessage) {
                MetaMessage event = (MetaMessage) msg;
                println("meta " + event.getData().toString());
            }
            else if (msg instanceof SysexMessage) {
                SysexMessage event = (SysexMessage) msg;
                println("sysex " + event.getData().toString());
            }
        }
        
        @Override
        void close() {
            
        }
    };
    
    
    Player(Wave32[] wave32_list) {
        this.wave32_list = wave32_list;
        
        init_all_oscs("Saw");
        //init_all_wave32s(0);
        channels[9] = new ChannelDrum(new WhiteNoise(PARENT));    //midi ch 10 is for percussion (TODO)
        channels[9].init_display(59+36*9, 51, 9);
        channels[9].disp.upd_wave("Noise");
    }
    
    
    void init_all_wave32s(int wave_num) {
        for (int i = 0; i < 16; i++) {    
            init_chan_wave32(i, wave_num);
        }
    }
    
    
    void init_chan_wave32(int which, int wave_num) {
        if(which == 9 || (wave_num < 0 || wave_num > 31)) return;
        if(channels[which] != null) channels[which].empty();
        channels[which] = new ChannelBeads(wave32_list[wave_num]);
        channels[which].init_display(59+36*which, 51, which);
        channels[which].disp.upd_wave("WV" + String.valueOf(wave_num));
    }
    
    
    void init_all_oscs(String osc_name) {
        for (int i = 0; i < 16; i++) {    
            init_chan_osc(i, osc_name);
        }
    }
    
    
    void init_chan_osc(int which, String osc_name) {
        if(which == 9) return;
        if(channels[which] != null) channels[which].empty();
        switch(osc_name) {
            case "Sine": {
                channels[which] = new ChannelOsc(new SinOsc(PARENT));
                break;
            }
            case "Square": {
                channels[which] = new ChannelOsc(new SqrOsc(PARENT));
                break;
            }
            case "Saw": {
                channels[which] = new ChannelOsc(new SawOsc(PARENT));
                break;
            }
            case "Triangle": {
                channels[which] = new ChannelOsc(new TriOsc(PARENT));
                break;
            }
            default: {
                println("no valid osc");
                osc_name = "???";
                break;
            }
        }
        channels[which].init_display(59+36*which, 51, which);
        channels[which].disp.upd_wave(osc_name);
    }
    
    
    // Open file and start playing
    String update(String filename) {
        quit();
        
        File file = new File(filename);
        curr_filename = filename; 
        
        try {
            seq = MidiSystem.getSequencer(false);
            seq.open();
            seq.setLoopCount(-1);
            
            Transmitter transmitter = seq.getTransmitter();
            transmitter.setReceiver(listener);
            
            Sequence mid = MidiSystem.getSequence(file);
            seq.setSequence(mid);
            seq.start();
            
            tempo_res = mid.getResolution();
            println("res " + tempo_res);
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
        
        
    void quit() {
        for(Channel c : channels) {
            c.empty();
        }
        
        try {
            seq.stop();
            seq.close();
            seq = null;
        }
        catch(NullPointerException npe) {
            println("Seq already stopped.");
        }
    }
    
    
    boolean set_paused(boolean how) {
        if (how) {
            if (seq == null) return false;
            prev_ticks = seq.getTickPosition();
            quit();
        }
        else {
            update(curr_filename);
            seq.setTickPosition(prev_ticks);
        }
        return true;
    }
    
    
    void update_display() {
        for(Channel c : channels) {
            if (c == null || c.disp == null) continue;
            c.disp.upd_chan_cont(c.toString());
            c.disp.upd_o_meter(c.last_vel, 0, 127);
            c.disp.upd_freq(c.last_freq);
            //c.disp.upd_bend_meter(c.last_bend);
        }
    }
    
    
    @Override
    String toString() {
        String s = "[";
        for(Channel c : channels) {
            s += c.toString() + " ";
        }
        return s + "]";
    }
}



Player p;
PFont font;
PFont font_med;
PFont font_bold;
PFont font_boldit;
String name;
PImage[] logo_anim = new PImage[8];
ThemeEngine t;
ButtonToolbar bt;
ButtonToolbar bst;
UiBooster ui = new UiBooster();

void setup() {
    noSmooth();
    size(680, 300);
    t = new ThemeEngine("Fresh Blue");
    background(t.theme[2]);
    surface.setTitle("vlco_o P3synth v" + VER_CODE);
    
    font = loadFont("TerminusTTF-12.vlw");
    font_med = loadFont("TerminusTTF-14.vlw");
    font_bold = loadFont("TerminusTTF-Bold-14.vlw");
    font_boldit = loadFont("TerminusTTF-Bold_Italic-14.vlw");
    textFont(font, 12);
    Button b1 = new Button("play");
    Button b2 = new Button("stop");
    Button b3 = new Button("pause");
    Button[] buttons_ctrl = {b1, b2, b3};
    bt = new ButtonToolbar(200, 16, 1.2, 0, buttons_ctrl);
    b1 = new Button("config");
    b2 = new Button("wave");
    b3 = new Button("info");
    Button[] buttons_set = {b2, b1, b3};
    bst = new ButtonToolbar(400, 16, 1.2, 0, buttons_set);
    
    //f14 = loadFont("pixel14.vlw");
    textFont(font, 12);
    fill(t.theme[4]);
    text("pre-release", 32, 48);
    text("Hello Mario.", 20, 260);
    
    fill(t.theme[0]);
    textFont(font_bold, 14);
    text("usage", 14, 61);
    text("  vel", 14, 100);
    text("instr", 14, 183);
    text(" freq", 14, 49+148);
    text("chan#", 14, 220);
    
    textFont(font, 12);
    for (int i = 0; i < 8; i++) {
        PImage img = loadImage("graphics/logo" + i + ".png");
        logo_anim[i] = img;
    }
    image(logo_anim[0], 12, 4);
    
    Wave32[] wave32_list = load_waves();
    p = new Player(wave32_list);
}



void draw() {
    p.update_display();
    if(p.seq != null) {
        int n = (int) (p.seq.getTickPosition() / (p.tempo_res/4)) % 8;
        image(logo_anim[n], 12, 4);
    }
}


void mouseClicked() {
    if(mouseButton == LEFT) {
        if(bt.collided("play")) {
            Button b = bt.get_button("play");
            /*
            if(b.pressed) {
                ui.showInfoDialog("Already playing. Due to a bug, it is necessary to restart program to play another file!");
                return;
            }
            */
            b.set_pressed(true);
            File file = ui.showFileSelection("MIDI files", "mid", "midi");
            fileSelected(file);
        }
        
        else if(bt.collided("stop")) {
            bt.get_button("stop").set_pressed(true);
            ui.showWaitingDialog("Exiting...", "Please wait");
            p.quit();
            exit();
        }
        
        else if(bst.collided("wave")) {
            bst.get_button("wave").set_pressed(true);
            String new_wave = ui.showSelectionDialog("This will override all current instruments.", "Which oscillator to use?", 
                                Arrays.asList("Square", "Sine", "Saw", "Triangle"));
            bst.get_button("wave").set_pressed(false);
            if (new_wave == null) return;
            p.init_all_oscs(new_wave);
        }
        
        else if(bst.collided("config")) {
            bst.get_button("config").set_pressed(true);
            String sel = ui.showTextInputDialog("Code of Wave32? (1-31)");
            bst.get_button("config").set_pressed(false);
            if (sel == null) return;
            int new_wave = int(sel);
            p.init_all_wave32s(new_wave);
        }
        
        else if(bt.collided("pause")) {
            Button b = bt.get_button("pause");
            if (!p.set_paused(!b.pressed)) return;
            b.set_pressed(!b.pressed);
        }
        
        else if(bst.collided("info")) {
            ui.showInfoDialog(
                "Thanks! For using P3synth\n\n" + 
                
                "PLAY: press this to open a new MIDI file.\n" +
                "STOP: press this to exit.\n" +
                "PAUSE: press this to pause currently playing song or resume currently paused song.\n" +
                "WAVE/CONFIG: (unstable) press any of these to check out custom waveforms.\n\n" +
                
                "This is proof of concept software. Beware of the plenty of bugs.\n" + 
                "UI and sound refinements coming soon.\n" + 
                "For more, check out: https://vlcoo.github.io"
            );
        }
    }
}


void fileSelected(File selection) {
    if(selection != null) {
        name = selection.getAbsolutePath();
        String response = p.update(name);
        
        fill(t.theme[2]);
        noStroke();
        rect(0, 265, 720, 20);
        
        if(!response.equals("")) {
            ui.showErrorDialog(response, "Failed");
            bt.get_button("play").set_pressed(false);
            fill(#ff0000);
        }
        else fill(t.theme[4]);
        delay(80);    // this may be a sin but don't worry about it
        textFont(font_boldit, 16);
        text(name, 16, 280);
        textFont(font, 12);
        bt.get_button("pause").set_pressed(false);
    }
    else bt.get_button("play").set_pressed(false);
}
