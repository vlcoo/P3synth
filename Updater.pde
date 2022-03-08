import http.requests.*;
import java.awt.Desktop;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;

float latest_vercode = VERCODE;
String latest_tagname = "";

final String RELEASES_URL = "https://api.github.com/repos/vlcoo/P3synth/releases";


boolean check_if_newer_ver() {
    if (latest_vercode > VERCODE) return true;
    
    GetRequest r = new GetRequest("https://api.github.com/repos/vlcoo/P3synth/releases");
    r.send();
    JSONArray response;
    
    try { response = parseJSONArray(r.getContent()); }
    catch (NullPointerException npe) { return false; }
    
    JSONObject latest = (JSONObject) response.get(0);
    latest_vercode = Float.parseFloat(latest.get("name").toString().replace("v", ""));
    latest_tagname = latest.get("tag_name").toString();
    
    return latest_vercode > VERCODE;
}


void download_latest_ver() {
    if (latest_tagname.equals("")) return;
    
    Desktop desktop = java.awt.Desktop.getDesktop();
    try {
        desktop.browse(new URI("https://github.com/vlcoo/P3synth/releases/tag/" + latest_tagname));
    }
    catch (URISyntaxException use) {}
    catch (IOException ioe) {}
}
