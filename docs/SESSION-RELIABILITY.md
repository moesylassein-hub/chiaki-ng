# Connection reliability patch — 26 September 2026

Based on moesylassein-hub/chiaki-ng commit
`306832acfcd5719bce4232592b055a6fceefc18e`.

This is a source patch, not a compiled Windows executable or a certified release.
It addresses issues found by reading the connection and session lifecycle code.
It does not establish the cause of a particular crash without that crash's log.

## Changes

- Replace the approximately 6 ms retry loop with a cancellable 1-second timer.
- Join the finished connection thread before reusing its handle for a retry.
- Retry only refused local connections within the existing 20-second retry window.
  Other errors now surface immediately instead of being retried indiscriminately.
- Process connected/quit state changes on the GUI thread and catch retry-start errors.
- Protect the decoder from queued work during destruction; drop stale presentation
  events and release frames when an event is discarded.
- Stop session producers before closing their audio devices during destruction.
- Guard late PSN results and login PIN requests against a retired session.
- Make cancellation tolerate a missing session/holepunch context.
- Cancel PSN work before waiting for the worker at application shutdown.
- Tie delayed wake-up callbacks to the backend lifetime and capture the original
  nickname, so a later session cannot change what the callback removes.
- Guard delayed controller setup against controller removal.
- Restore discovery/window interaction after selected startup failures and show
  errors when PSN credentials are absent or refresh fails.
- Avoid logging the entered console PIN; free a decoder allocation when its
  initialization fails.

## Validation completed

- `git diff --check`.
- Compiled the actual decoder-lifetime guard and its regression test with GCC,
  C++11, `-Wall -Wextra -Werror`, AddressSanitizer and UndefinedBehaviorSanitizer.
- Passed tests for late callbacks, repeated close, exception-safe unlock and
  200 concurrent use/teardown rounds.
- LeakSanitizer was disabled because this environment cannot inspect the process
  information it requires. This is not a leak-test result.

The complete application has NOT been compiled here: Qt, FFmpeg, libplacebo and
the build tools/dependencies are unavailable. Windows startup, GPU decoding,
controller/haptics/audio, LAN and PSN streaming require integration testing.
The new workflow tests the resource guard on Windows and Linux; it is not a
substitute for the full application build or console testing.

## Apply using GitHub's website (no GitHub Desktop needed)

1. Extract `chiaki-ng-reliability-fixes.zip`.
2. Open https://github.com/moesylassein-hub/chiaki-ng .
3. Create a new branch, for example `test-session-reliability`, from your current
   main branch. If the source has changed since the commit above, review/merge the
   patch instead of overwriting newer files with the replacement copies.
4. At the repository root on that branch, choose **Add file > Upload files**.
5. Drag the extracted `gui`, `test`, `docs`, and `.github` folders into the upload
   area. Keep their folder structure. Do not upload the ZIP itself as source.
6. Commit the uploaded changes to that branch.
7. Under **Actions**, run **Session lifecycle regression tests** on that branch.
8. Run **Build chiaki-ng Windows x86_64 (VC)** on that same branch.
   x86_64 is the 64-bit Windows build, including for an RTX 3050 PC.
9. After the full build succeeds, download the portable artifact named
   `chiaki-ng-win_x64-VC-Release`. Extract the artifact and the ZIP inside it, then
   run `chiaki.exe` alongside its packaged DLLs. Keep your old build separately.

The package also contains `session-reliability.patch` for developers:

```sh
git apply --check session-reliability.patch
git apply session-reliability.patch
```

## Windows acceptance checks

1. With the console awake, connect, disconnect and reconnect ten times.
2. Connect while the console is in rest mode; cancel during wake-up and retry.
3. Try an unreachable/offline console; check that cancellation returns control.
4. Disconnect the network during a stream; restore it and reconnect.
5. Cancel a PSN connection and retry; check sign-in failure handling.
6. Unplug/replug the controller immediately after connecting.
7. Check picture, sound, microphone, rumble and session shutdown.
8. Compare hardware decoding and software decoding if startup still fails.

If any check fails, retain the session log and Windows crash details, plus the
decoder/renderer settings and whether the connection was LAN or PSN. Those are
needed to identify remaining faults. No claim of flawless operation is made.

## Experimental controller connected directly to PS5

Settings → Config → **Controller connected directly to PS5 (experimental)** is
OFF by default, applies only to PS5, and can be changed only while disconnected.
It sends the controller-connection message with `connected=false`, omits the
controller type, and does not start the remote controller feedback sender.
Controller state submissions are ignored, including gamepad, keyboard-as-controller,
mouse/touch and motion input. Transport heartbeats, video/audio, registration and
session authentication are unchanged. No secondary account is selected or created.

This is a protocol experiment, not confirmed same-account support. The PS5 may
still terminate Remote Play when its directly paired controller selects the same
account. Test both connecting Chiaki first and turning on the PS5 controller first.
If either disconnects, retain the log and disable this checkbox before reconnecting.
The disabled state preserves normal remote input. This does not change Bluetooth
pairing or firmware account policy. PC application controls still work.

## Stream health and recovery

Settings → Config contains **Automatically recover frozen or disconnected streams**
(default on) and **Adaptive bitrate (experimental)** (default off). Adaptive bitrate
is independent of freeze recovery and never changes the saved bitrate setting.
It requires a brief reconnect because the protocol implementation negotiates the
requested bitrate at connection time; this is not seamless in-stream rate control.

After a 15-second connection grace period, missing video delivery/presentation for
five seconds triggers a nonblocking decoder-lock attempt, decoder flush, fresh
keyframe request and renderer queue reset. If frames remain absent for another
five seconds, the entire session is stopped and destroyed before reconnecting.
No callback or retry may reuse a retired session. Sleep, minimized windows,
protected scenes and disabled video are excluded. The Raspberry Pi decoder is
excluded from the FFmpeg video watchdog.

Audio that previously arrived but then stops for ten seconds while video continues,
or an SDL output device stopped for five seconds, uses the same bounded reconnect.
Existing controller hotplug and stream-statistics support are retained.

The status window explains the recovery stage, exposes **Cancel recovery**, and
reports the outcome. Closing it while recovery is active cancels recovery. Retries
wait 2, 4 and 6 seconds after session destruction, with a maximum of **three total
reconnects per manually started session**, shared by recovery and adaptive bitrate.
Authentication failures, intentional disconnection and console shutdown are not
retried. A connection attempt times out after 45 seconds. Cancel/stop/suspend/profile
changes invalidate pending reconnects, and automatic reconnection starts muted.

Adaptive bitrate waits at least 30 seconds after connecting. Sustained loss of 3%
for five seconds reduces the requested bitrate by 25%, down to 8 Mbps (or the
original bitrate if lower). Two minutes at no more than 0.5% loss raises it by 10%
of the original bitrate (at least 1 Mbps), capped at the original request. Network
warnings appear independently of the adaptive setting. Turning this option off
leaves the current session bitrate in place; the next manual connection uses the
saved bitrate.

Recovery diagnostics are automatically written to `recovery-latest.json` in the
log directory and can be exported from Config or the recovery window. They contain
at most 100 allowlisted events, timestamps, numeric stream statistics and outcomes.
They intentionally exclude raw logs, credentials, account IDs, console names,
addresses and controller identities. Existing session logs remain separate.

A full minute of continuously healthy video records the video settings that
launched that stream. Config can restore that snapshot (restart afterward).
Two starts interrupted before a successful check cause the next launch to restore
that snapshot, when available. Normal stops do not count as crashes. This detects
unclean exits, not their cause, and does not replace account or controller settings.
Existing profile management can hold separate quality and Discord configurations.

### Validation and limits

`test/session-lifecycle/health.cpp` covers startup grace, disabled automation,
soft repair and escalation, resumed frames, intentional stream disabling, audio
liveness, sustained-loss thresholds, bitrate bounds, stability hysteresis and sleep.
Run it together with the session-resource lifetime tests. A Windows streaming test
with induced loss, controller/audio unplugging, cancellation during PSN setup and
recovery with Vulkan is still required. A blocked GUI/GPU driver or a process crash
cannot be repaired by an in-process watchdog.

### Transport and recovery follow-up

Transport disconnects wake both handshake and active-stream waiters. Congestion
reports start only after the UDP handshake; the socket stays owned until senders
have stopped and the receive worker has joined. Receive sockets request a 1 MiB
buffer to tolerate short scheduling delays (the OS may cap the granted size).

Packet accounting locks sequence updates, handles 16-bit wraparound, ignores
duplicates, and counts every source audio unit. The UI samples cumulative counters
under the same lock and weights loss by packet counts over two seconds. Packets
arriving after an interval has been reported remain counted as late/missing.

Video repair requests a fresh frame even when the decoder is busy. Unexpected
transport disconnections and timed-out recovery attempts use the remaining retry
budget; console shutdown remains excluded. Diagnostics version 2 records numeric
quit reasons and whether the fresh-frame request succeeded. Adaptive bitrate
remains optional and disabled by default.

`test/session-lifecycle/network.py` checks production packet accounting with
wraparound, duplicates, reordering, concurrent sampling and transport-failure wait
predicates using AddressSanitizer and UndefinedBehaviorSanitizer. These checks
cannot establish the cause of physical packet loss or replace a real PS5 test.
