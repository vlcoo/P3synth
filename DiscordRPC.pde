import net.arikia.dev.drpc.DiscordEventHandlers;
import net.arikia.dev.drpc.DiscordRPC;
import net.arikia.dev.drpc.DiscordRichPresence;

final String APP_ID = "1058529164979884092";
int discordTimer = 0;


void beginDiscordActivity() {
    DiscordRPC.discordInitialize(APP_ID, new DiscordEventHandlers(), false);
    DiscordRPC.discordRegister(APP_ID, "");
}

void updateDiscordActivity() {
    discordTimer++;
    while (discordTimer < 120) return;
    
    String status = "";
    String details = "";
    String small_image_txt = "";
    String howDetailed = prefs.get("discord rpc", "No");
    if (howDetailed.equals("Yes (detailed)")) {
        status = player.playing_state == -1 ? "" : "\"" + (win_plist != null && win_plist.active && !win_plist.album_title.equals("") ? win_plist.album_title : player.disp.label_filename) + "\"";
        details = player.playing_state == -1 ? "Stopped" : 
            (win_plist != null && win_plist.active ? "Playing playlist: " + player.disp.queue_bottom_str : "Playing MIDI file");
        small_image_txt = player.system_synth ? "SF2/DLS \"" + player.sf_filename + "\"" : "Osc synth";
    }
    else if (howDetailed.equals("Yes (private)")) {
        details = player.playing_state == -1 ? "Stopped" : "Playing MIDI file";
        small_image_txt = player.system_synth ? "SF2/DLS" : "Osc synth";
    }
    else return;

    DiscordRPC.discordRunCallbacks();
    DiscordRichPresence.Builder presence = new DiscordRichPresence.Builder(status);
    presence.setDetails(details);
    presence.setBigImage("icon", "");
    presence.setSmallImage("midi_program", small_image_txt);
    presence.setStartTimestamps(player.epoch_at_begin);
    DiscordRPC.discordUpdatePresence(presence.build());
    discordTimer = 0;
}
