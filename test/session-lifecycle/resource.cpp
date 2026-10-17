#include "sessionresource.h"
#include <atomic>
#include <cassert>
#include <future>
#include <memory>
#include <stdexcept>
#include <thread>

int main()
{
    // A queued callback holding the gate must not use a deleted decoder.
    auto value = std::unique_ptr<int>(new int(42));
    auto resource = std::make_shared<SessionResource<int>>(value.get());
    auto queued = [resource]() {
        resource->Use([](int *) { assert(false && "retired resource accessed"); });
    };
    resource->Use([](int *p) { assert(*p == 42); });
    resource->Close();
    value.reset();
    queued();
    resource->Close(); // repeated cancellation is safe
    assert(!resource->IsOpen());

    // A throwing callback must release the lock so cleanup can proceed.
    int n = 0;
    SessionResource<int> throwing(&n);
    try {
        throwing.Use([](int *) { throw std::runtime_error("decoder error"); });
    } catch (const std::runtime_error &) {}
    throwing.Close();

    // Teardown races with queued users; Close must serialize deletion with use.
    for (int iteration = 0; iteration < 200; ++iteration)
    {
        auto data = std::unique_ptr<int>(new int(7));
        SessionResource<int> shared(data.get());
        std::promise<void> entered, release;
        auto released = release.get_future();
        std::atomic<bool> using_resource{false};
        std::thread reader([&]() {
            shared.Use([&](int *p) {
                using_resource = true;
                entered.set_value();
                released.wait();
                assert(*p == 7);
                using_resource = false;
            });
            for (int i = 0; i < 100; ++i)
                shared.Use([](int *p) { assert(*p == 7); });
        });
        entered.get_future().wait();
        std::thread closer([&]() {
            shared.Close();
            assert(!using_resource);
            data.reset();
        });
        release.set_value();
        reader.join();
        closer.join();
        assert(!shared.IsOpen());
    }
}
