# Windows desktop comparison

Reference version: PXPlay 3.2.0 portable demo. The categories below come from the installed demo’s user-interface resource inventory and the Windows release notes. Some labels are shared with other platforms. A label alone does not establish availability on a particular PC. This comparison tracks the Windows client.

| Area | Reference controls and behavior | Coverage in this fork |
| --- | --- | --- |
| Home and profiles | Profile switcher, linked consoles, pairing tile, recent games with artwork, PSN account state, focus and shortcut hints, animated or static background | Console cards group LAN, manual and PSN routes. Offline consoles stay visible. The shelf displays account titles and artwork on request. Home styling, background motion, the shelf, the wake action and the pairing tile are configurable. |
| Pairing and internet | PS4/PS5 PIN pairing, account identifiers, LAN and PSN routes, linking away from home, wake or connect, saved login PIN, network troubleshooting | Local registration, discovery, saved addresses, wake, account sign-in, login PINs and PSN connections are available. Remote-only pairing and router setup parity require further verification. |
| Streaming | Independent home and internet quality, resolution, 30/60 fps, bitrate, reconnection, window size and startup mode | Local and remote presets per console generation, bitrate, session modes, recovery and fullscreen are available. Per-console overrides require a separate comparison. |
| Video | Decoder and renderer choice, HDR and tone mapping, upscaling, sharpening, custom shaders, VSync, buffering, pacing and generated frames | Vulkan and OpenGL rendering, spatial presets, user GLSL hooks, frame mixing and 2× motion interpolation. TV-off HDR forcing and Windows Direct3D output require further work. Decoder choices are separate from renderer choices. |
| Geometry | Original, fill/zoom, stretched and fixed aspect ratios. Ambient color, blur and edge extension | Original, zoom, stretch and blurred borders. Fixed aspect ratios and the other ambient styles need implementation or verification. |
| Audio | Device choice, buffering, app volume, optional system-volume control, microphone and startup state | Device selection, buffer, per-app volume, microphone and startup microphone state are available. Windows system-volume controls and fallback-engine behavior require separate verification. |
| Gamepad and local multiplayer | Remapping, import files, triggers, rumble, haptics, lightbar, motion, hot-plugging, joining a separate player | Controller mapping, adaptive triggers, motion and rumble exist. Independent extra players, mapping-file import, and full Bluetooth haptic behavior are separate from basic controller input. |
| Keyboard and touch | Keyboard as controller or native keyboard, console text entry, touchpad swipes/taps, touch area, mouse mode and shortcuts | Keyboard-to-controller mapping, console text dialogs and touchpad emulation are available. Native PS5 keyboard gameplay and configurable touch-area parity remain open. |
| UI, logging and advanced controls | Overlay visibility, performance stats, background style, wake and link controls, log directory, verbose logs, keyframe recovery and input polling | Stream controls, stats, logging, recovery and home visibility controls are available. Each platform-specific advanced switch needs validation against hardware. |
| Launchers and games | Steam and desktop shortcuts, per-console launches and starting a title through PSN | Steam integration, command-line streams and game history are available. Direct game launch through PSN is unimplemented. |

A paired PS5 and two separately authorized local players are needed to verify independent multiplayer. A suitable display, a TV-off test and an actual PlayStation game with native keyboard input are needed for those respective checks.

[Windows release notes](https://github.com/streamingdv/PSPlay-Application-Hosting/releases)
