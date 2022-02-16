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


// Custom waveform of width 32 and height 16 (will be normalized)
class Wave32 {
  float[] data = new float[32];
  boolean normalized = false;
  
  
  Wave32(int[] data) {
    for (int i = 0; i < this.data.length; i++) {
      this.data[i] = constrain(data[i], -7, 7);
    }
    normalize();
  }
  
  
  float[] get_wave() {
    return data;
  }
  
  
  private void normalize() {
    for (int i = 0; i < this.data.length; i++) {
      data[i] = map(data[i], -7, 7, -1, 1);
    }
    normalized = true;
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



class Channel {
  int extended_sample_factor = 1;  // 1 is original size of wave32
  float[] wave_data = new float[extended_sample_factor * 32];
  HashMap<Integer, AudioSample> current_notes = new HashMap<Integer, AudioSample>();
  boolean silent = false;
  int last_freq = 0;
  
  
  Channel(Wave32 wave) {
    float[] non_ext_wave = wave.get_wave();
    // e x t e n d  sample so AudioSample doesn't loop so frequently...
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
    s.amp(map(vel, 0, 127, 0, 1) / 6);
    //s.play();
    current_notes.put(freq, s);
  }
  
  
  private int freq_to_midi(int freq) {
    return int( 69 + 12 * (log(freq / 440.0)/log(2)) );
  }
  
  
  private int bend_to_freq(int freq, int pitchbend) {
    int note_code = freq_to_midi(freq);
    return int( 440 * pow(2, ((note_code-69) / 12.0) + ((pitchbend-8192) / (4096.0*12.0))) );
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
          return;    // channel 10 is percussion, TODO
        }
      
        if(comm == ShortMessage.NOTE_ON && data2 > 0) {
          channels[chan].play(midi_to_freq(data1), data2);
          //println(channels[chan].toString());
        }
        else if(comm == ShortMessage.NOTE_OFF || (comm == ShortMessage.NOTE_ON && data2 <= 0)) {
          channels[chan].stop(midi_to_freq(data1));
        }
        else if(comm == ShortMessage.PROGRAM_CHANGE && data1 >= 112) {
          channels[chan].silent = true;  //if program change to percussion, silence (TODO)
        }
        else if(comm == ShortMessage.PITCH_BEND) {
          channels[chan].bend(data1, data2);
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
      channels[i] = new Channel(wave32_list[wave_num]);
    }
    //channels[9].silent = true;  //midi ch 10 is for percussion (TODO)
  }
  
  
  // Open file and start playing
  void update(String filename) {
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
      println("Midi device unavailable!");
    }
    catch(InvalidMidiDataException imde) {
      println("Invalid Midi data!");
    }
    catch(IOException ioe) {
      println("I/O Error!");
    }
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



Wave32[] setup_waves() {
  Wave32[] wave_list = new Wave32[32];  //There seem to be 32 different waveforms in GXSCC.
  
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
PFont f;
String name;

void setup() {
  noSmooth();
  size(640, 446);
  f = loadFont("pixel14.vlw");
  textFont(f, 14);
  noStroke();
  background(223, 130, 95);
  text("pre-alpha", 32, 50);
  text("LEFT CLICK to open file", 20, 100);
  text("RIGHT CLICK to exit", 20, 120);
  text("This is proof-of-concept work.", 20, 260);
  text("Beware of loud popping sounds (lowering volume is recommended).", 20, 280);
  text("Before loading a second file, it's advised to close and re-open program.", 20, 300);
  
  PImage img = loadImage("graphics/logo.png");
  image(img, 12, 0);
  
  Wave32[] wave32_list = setup_waves();
  p = new Player(wave32_list);
  
  fill(92, 31, 9);
  text("CHANNEL CONTENTS", 20, 180);
}



void draw() {
  fill(223, 130, 95);
  rect(10, 180, 640, 40);
  fill(92, 31, 9);
  text(p.toString(), 20, 200);
}


void mouseClicked() {
  if(mouseButton == RIGHT) {
    fill(255);
    text("Please wait...",20,400);
    p.quit();
    exit();
  }
  else if(mouseButton == LEFT) {
    selectInput("Which MIDI file?", "fileSelected");
  }
}


void fileSelected(File selection) {
  if(selection != null) {
    name = selection.getAbsolutePath();
    p.update(name);
  }
}
