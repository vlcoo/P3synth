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
        if (theme == null) {
            theme = available_themes.get("Fresh Blue");
        }
    }


    private void load_themes() {
        // theme is an array of ints (colors in hex) in order: darker, dark, neutral, light, lightest
        int[] theme_01 = {#001247, #3c3cb0, #809fff, #bfcfff, #ffffff};
        available_themes.put("Fresh Blue", theme_01);
        int[] theme_03 = {#7d0000, #cc0000, #ff3333, #ffb3b3, #ffffff};
        available_themes.put("Hot Red", theme_03);
        int[] theme_04 = {#6bb36b, #99ff99, #ccffcc, #e6ffe6, #000000};
        available_themes.put("Crispy Green", theme_04);
        int[] theme_02 = {#5c1f09, #b2593f, #df825f, #ffd2a2, #ffffff};
        available_themes.put("Original GX", theme_02);
    }
}


class ChannelDisplay {
    int x, y = 0;
    int id = 0;
    int curr_o_meter = -1;
    int curr_bend_meter = -1;
    String curr_chan_cont = "";

    ChannelDisplay(int x, int y, int id) {
        this.x = x;
        this.y = y;
        this.id = id;

        stroke(t.theme[0]);
        noFill();
        
        rect(x, y, 33, 13);                // mute bar
         rect(x, y+15, 33, 58);             // output bar out
         rect(x+2, y+24, 29, 47);           // output bar in
         rect(x+7, y+24, 5, 47);            // output bar in cols 1, 2
         line(x+17, y+24, x+17, y+71);      // output bar in cols 3
         rect(x, y+75, 33, 9);              // 
         rect(x, y+86, 33, 9);              // 
         rect(x, y+119, 33, 17);
         rect(x, y+149, 15, 9);
         rect(x+18, y+149, 15, 9);
         rect(x+9, y+160, 15, 9);
         fill(t.theme[1]);
         rect(x, y+97, 33, 9);
         rect(x, y+108, 33, 9);
         rect(x, y+138, 33, 9);
         //fill(t.theme[0]);
         line(x+17, y+108, x+17, y+117);
        /*
         for(int i = 0; i < 15; i++) {
         noStroke();
         rect(x+19, y+26+3*i, 11, 2);
         for(int j = 0; j < 3; j++) {
         rect(x+4+5*j, y+26+3*i, 2, 2);
         }
         }
         */
        fill(t.theme[0]);
        text(id+1, x+11, 220);
        upd_o_meter(0);
        upd_bend_meter(0);
    }


    void upd_chan_cont(String text) {
        if (text.equals(curr_chan_cont)) return;
        fill(t.theme[2]);
        rect(x+1, y+1, 32, 12);
        fill(t.theme[0]);
        text(text, x+2, y+11);

        curr_chan_cont = text;
    }


    void upd_wave(String text) {
        if (text.length() >= 4) {
            text = text.substring(0, 4);
        }
        fill(t.theme[2]);
        rect(x+1, y+120, 32, 16);
        fill(t.theme[0]);
        text(text, x+3, y+133);
    }


    void upd_o_meter(float value, float old_min, float old_max) {
        value = int( map(value, old_min, old_max, 0, 43) );
        upd_o_meter(value);
    }


    void upd_o_meter(float value) {
        if (value == curr_o_meter) return;
        value = constrain(value, 0, 43);
        fill(t.theme[1]);
        noStroke();
        for (int i = 0; i < 43; i++) {
            if (i == 43-value) fill(t.theme[3]);
            rect(x+19, y+26+1*i, 11, 2);
        }

        curr_o_meter = int( value );
    }


    void upd_bend_meter(int value) {
        if (value == curr_bend_meter) return;
        value = int( map(value, -8192, 8191, -8, 8) );
        fill(t.theme[1]);
        noStroke();
        for (int i = 0; i < 15; i++) {
            if ((value <= 0 && i == 0) || (value < 0 && i == value)) fill(t.theme[1]);
            if ((value > 0 && i == 0) || (value > 0 && i == value)) fill(t.theme[3]);
            rect(x+2+2*i, y+77, 1, 6);
        }

        curr_bend_meter = value;
    }


    void upd_freq(int f) {
        fill(t.theme[1]);
        noStroke();
        rect(x+1, y+139, 32, 8);
        fill(t.theme[4]);
        if (id == 9) text(f == 0 ? "-  -" : "-ts-", x+2, y+147);
        else text(f, x+2, y+147);
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
        if (pressed) {
            texture_path = "data/buttons/" + name + "Down.png";
        } else {
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
        for (Button b : buttons) {
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
