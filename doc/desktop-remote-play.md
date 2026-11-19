# Windows Remote Play

Choose **Local Connect** for a console discovered on your network. Choose **Remote Connect** for a registered console linked to PSN. **Add Console** saves a manual address. Saved addresses can be used from either view. Use the left and right arrows to switch views and the up and down arrows to pick a console. Press Enter to connect. A registered console in rest mode offers **Wake and connect**.

The session mode next to the connection tabs controls the next connection. **Gamepad only** forwards controls while disabling audio and video playback. **Profiles** opens the profile switcher. With a named profile active, this button shows its name.

| Setting | Where to find it | What it does |
| --- | --- | --- |
| Stream quality | Settings → Stream | Pick a console generation, then select a local or remote preset. A preset sets resolution, frame rate and automatic bitrate for that one combination. Manual changes appear as Custom. 1080p requires a PS5 or PS4 Pro. |
| Console text entry | Settings → General | Enable before connecting. When the console requests text, a desktop window lets you edit it, send it or cancel. Game input resumes when it closes. |
| Recent games | Settings → General | Optionally remember up to four titles seen by local discovery on each registered console. Streamer mode hides the history and pauses collection. Turning the option off clears this profile’s history. |

## Windows feature coverage

| Capability | Status in this fork |
| --- | --- |
| LAN discovery, wake, address-based connections and PSN connections | Implemented. Both connection views use stable identifiers during discovery refreshes. |
| Controller mapping, fullscreen, zoom, stretch, stream volume and a performance overlay | Available through the existing settings and stream menu. |
| Keyboard for console text dialogs | Implemented through chiaki’s console keyboard protocol. Physical PS4 and PS5 verification is pending. |
| Native keyboard gameplay, independent players in one session and launching a game directly through PSN | Open feature gaps. The games list displays titles observed on the network. |
| Forced PS5 HDR with the TV off, a Direct3D 12 renderer and motion-estimated frame generation | Open feature gaps. The existing client offers its own HDR and frame-mixing settings. |

The Windows reference is [PXPlay’s published desktop release notes](https://github.com/streamingdv/PSPlay-Application-Hosting/releases/tag/v3.2.0_v9.0.0).
