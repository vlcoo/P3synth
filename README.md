![P3synth](data/graphics/logo.png)

A synthesizer and MIDI visualization program programmed with Processing 3 and 4.
Supports playback of MID files with optional SF2/DLS loading.

### Quick start
Get the executable JAR file from the [releases](https://github.com/vlcoo/P3synth/releases/latest) page. You will need the latest version of Java 8 (if needed, go [here](https://java.com/en/download/)).

Upon opening, simply drag and drop a MIDI file onto the program to begin!

![Preview](https://raw.githubusercontent.com/vlcoo/vlcoo.github.io/main/assets/p3synth_pic_expand.png)

### Source code
The source code under the nightly branch may include features sooner than the releases, but it might be less stable. 
Keep in mind this is Processing code, not plain old Java. The following libraries are needed in the P4 sketch:
- Sound
- HTTP Requests for Processing
- Drop

The `code` folder has some extra libraries that may not have been in Processing's library repo.

### MIDI message support
The following MIDI features are currently implemented:
- Basic note playing with velocity and channel expression.
- Soft, sostenuto and damper pedals.
- Pitch bending and stereo panning.
- Program changing. Uses Pulse, Triangle, Sine and Saw oscillators.
- Lyrics (if applicable) and other metadata.
- Mute/Solo - use the X button on any channel and left or right click it.

### Guide
An exhaustive explanation of all features is present in the [wiki](https://github.com/vlcoo/P3synth/wiki).
