# Chiaki-ng improvement pass

This source tree contains a focused reliability and interface improvement pass made on top of the uploaded `chiaki-ng-main` source snapshot.

## Interface improvements

- Rebuilt the main console screen around modern console cards.
- Added clearer console status badges and connection information.
- Added a proper empty state when no consoles are available.
- Simplified primary actions: Connect, Wake Up, PIN, Hide/Delete, Add Console, Settings, PSN refresh, and Steam shortcut.
- Replaced the old discovery floating button with a labeled network-discovery switch and status text.
- Improved keyboard/controller focus safety so hidden hosts are not acted on accidentally.
- Added bounded navigation guards when moving through hidden host entries.
- Modernized the shared dialog shell and confirmation dialog styling.
- Improved confirmation-dialog wrapping and callback safety.
- Localized new visible strings with `qsTr()`.

## Reliability fixes

- Fixed network discovery UI behavior so the switch assigns the requested state instead of blindly inverting the backend value.
- CLI login passcodes are now required to be exactly four numeric digits, not merely four characters.
- Removed a duplicated invalid `morning` diagnostic message in the CLI path.
- Added URL validation before JSON network requests.
- Added explicit malformed-JSON detection and error reporting.
- Replaced three renderer `qFatal()` hard-abort paths with user-facing startup errors:
  - Vulkan -> OpenGL fallback also fails.
  - Explicit OpenGL initialization fails.
  - OpenGL render-control context activation fails.
- Startup paths now catch those renderer exceptions and show a readable error dialog instead of terminating abruptly.
- Basic-auth header construction no longer uses placeholder substitution for credentials.

## Validation performed

- QML delimiter-balance checks passed for modified QML files.
- `git diff --no-index --check` found no whitespace errors.
- CMake configuration was attempted.

A complete build was not possible in the current sandbox because:

1. the GitHub "Download ZIP" snapshot does not include git submodule contents such as `third-party/nanopb`, `third-party/curl`, and `third-party/cpp-steam-tools`; and
2. this Linux environment does not provide the required `libplacebo` and FFmpeg development packages.

For a real Windows build, use a recursive git clone (or initialize all submodules) and follow the project's Windows dependency/build instructions.

## Scope note

No responsible maintenance pass can guarantee that *all* bugs in a networked, cross-platform streaming application are fixed without reproducing issues across supported operating systems, GPUs, controllers, networks, and PlayStation firmware versions. This pass deliberately fixes high-confidence issues without making speculative protocol changes that could destabilize Remote Play.
