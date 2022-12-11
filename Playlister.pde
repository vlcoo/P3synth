import java.util.stream.Stream;
import java.nio.file.*;
import java.util.Comparator;
import java.util.Collections;


public class PlaylistModule extends PApplet {
    Frame parentFrame;
    Frame selfFrame;
    ButtonToolbar all_buttons;
    
    boolean active = false;
    boolean shuffled = false;
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
        this.surface.setTitle("Playlist");
        
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
        
        if (key == 'a') {
            int prev_item_count = items.size();
            add_single_file(ui.showFileSelection("MIDI files", "mid", "midi"));
            if (prev_item_count == 0 && items.size() > prev_item_count) set_current_item(0);
        }
        
        else if (key == 'f') {
            add_folder(true, true, ui.showDirectorySelection());
        }
        
        else if (key == 'p') {
            set_current_item(active ? -1 : 0);
        }
        
        else if (key == 'r') {
            set_shuffle(!shuffled);
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
    }
    
    
    void add_folder(boolean recursive, boolean replace, File folder) {
        if (folder == null) return;
        ArrayList<PlaylistItem> aux = new ArrayList<>();
        
        try (Stream<Path> stream = recursive ? Files.walk(folder.toPath(), 2) : Files.list(folder.toPath())) {
            stream.filter(Files::isRegularFile).forEach( (k) -> {
                PlaylistItem i = new PlaylistItem(k);
                if (i.file != null && is_valid_midi(i.file)) aux.add(i);
            });
        }
        catch (IOException ioe) {
            println("ioe on recursive folder");
        }
        
        if (!aux.isEmpty()) {
            if (replace) {
                items = aux;
                set_shuffle(shuffled);
            }
            else {
                Collections.sort(aux, new PlaylistItem());
                items.addAll(aux);
            }
        }
        else ui.showErrorDialog("Folder didn't contain any valid MIDI files.", "Can't add");
    }
    
    
    void add_single_file(File file) {
        if (file == null) return;
        if (!is_valid_midi(file)) {
            ui.showErrorDialog("Invalid MIDI data!", "Can't add");
            return;
        }
        
        items.add(new PlaylistItem(file));
    }
    
    
    void set_shuffle(boolean how) {
        if (items.size() <= 1) return;
        
        if (how) {
            Collections.shuffle(items);
        }
        else {
            Collections.sort(items, new PlaylistItem());
        }
        
        shuffled = how;
        set_current_item(active ? 0 : -1);
    }
    
    
    void save_as_m3u(String filename) {
        // File out = new 
    }
    
    
    void load_m3u(File in) {
        
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


class PlaylistItem implements Comparator<PlaylistItem> {
    File file;
    String filename;
    
    
    PlaylistItem() {
        
    }
    
    
    PlaylistItem(File f) {
        if (f == null) return;
        
        file = f;
        filename = check_and_shrink_string(f.getName().replaceFirst("[.][^.]+$", ""), 18);
    }
    
    
    PlaylistItem(Path p) {
        if (p == null) return;
        
        file = p.toFile();
        filename = check_and_shrink_string(p.getFileName().toString().replaceFirst("[.][^.]+$", ""), 18);
    }
    
    @Override
    public int compare(PlaylistItem a, PlaylistItem b) {
        return a.filename.compareTo(b.filename);
    }
}
