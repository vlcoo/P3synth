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
int VER_CODE = 7;


// Custom waveform of width 32 and height 16 (will be normalized)
class Wave32 extends BufferFactory {
  float[] data = new float[32];
  boolean normalized = false;
  
  
  Wave32() {
      
  }
  
  
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
    int channel_num = 16;
    Channel[] channels = new Channel[channel_num];
    Wave32[] wave32_list;
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
                
                if(chan == 9) {
                    return;        // channel 10 is percussion, TODO
                }
            
                if(comm == ShortMessage.NOTE_ON && data2 > 0) {
                    channels[chan].play(midi_to_freq(data1), data2);
                    //println(channels[chan].toString());
                }
                else if(comm == ShortMessage.NOTE_OFF || (comm == ShortMessage.NOTE_ON && data2 <= 0)) {
                    channels[chan].stop(midi_to_freq(data1));
                }
                else if(comm == ShortMessage.PROGRAM_CHANGE && data1 >= 112) {
                    channels[chan].silent = true;    //if program change to percussion, silence (TODO)
                }
                else if(comm == ShortMessage.PITCH_BEND) {
                    //channels[chan].bend(data1, data2);
                }
            }
        }
        
        @Override
        void close() {
            
        }
    };
    
    
    Player(Wave32[] wave32_list) {
        this.wave32_list = wave32_list;
        int wave_num = 0;
        println("using wave " + wave_num);
        
        for (int i = 0; i < channel_num; i++) {
            channels[i] = new Channel();
        }
        
        set_all_oscs("Saw");
        //channels[9].silent = true;    //midi ch 10 is for percussion (TODO)
    }
    
    
    void set_all_wave32s(int wave_num) {
        for (int i = 0; i < channel_num; i++) {
            channels[i].set_wave(wave32_list[wave_num]);
        }
    }
    
    
    void set_all_oscs(String osc_name) {
        switch(osc_name) {
            case "Sine": {
                for (int i = 0; i < channel_num; i++) {
                    channels[i].set_osc(new SinOsc(PARENT));
                }
                break;
            }
            case "Square": {
                for (int i = 0; i < channel_num; i++) {
                    channels[i].set_osc(new SqrOsc(PARENT));
                }
                break;
            }
            case "Saw": {
                for (int i = 0; i < channel_num; i++) {
                    channels[i].set_osc(new SawOsc(PARENT));
                }
                break;
            }
            case "Triangle": {
                for (int i = 0; i < channel_num; i++) {
                    channels[i].set_osc(new TriOsc(PARENT));
                }
                break;
            }
            default: {
                break;
            }
        }
    }
    
    
    // Open file and start playing
    String update(String filename) {
        quit();
        
        File file = new File(filename);
        
        try {
            seq = MidiSystem.getSequencer(false);
            seq.open();
            seq.setLoopCount(-1);
            
            Transmitter transmitter = seq.getTransmitter();
            transmitter.setReceiver(listener);
            
            Sequence mid = MidiSystem.getSequence(file);
            seq.setSequence(mid);
            seq.start();
        }
        catch(MidiUnavailableException mue) {
            return "Midi device unavailable!";
        }
        catch(InvalidMidiDataException imde) {
            return "Invalid Midi data!";
        }
        catch(IOException ioe) {
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
    
    
    @Override
    String toString() {
        String s = "[";
        for(Channel c : channels) {
            s += c.toString() + " ";
        }
        return s + "]";
    }
}



Wave32[] load_waves() {
    Wave32[] wave_list = new Wave32[32];    //There seem to be 32 different waveforms in GXSCC.
    
    int[] wd_00 = {7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7, -7};
    wave_list[0] = new Wave32(wd_00);
    int[] wd_07 = {0, 0, 0, -7, 0, 6, 6, 6, 0, 0, 0, -7, 0, 0, 0, -7, -7, -7, -7, 0, -7, -7, 0, 0, 0, 0, -7, -7, -7, 0, -7, -7};
    wave_list[7] = new Wave32(wd_07);
    int[] wd_12 = {2, 4, 4, 2, 0, 0, 0, 3, 5, 6, 5, 2, 0, -1, -1, 0, 1, 1, 0, -3, -5, -6, -5, -3, 0, 0, -2, -4, -4, -2, 0, 0};
    wave_list[12] = new Wave32(wd_12);
    int[] wd_25 = {0, 3, 7, 3, 0, -3, 0, -3, 0, -1, -2, -3, -4, -4, -5, -5, -6, -6, -7, -7, -7, -7, -7, -6, -6, -5, -5, -4, -4, -3, -2, -1};
    wave_list[25] = new Wave32(wd_25);
    
    return wave_list;
}



Player p;
PFont f14;
PFont f8;
String name;
ThemeEngine t;
ButtonToolbar bt;
UiBooster ui = new UiBooster();

void setup() {
    noSmooth();
    size(640, 446);
    t = new ThemeEngine("Default Blue");
    noStroke();
    background(t.theme[2]);
    surface.setTitle("vlco_o P3synth v" + VER_CODE);
    
    f14 = loadFont("pixel14.vlw");
    textFont(f14, 14);
    Button b1 = new Button("play");
    Button b2 = new Button("stop");
    Button b3 = new Button("config");
    Button[] buttons = {b1, b2, b3};
    bt = new ButtonToolbar(200, 16, 1.2, 0, buttons);
    
    //f14 = loadFont("pixel14.vlw");
    //textFont(f14, 14);
    fill(t.theme[4]);
    text("pre-release", 32, 50);
    text("This is proof-of-concept work.", 20, 260);
    text("Beware of loud popping sounds (lowering volume is recommended).", 20, 280);
    text("Before loading a second file, it's advised to close and re-open program.", 20, 300);
    
    PImage img = loadImage("graphics/logo.png");
    image(img, 12, 4);
    
    Wave32[] wave32_list = load_waves();
    p = new Player(wave32_list);
    
    fill(t.theme[0]);
    text("CHANNEL CONTENTS", 20, 180);
}



void draw() {
    fill(t.theme[2]);
    rect(10, 180, 640, 40);
    fill(t.theme[0]);
    text(p.toString(), 20, 200);
}


void mouseClicked() {
    if(mouseButton == LEFT) {
        if(bt.collided("play")) {
            Button b = bt.get_button("play");
            if(b.pressed) {
                ui.showInfoDialog("Already playing. Due to a bug, it is necessary to restart program to play another file!");
                return;
            }
            b.set_pressed(true);
            File file = ui.showFileSelection();
            fileSelected(file);
        }
        
        else if(bt.collided("stop")) {
            bt.get_button("stop").set_pressed(true);
            ui.showWaitingDialog("Exiting...", "Please wait");
            p.quit();
            exit();
        }
        
        else if(bt.collided("config")) {
            bt.get_button("config").set_pressed(true);
            Form f = show_config_win();
            String new_wave = f.getByIndex(0).asString();
            p.set_all_oscs(new_wave);
            bt.get_button("config").set_pressed(false);
        }
    }
}


void fileSelected(File selection) {
    if(selection != null) {
        name = selection.getAbsolutePath();
        String response = p.update(name);
        if(!response.equals("")) {
            bt.get_button("play").set_pressed(false);
            ui.showErrorDialog(response, "Failed");
        }
    }
}
