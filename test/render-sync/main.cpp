#include "rendersync.h"
#include <QSemaphore>
#include <atomic>
#include <thread>
#include <chrono>

static void require(bool ok, const char *message)
{
    if (!ok)
        qFatal("%s", message);
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    QObject gui_control;
    bool direct = false;
    RunRenderSync(&gui_control, [&]() { direct = true; });
    require(direct, "Same-thread synchronization must run inline");

    QThread render_thread;
    auto *render_control = new QObject;
    render_control->moveToThread(&render_thread);
    QObject::connect(&render_thread, &QThread::finished, render_control, &QObject::deleteLater);
    render_thread.start();

    // Hold the worker so an asynchronous implementation cannot pass by luck.
    QSemaphore gate;
    QMetaObject::invokeMethod(render_control, [&]() { gate.acquire(); }, Qt::QueuedConnection);
    std::thread release([&]() {
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        gate.release();
    });
    std::atomic<bool> finished{false};
    bool gui_mutation = false;
    QMetaObject::invokeMethod(&app, [&]() { gui_mutation = true; }, Qt::QueuedConnection);
    RunRenderSync(render_control, [&]() {
        require(QThread::currentThread() == &render_thread, "Sync ran on the wrong thread");
        require(!gui_mutation, "GUI event processing overlapped synchronization");
        finished.store(true);
    });
    require(finished.load(), "GUI returned before render synchronization completed");
    require(!gui_mutation, "Synchronization must not pump GUI events");
    release.join();
    QCoreApplication::processEvents();
    require(gui_mutation, "GUI should resume processing events after synchronization");
    render_thread.quit();
    require(render_thread.wait(5000), "Render thread did not stop");
    return 0;
}
