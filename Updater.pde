import http.requests.*;
import java.awt.Desktop;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.time.LocalDate;

float latest_vercode = -1;


float check_if_newer_ver() {
    if (latest_vercode != -1) return latest_vercode - VERCODE;
    
    GetRequest r = new GetRequest("https://api.github.com/repos/vlcoo/P3synth/releases/latest");
    r.send();
    JSONObject latest;
    
    try { latest = parseJSONObject(r.getContent()); }
    catch (NullPointerException npe) { return 0; }
    catch (RuntimeException re) { return 0; }
    
    if (latest == null) return -1000;
    latest_vercode = Float.parseFloat(latest.get("name").toString().replace("v", ""));
    return latest_vercode - VERCODE;
}


void download_latest_ver() {
    open_web_url("https://github.com/vlcoo/P3synth/releases/latest/download/P3synth.jar");
}


void open_web_url(String url) {
    Desktop desktop = java.awt.Desktop.getDesktop();
    try {
        desktop.browse(new URI(url));
    }
    catch (URISyntaxException use) {}
    catch (IOException ioe) {}
}
