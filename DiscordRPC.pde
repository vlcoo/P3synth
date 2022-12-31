import net.arikia.dev.drpc.DiscordEventHandlers;
import net.arikia.dev.drpc.DiscordRPC;
import net.arikia.dev.drpc.DiscordRichPresence;

final String APP_ID = "1058529164979884092";


void beginDiscordActivity() {
    DiscordRPC.discordInitialize(APP_ID, new DiscordEventHandlers(), false);
    DiscordRPC.discordRegister(APP_ID, "");
}

void updateDiscordActivity() {
    DiscordRPC.discordRunCallbacks();

    DiscordRichPresence.Builder presence = new DiscordRichPresence.Builder(player.playing_state == -1 ? "Stopped" : "MIDI \"" + player.disp.label_filename + "\"");
    if (win_plist != null && win_plist.active) presence.setDetails("Playlist: " + player.disp.queue_bottom_str);
    presence.setBigImage("icon", "");
    presence.setSmallImage("midi_program", player.system_synth ? "SF2/DLS \"" + player.sf_filename + "\"" : "Osc synth");
    presence.setStartTimestamps(player.epoch_at_begin);
    DiscordRPC.discordUpdatePresence(presence.build());
}
