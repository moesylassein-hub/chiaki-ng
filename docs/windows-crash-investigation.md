# Windows PS5 connection crash investigation

## Findings and limits

The inspected fork baseline is `cf995e84bb95937f0b6daefd24526e71ef5824ae`.
Its VC Windows workflow last completed successfully on October 17, 2026
(run 39066073086). Build success does not test a PS5 connection.

With the user's approval, a brief diagnostic summary: three local dumps from
an MSYS2 build report heap corruption (`0xc0000374`) or a read access violation
(`0xc0000005`), detected in `ntdll.dll` and `Qt6Qml.dll`. OBS and NVIDIA capture
modules were loaded, but their presence does not establish causation. The
original corrupting write has not been identified. No dump files, memory,
raw addresses, or personal paths are published. GPU utilization and network
warnings alone do not establish the cause.

## Confirmed source defect

Both `update()` and `updateSwapchain()` dispatched `sync()` asynchronously to
the Vulkan render thread. The GUI thread could keep changing/deleting QML
objects while Qt synchronized those objects with the scene graph.
[Qt requires the GUI thread to be blocked during synchronization](https://doc.qt.io/qt-6/qquickrendercontrol.html#sync).

Both paths now use a blocking dispatch when rendering on another thread,
and execute directly for OpenGL's GUI-thread renderer. This removes a real
data race and is consistent with the Qt/heap failures, but is **not a proven
explanation for every reported crash**. In particular, the OpenGL path was
already synchronous. D3D11VA changes the decoder, not the Vulkan renderer.
Upstream v1.10.0 already uses blocking dispatch at both call sites, so this
regression in the fork cannot explain a separate failure of that release.
`QSG_RHI_BACKEND` alone is not a reliable test of this application's backend:
the application explicitly selects Qt's graphics API and wraps its own device.

The synchronization callback must never make a blocking call to the GUI
thread; the Vulkan path uses queued GUI notifications. Waiting for the render
thread can expose a GPU hang as a UI stall. This patch does not claim GPU
device-loss recovery or attempt to continue after heap corruption.

An allocation check also prevents dereferencing a null Vulkan hardware
device context. Startup logs identify the requested renderer and Qt runtime.

## Validation

The Qt Core regression test exercises the actual dispatch helper with a
deliberately stalled worker, verifies completion before returning to the GUI,
checks thread affinity, prevents GUI event processing during synchronization,
and exercises the same-thread path (which must not deadlock).

Run it with:

```text
cmake -S test/render-sync -B build-render-sync
cmake --build build-render-sync --config Release
ctest --test-dir build-render-sync -C Release --output-on-failure
```

The Windows VC workflow runs this test before compiling the application.
It builds optimized RelWithDebInfo binaries, uploads matching chiaki PDBs
separately, and includes `build-info.txt` in the portable package. Run the
included `diagnose.ps1` to collect stdout, stderr, executable hash, and exit
code without changing settings or the registry. Review logs before sharing.
Actual PS5 streaming, reconnect, resize, fullscreen, and device-loss behavior
still need testing on the affected PC. Do not describe the portable build as
a confirmed fix until that test succeeds. Use a freshly extracted package;
do not mix DLLs from the MSYS2 and VC packages.
