#pragma once

#include <QCoreApplication>
#include <QMetaObject>
#include <QThread>
#include <utility>

// QQuickRenderControl::sync reads GUI-owned QML objects. The GUI thread must
// remain blocked until synchronization finishes on the render thread.
// The callback must not synchronously call back into the GUI thread.
template<typename Function>
void RunRenderSync(QObject *render_control, Function &&sync)
{
    Q_ASSERT(QThread::currentThread() == QCoreApplication::instance()->thread());
    if (render_control->thread() == QThread::currentThread())
        sync(); // OpenGL: blocking a queued call to ourselves would deadlock.
    else
        QMetaObject::invokeMethod(render_control, std::forward<Function>(sync),
                                  Qt::BlockingQueuedConnection);
}
