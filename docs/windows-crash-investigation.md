# Windows PS5 connection crash investigation

## Findings and limits

The inspected fork baseline is `cf995e84bb95937f0b6daefd24526e71ef5824ae`.
Its VC Windows workflow last completed successfully on October 17, 2026
(run 39066073086). Build success does not test a PS5 connection.

No user crash dumps, memory, local paths, or local dump-derived findings are
included here. The following is a source-code review, not a diagnosis of a
particular crash.

## Confirmed source defect

Both `update()` and `updateSwapchain()` dispatched `sync()` asynchronously to
the Vulkan render thread. The GUI thread could keep changing/deleting QML
objects while Qt synchronized those objects with the scene graph.
[Qt requires the GUI thread to be blocked during synchronization](https://doc.qt.io/qt-6/qquickrendercontrol.html#sync).

Both paths now use a blocking dispatch when rendering on another thread,
and execute directly for OpenGL's GUI-thread renderer. This removes a real
data race, but is **not a proven explanation for every reported crash**. In particular, the OpenGL path was
already synchronous. D3D11VA changes the decoder, not the Vulkan renderer.
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
Actual PS5 streaming, reconnect, resize, fullscreen, and device-loss behavior
still need testing on the affected PC. Do not describe the portable build as
a confirmed fix until that test succeeds. Use a freshly extracted package;
do not mix DLLs from the MSYS2 and VC packages.
