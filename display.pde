import java.util.Arrays;


Form show_config_win() {
    Form f = ui.createForm("Config")
    .addSelection("Which oscillator to use?", Arrays.asList("Square", "Sine", "Saw", "Triangle"))
    .show();
    return f;
}


class ThemeEngine {
    HashMap<String, int[]> available_themes = new HashMap<String, int[]>();
    int[] theme;
    
    
    ThemeEngine(String theme_name) {
        load_themes();
        theme = available_themes.get(theme_name);
        if(theme == null) {
            theme = available_themes.get("Default Blue");
        }
    }
    
    
    private void load_themes() {
        // theme is an array of ints (colors in hex) in order: darker, dark, neutral, light, lightest
        int[] theme_01 = {#001247, #0000b3, #809fff, #bfcfff, #ffffff};
        available_themes.put("Default Blue", theme_01);
        int[] theme_02 = {#5c1f09, #b2593f, #df825f, #ffd2a2, #ffffff};
        available_themes.put("Original GX", theme_02);
    }
}



class Button {
    int x, y, width, height;
    String name, label;
    PImage texture;
    boolean pressed = false;
    
    Button(int x, int y, String name) {
        this.name = name;
        this.x = x;
        this.y = y;
        set_pressed(false);
        label = name.substring(0, 1).toUpperCase() + name.substring(1);
    }
    
    
    Button(String name) {
        this.name = name;
        label = name.substring(0, 1).toUpperCase() + name.substring(1);
    }
    
    
    void set_texture() {
        String texture_path = "data/buttons/" + name + "Up.png";
        texture = loadImage(texture_path);
        
        this.width = texture.width;
        this.height = texture.height;
    }
    
    
    void set_pressed(boolean pressed) {
        this.pressed = pressed;
        
        String texture_path = "";
        if(pressed) {
            texture_path = "data/buttons/" + name + "Down.png";
        }
        else {
            texture_path = "data/buttons/" + name + "Up.png";
        }
        PImage texture = loadImage(texture_path);
        image(texture, x, y);
        
        this.width = texture.width;
        this.height = texture.height;
        
        fill(t.theme[0]);
        text(label, x, y - 2);
    }
    
    
    boolean collided() {
        return (mouseX > this.x && mouseX < this.width + this.x) && (mouseY > this.y && mouseY < this.height + this.y);
    }
}



class ButtonToolbar {
    int x, y;
    float x_sep, y_sep = 1;
    HashMap<String, Button> buttons = new HashMap<String, Button>();
    
    ButtonToolbar(int x, int y, float x_sep, float y_sep, Button[] buttons) {
        this.x_sep = x_sep;
        this.y_sep = y_sep;
        this.x = x;
        this.y = y;
        
        int i = 0;
        for(Button b : buttons) {
            this.buttons.put(b.name, b);
            b.set_texture();
            b.x = int(i * (b.width * this.x_sep) + x);
            b.y = int(i * (b.height * this.y_sep) + y);
            b.set_pressed(false);
            i++;
        }
    }
    
    
    Button get_button(String name) {
        return this.buttons.get(name);
    }
    
    
    boolean collided(String b_name) {
        return this.buttons.get(b_name).collided();
    }
}
        
