![P3synth](data/graphics/logo.png)

---

A synthesizer and MIDI visualization program programmed with Processing 3 and 4.
Supports playback of MID files.

### Quick start
Get the executable JAR file from the [releases](https://github.com/vlcoo/P3synth/releases/latest) page. You will need the latest version of Java 8 (if needed, go [here](https://java.com/en/download/)).

Upon opening, simply drag and drop a MIDI file onto the program to begin!

![Preview](https://raw.githubusercontent.com/vlcoo/vlcoo.github.io/main/assets/p3synth_pic_expand.png)

### Source code
The source code may include features sooner than the releases, but it might be less stable. 
Keep in mind this is Processing code, not plain old Java. The following libraries are needed in the P3 sketch:
- Sound
- HTTP Requests for Processing
- UiBooster

### MIDI message support
The following MIDI features are currently implemented:
- Basic note playing with velocity and channel expression.
- Soft, sostenuto and damper pedals.
- Pitch bending and stereo panning.
- Program changing. Uses Pulse, Triangle, Sine and Saw oscillators.
- Lyrics (if applicable).
- Mute/Solo - use the X button on any channel and left or right click it.

### LabsModule
Use the "Labs" button in-program! This dialog includes the following option:
- Freq Detune: slide up or down the relative frequency of the oscillators.
- Transpose: relative semitones transpose up or down.
- Play Speed: playback speed factor.
- Set All Oscs: override all instruments with a specific one.
- Transform: experimental chord mode changer (convert to major/minor).
- System Synth: use your device's default synthesizer instead.
- MIDI Input: see section below!

### MIDI input mode
This is a mode (prone to errors) featured in the LabsModule of P3synth versions **22.89 and up**.
To activate MIDI input mode, follow these steps:
- Download the MIDInServer.py script from this repo above.
- The server requires Python 3 to run. Download and install it. Also, install the [mido](https://mido.readthedocs.io/en/latest/installing.html) Python package.
- Run the MIDInServer.py script and select which MIDI input to listen to.
- Open P3synth and its LabsModule. The latter is accessed by the very top left button.
- Finally, choose the "MIDI INPUT" button.
- If the message "MIDI In disconnected!" appears prematurely, try closing and reopening the server script.
- To exit this mode, close the server script or click the "MIDI INPUT" button again.
