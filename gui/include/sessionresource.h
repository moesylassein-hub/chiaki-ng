#ifndef CHIAKI_SESSIONRESOURCE_H
#define CHIAKI_SESSIONRESOURCE_H

#include <mutex>
#include <atomic>

// Queued work may outlive its session. Closing waits for an in-flight user,
// then makes all later work a no-op before the underlying resource is freed.
template<typename T>
class SessionResource
{
public:
    explicit SessionResource(T *resource) : resource(resource), open(resource != nullptr) {}

    template<typename F>
    void Use(F &&callback)
    {
        std::lock_guard<std::mutex> lock(mutex);
        if(resource)
            callback(resource);
    }

    void Close()
    {
        std::lock_guard<std::mutex> lock(mutex);
        resource = nullptr;
        open.store(false);
    }

    bool IsOpen()
    {
        return open.load();
    }

private:
    std::mutex mutex;
    T *resource;
    std::atomic<bool> open;
};

#endif
