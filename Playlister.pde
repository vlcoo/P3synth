public class PlaylistModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    
    boolean active = false;
    ArrayList<PlaylistItem> items;
    int current_item = -1;
    int scroll_offset = 0;
    
    
    PlaylistModule(Frame f) {
        this.parentFrame = f;
        
        items = new ArrayList<>();
    }
    
    
    public void settings() {
        this.size(210, 420);
    }
    
    
    public void exit() {
        toggle_playlist_win();
    }
    
    
    public void setup() {
        this.textFont(fonts[2]);
        this.fill(t.theme[0]);
        
        this.selfFrame = ( (PSurfaceAWT.SmoothCanvas)this.surface.getNative() ).getFrame();
        this.selfFrame.setSize(new Dimension(210, 420));
        ((JFrame) this.selfFrame).setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        
        player.seq.setLoopCount(0);
        b_loop.set_pressed(false);
        this.setup_buttons();
        this.reposition();
    }
    
    
    public void draw() {
        if (t.theme.length == 6) gradientRect(0, 0, this.width, this.height, (int) t.theme[2], t.theme[5], 0, this);
        else this.background(t.theme[2]);
        
        textFont(fonts[1]);
        fill(t.theme[0]);
        for (int i = 0; i < items.size(); i++) {
            text((i == current_item ? "-> " : "") + items.get(i).filename, 10, 20 * (1 + i + scroll_offset));
        }
        
        textFont(fonts[5]);
        text(current_item + " " + active, 60, 380);
    }
    
    
    public void set_current_item(int index) {
        if (index < 0) {
            active = false;
            current_item = -1;
            return;
        }
        
        if (items.size() != 0) {
            current_item = index;
            if (current_item >= items.size()) {
                current_item = -1;
                active = false;
                return;
            }
            active = true;
            File f = items.get(current_item).file;
            if (!player.curr_filename.equals(f.getAbsolutePath())) try_play_file(f);
        }
    }
    
    
    public void setup_buttons() {
        
    }
    
    
    public void reposition() {
        int x = this.parentFrame.getX();
        int y = this.parentFrame.getY();
        this.getSurface().setLocation((x < this.width ? x + parentFrame.getWidth() + 2 : x - this.width - 2), (y));
        this.getSurface().setIcon(logo_icon);
    }
    
    
    public void mouseWheel(MouseEvent e) {
        scroll_offset += -e.getCount();
    }
    
    
    public void keyPressed() {
        println(key + " " + keyCode);
        int prev_item_count = items.size();
        
        if (key == 'a') {
            PlaylistItem i = new PlaylistItem(ui.showFileSelection("MIDI files", "mid", "midi"));
            if (i.file != null && is_valid_midi(i.file)) items.add(i);
        }
        
        else if (key == 'f') {
            File folder = ui.showDirectorySelection();
            if (folder == null) return;
            for (File child : folder.listFiles()) {
                PlaylistItem i = new PlaylistItem(child);
                if (i.file != null && is_valid_midi(i.file)) items.add(i);
            }
        }
        
        else if (key == 'p') {
            set_current_item(active ? -1 : 0);
        }
        
        else if (keyCode == 116) {
            toggle_playlist_win();
        }
        
        else if (keyCode == 33) {        // PGUP
            set_current_item(current_item - 1);
        }
        
        else if (keyCode == 34) {        // PGDOWN
            set_current_item(current_item + 1);
        }
        
        if (prev_item_count == 0 && items.size() > prev_item_count) set_current_item(0);
    }
}


boolean is_valid_midi(File mid) {
    try {
        MidiSystem.getSequence(mid);
    }
    catch (InvalidMidiDataException imde) {
        return false;
    }
    catch (IOException ioe) {
        return false;
    }
    return true;
}


class PlaylistItem {
    File file;
    String filename;
    
    
    PlaylistItem(File f) {
        if (f == null) return;
        
        file = f;
        filename = f.getName();
    }
}
