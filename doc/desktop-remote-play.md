# Windows Remote Play

The home dashboard lists registered consoles, including consoles that are offline. **Link Console** opens registration. Select a console card to choose **Local Connect** or **Remote Connect**, its route and its session mode. Choose **Add address** when a saved console has no reachable route. The top toolbar opens the profile switcher, help, internet settings and settings. The overflow menu includes network discovery, adding a manual address and refreshing PSN consoles.

**Gamepad only** forwards controls while disabling audio and video playback. Home background, the recent-games shelf, the wake action and the pairing tile can be customized under **Settings → General**.

| Setting | Where to find it | What it does |
| --- | --- | --- |
| Stream quality | Settings → Stream | Pick a console generation, then select a local or remote preset. A preset sets resolution, frame rate and automatic bitrate for that one combination. Manual changes appear as Custom. 1080p requires a PS5 or PS4 Pro. |
| Console text entry | Settings → General | Enable before connecting. When the console requests text, a desktop window lets you edit it, send it or cancel. Game input resumes when it closes. |
| Recent games | Settings → General | Optionally remember up to four titles seen by local discovery on each registered console. Streamer mode hides the history and pauses collection. Turning the option off clears this profile’s history. |

**Display settings** is available from the home navigation menu and the stream overlay. Turn on **Ambient blur** to fill screen borders with a blurred copy of the current game while keeping its aspect ratio. Choose **Load shader** to apply an mpv-format GLSL hook alongside the selected upscaler. Shaders are saved per profile on this machine. **Remove** restores the stream preset.

Enable **2× motion interpolation** in Display settings before connecting for 30-to-60 or 60-to-120 presentation on a sufficiently fast display. It estimates motion between adjacent decoded frames, adding processing and presentation latency. Scene cuts, missing frames, unsupported formats and overloaded CPUs fall back to real frames. This mode is off by default.

For portable settings, start `chiaki.exe --settings-dir .\profiles` from the extracted folder. The app creates a separate configuration there, including console registrations. Keep that directory private.

The home screen includes a **Recently played on PlayStation** shelf. Select **Load games** to request the last twelve PS4/PS5 titles from the signed-in account. Select a cover for its platform and last-played date. The shelf is hidden in streamer mode and cleared on profile or sign-in changes. The local console history is independent.

## Windows feature coverage

| Capability | Status in this fork |
| --- | --- |
| LAN discovery, wake, address-based connections and PSN connections | Implemented. Both connection views use stable identifiers during discovery refreshes. |
| Controller mapping, fullscreen, zoom, stretch, stream volume and a performance overlay | Available through the existing settings and stream menu. |
| Keyboard for console text dialogs | Implemented through chiaki’s console keyboard protocol. Physical PS4 and PS5 verification is pending. |
| Native keyboard gameplay, independent players in one session and launching a game directly through PSN | Open feature gaps. The account game shelf shows history and game details. |
| Motion-estimated frame generation | Implemented for 8-bit and 10-bit 4:2:0 streams. Actual timing depends on the CPU, decoder and display. |
| Forced PS5 HDR with the TV off and a Direct3D 12 renderer | Open feature gaps. |

The Windows reference is [PXPlay’s published desktop release notes](https://github.com/streamingdv/PSPlay-Application-Hosting/releases/tag/v3.2.0_v9.0.0).
