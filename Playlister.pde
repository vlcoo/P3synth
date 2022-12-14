import java.util.stream.Stream;
import java.nio.file.*;
import java.util.Comparator;
import java.util.Collections;


public class PlaylistModule extends PApplet {
    final int ITEM_UI_HEIGHT = 28;
    
    PApplet parentPApplet;
    Frame parentFrame;
    Frame selfFrame;
    DnDPlistListener dnd_playlist;
    ButtonToolbar buttons_top;
    ButtonToolbar buttons_bottom;
    PImage[] playlist_item_bgs;
    
    boolean active = false;
    boolean shuffled = false;
    ArrayList<PlaylistItem> items;
    PlaylistItem pending_removal;
    int current_item = -1;
    int scroll_offset = 0;
    String custom_msg = "";
    
    
    PlaylistModule(Frame f, PApplet parent) {
        this.parentFrame = f;
        this.parentPApplet = parent;
        
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
        //this.selfFrame.setSize(new Dimension(210, 420));
        ((JFrame) this.selfFrame).setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
        
        player.seq.setLoopCount(0);
        player.disp.b_loop.set_pressed(false);
        
        this.setup_buttons();
        this.setup_images();
        
        SDrop drop = new SDrop(this);
        dnd_playlist = new DnDPlistListener(this);
        drop.addDropListener(dnd_playlist);
        
        this.reposition();
    }
    
    
    public void draw() {
        if (t.is_extended_theme) gradientRect(0, 0, this.width, this.height, (int) t.theme[2], t.theme[5], 0, this);
        else this.background(t.theme[2]);
        
        if (items.isEmpty()) {
            textFont(fonts[5]);
            this.fill(t.theme[0]);
            textAlign(CENTER, CENTER);
            
            // too many words? idk
            if (dnd_playlist.draggedOnto) custom_msg = "OK! (Add to queue)";
            else custom_msg = (show_key_hints ? "Press\n'a' or 'f' to open" : "Drag and drop") +
                "\na file or folder\nto add...";
            text(custom_msg, 105, 210);
        }
        else {
            this.stroke(t.theme[0]);
            this.fill(t.theme[1]);
            this.rect(14, ITEM_UI_HEIGHT * (1.8 - scroll_offset), 180, ITEM_UI_HEIGHT * items.size(), 6, 6, 6, 6);
            
            for (int i = 0; i < items.size(); i++) {
                float y = ITEM_UI_HEIGHT * (1.8 + i - scroll_offset);
                if (i == current_item) {
                    this.fill(t.theme[3]);
                    this.noStroke();
                    int rUp = i == 0 ? 6 : 0;
                    int rDown = i == items.size()-1 ? 6 : 0;
                    this.rect(15, y + 0.5, 179, ITEM_UI_HEIGHT - 0.5, rUp, rUp, rDown, rDown);
                    this.fill(t.theme[0]);
                    this.stroke(t.theme[0]);
                }
                else {
                    this.fill(t.theme[4]);
                }
                this.textAlign(LEFT, BOTTOM);
                this.textFont(fonts[1]);
                this.text(items.get(i).filename, 20, y + 21);
                if(i != items.size() - 1) this.line(14, y + ITEM_UI_HEIGHT, 194, y + ITEM_UI_HEIGHT);
                items.get(i).button_delete.redraw_at_pos(170, (int) y + 6, this);
            }
        }
        
        noStroke();
        this.fill(t.theme[2]);
        this.rect(0, 0, 210, 46);
        if (t.is_extended_theme) this.fill(t.theme[5]);
        this.rect(0, 365, 210, 420);
        
        buttons_top.redraw(this);
        buttons_bottom.redraw(this);
    }
    
    
    public void set_current_item(int index) {
        if (index < 0) {
            active = false;
            current_item = -1;
        }
        
        else if (items.size() != 0) {
            current_item = index;
            if (current_item >= items.size()) {
                current_item = -1;
                active = false;
            }
            else {
                active = true;
                File f = items.get(current_item).file;
                if (!player.curr_filename.equals(f.getAbsolutePath())) try_play_file(f, true);
            }
        }
        
        buttons_top.get_button("On/Off").set_pressed(active);
    }
    
    
    public void next() {
        set_current_item(current_item + 1);
        reposition_scroll();
    }
    
    
    public void previous() {
        set_current_item(current_item - 1);
        reposition_scroll();
    }
    
    
    public void setup_buttons() {
        Button b1 = new Button("standby", "On/Off");
        b1.set_key_hint("p");
        Button b2 = new Button("trashcan", "Clear");
        b2.set_key_hint("c");
        Button b4 = new Button("shuffle", "Shuffle");
        b4.set_key_hint("r");
        Button b5 = new Button("saveM3U", "Save");
        Button b6 = new Button("loadM3U", "Load");
        Button[] bs = new Button[] {b1, b4};
        buttons_top = new ButtonToolbar(66, 16, 1.8, 0, bs);
        bs = new Button[] {b2, b5, b6};
        buttons_bottom = new ButtonToolbar(42, this.height - 44, 1.6, 0, bs);
    }
    
    
    public void setup_images() {
        playlist_item_bgs = new PImage[2];
        playlist_item_bgs[0] = parentPApplet.loadImage("buttons/wideUp.png");
        playlist_item_bgs[1] = parentPApplet.loadImage("buttons/wideDown.png");
    }
    
    
    public void reposition() {
        int x = this.parentFrame.getX();
        int y = this.parentFrame.getY();
        this.getSurface().setLocation((x < this.width ? x + parentFrame.getWidth() + 2 : x - this.width - 2), (y));
        this.getSurface().setIcon(logo_icon);
    }
    
    
    public void mouseWheel(MouseEvent e) {
        //if (items.isEmpty()) return;
        scroll_offset = constrain(scroll_offset + e.getCount() * 2, -9, items.size() - 1);
    }
    
    
    public void keyPressed() {
        int prev_item_count = items.size();
        
        if (keyCode == 18) show_key_hints = true;
        
        else if (key == 'a') {
            add_single_file(ui.showFileSelection("MIDI files", "mid", "midi"));
        }
        
        else if (key == 'f') {
            this.cursor(WAIT);
            add_folder(
                prefs.getBoolean("recursive folder", false),
                prefs.getBoolean("replace playlist", true),
                ui.showDirectorySelection()
            );
            this.cursor(ARROW);
        }
        
        else if (key == 'p') {
            set_current_item(active ? -1 : 0);
            if (active) reposition_scroll();
        }
        
        else if (key == 'r') {
            set_shuffle(!shuffled);
        }
        
        else if (key == 'c') {
            items.clear();
            if (active) player.set_playing_state(-1);
            set_current_item(-1);
        }
        
        else if (keyCode == 116) {
            toggle_playlist_win();
        }
        
        if (prev_item_count == 0 && items.size() > prev_item_count) set_current_item(0);
    }


    void keyReleased() {
        show_key_hints = false;
    }    
    
    
    void mousePressed() {
        if (mouseButton == LEFT) {
            for (PlaylistItem item : items) {
                if (item.button_delete.collided(this)) curr_mid_pressed = item.button_delete;
            }
            for (Button b : buttons_top.buttons.values()) {
                if (b.icon_filename.equals("standby") || b.icon_filename.equals("shuffle")) continue;
                if (b.collided(this)) curr_mid_pressed = b;
            }
            for (Button b : buttons_bottom.buttons.values()) {
                if (b.collided(this)) curr_mid_pressed = b;
            }
        }
        
        if (curr_mid_pressed != null) curr_mid_pressed.set_pressed(true);
    }
    
    
    void mouseReleased() {
        if (mouseButton == LEFT) {
            if (curr_mid_pressed != null) {
                curr_mid_pressed.set_pressed(false);
                curr_mid_pressed = null;
            }
            
            for (PlaylistItem item : items) {
                if (item.button_delete.collided(this)) {
                    pending_removal = item;
                    continue;
                }
            }
            if (pending_removal != null) {
                remove_item(pending_removal);
                pending_removal = null;
            }
            
            if (buttons_top.collided("On/Off", this)) {
                set_current_item(active ? -1 : 0);
                if (active) reposition_scroll();
            }
            
            else if (buttons_top.collided("Shuffle", this)) {
                set_shuffle(!shuffled);
            }
            
            else if (buttons_bottom.collided("Clear", this)) {
                items.clear();
                if (active) player.set_playing_state(-1);
                set_current_item(-1);
            }
            
            else if (buttons_bottom.collided("Save", this)) {
                String msg = items.isEmpty() ? 
                    "Playlist is empty" : 
                    save_as_m3u(ui.showFileSelection("Playlist files", "m3u"));
                if (!msg.equals("")) ui.showErrorDialog(msg, "Can't save");
            }
            
            else if (buttons_bottom.collided("Load", this)) {
                String msg = load_m3u(ui.showFileSelection("Playlist files", "m3u"));
                if (!msg.equals("")) ui.showErrorDialog(msg, "Can't load");
            }
            
            int i = which_index_clicked();
            if (i > -1) set_current_item(i);
        }
    }
    
    
    void mouseMoved() {
        if (collided_plist()) cursor(HAND);
        else cursor(ARROW);
    }
    
    
    boolean collided_plist() {
        return mouseX > 14 && mouseX < 168 &&
        mouseY > max(46, ITEM_UI_HEIGHT * (1.8 - scroll_offset)) &&
        mouseY < min(365, ITEM_UI_HEIGHT * (1.8 - scroll_offset + items.size()));
    }
    
    
    int which_index_clicked() {
        if (!collided_plist()) return -1;
        
        return floor((mouseY - (ITEM_UI_HEIGHT * (1.8 - scroll_offset))) / ITEM_UI_HEIGHT);
    }
    
    
    void reposition_scroll() {
        if (current_item == -1) return;
        
        if (current_item < scroll_offset) scroll_offset = current_item;
        else if (current_item > scroll_offset + 9) scroll_offset = current_item - 9;
    }
    
    
    void remove_item(PlaylistItem item) {
        int i = items.indexOf(item);
        items.remove(item);
        if (i == current_item) set_current_item(current_item);
        else if (i < current_item) current_item--;
        if (items.size() == 0) {
            if (active) player.set_playing_state(-1);
            set_current_item(-1);
        }
    }
    
    
    ArrayList<PlaylistItem> add_folder_to_list(boolean recursive, File folder) {
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
        
        return aux;
    }
    
    
    void add_folder(boolean recursive, boolean replace, File folder) {
        if (folder == null) return;
        ArrayList<PlaylistItem> aux = add_folder_to_list(recursive, folder);
        
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
    
    
    void try_add_auto(File file) {
        if (!file.exists()) return;
        if (file.isFile()) add_single_file(file);
        else if (file.isDirectory()) add_folder(
            prefs.getBoolean("recursive folder", false), 
            prefs.getBoolean("replace playlist", true), 
            file
        );
    }
    
    
    void set_shuffle(boolean how) {
        shuffled = how;
        buttons_top.get_button("Shuffle").set_pressed(how);
        
        if (items.size() <= 1) return;
        
        if (how) {
            Collections.shuffle(items);
        }
        else {
            Collections.sort(items, new PlaylistItem());
        }
        
        set_current_item(active ? 0 : -1);
    }
    
    
    String save_as_m3u(File out) {
        if (out == null) return "";
        if (out.exists() &&
            !ui.showConfirmDialog("File already exists. Overwrite?", "Saving playlist")
        ) return "";
        
        try {
            String path = out.getAbsolutePath();
            if (!path.toLowerCase().endsWith(".m3u")) path += ".m3u";
            FileWriter writer = new FileWriter(path);
            for (PlaylistItem item : items) {
                writer.write(item.file.getAbsolutePath() + "\n");
            }
            writer.close();
        }
        catch (IOException ioe) {
            return "IOException!";
        }
        
        return "";
    }
    
    
    String load_m3u(File in) {
        if (in == null) return "";
        ArrayList<PlaylistItem> aux = new ArrayList<>();
        
        try {
            BufferedReader reader = new BufferedReader(new FileReader(in.getAbsolutePath()));
            String l = reader.readLine();
            
            while (l != null) {
                try { Paths.get(l); }
                catch (InvalidPathException | NullPointerException pex) { break; }
                
                File f = new File(l);
                if (f.exists() && is_valid_midi(f)) {
                    if (f.isDirectory()) aux.addAll(add_folder_to_list(false, f));
                    else if (f.isFile()) aux.add(new PlaylistItem(f));
                }
                
                l = reader.readLine();
            }
            
            reader.close();
        }
        catch (IOException ioe) {
            return "IOException!";
        }
        
        if (aux.isEmpty()) return "Playlist didn't contain any valid MIDI files.";
        
        items = aux;
        set_shuffle(shuffled);
        return "";
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


class DnDPlistListener extends DropListener {
    boolean draggedOnto = false;
    int PADDING = 32;
    PlaylistModule win;
    
    DnDPlistListener(PlaylistModule win) {
        this.win = win;
        setTargetRect(win.width-128, 8, 116, 48);
        setTargetRect(PADDING, 46, win.width-PADDING*2, win.height-92);
    }
    
    void dropEnter() {
        draggedOnto = true;
    }
    
    void dropLeave() {
        draggedOnto = false;
    }
    
    void dropEvent(DropEvent e) {
        if (e.file() == null) return;
        
        int prev_item_count = win.items.size();
        win.cursor(WAIT);
        win.try_add_auto(e.file());
        win.cursor(ARROW);
        if (prev_item_count == 0 && win.items.size() > prev_item_count) win.set_current_item(0);
    }
}


class PlaylistItem implements Comparator<PlaylistItem> {
    File file;
    String filename;
    Button button_delete;
    
    
    PlaylistItem() {
        
    }
    
    
    PlaylistItem(File f) {
        if (f == null) return;
        
        file = f;
        filename = check_and_shrink_string(f.getName().replaceFirst("[.][^.]+$", ""), 18);
        button_delete = new Button("itemDelete", "");
    }
    
    
    PlaylistItem(Path p) {
        if (p == null) return;
        
        file = p.toFile();
        filename = check_and_shrink_string(p.getFileName().toString().replaceFirst("[.][^.]+$", ""), 18);
        button_delete = new Button("itemDelete", "");
    }
    
    @Override
    public int compare(PlaylistItem a, PlaylistItem b) {
        return a.filename.compareTo(b.filename);
    }
}
