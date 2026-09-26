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
