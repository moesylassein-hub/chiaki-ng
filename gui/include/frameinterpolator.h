// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#pragma once
extern "C" {
#include <libavutil/frame.h>
}

// One instance per decoder session, used on its frame-delivery thread.
class FrameInterpolator {
public:
    FrameInterpolator() = default;
    ~FrameInterpolator();
    FrameInterpolator(const FrameInterpolator &) = delete;
    FrameInterpolator &operator=(const FrameInterpolator &) = delete;
    double previousPts() const { return previous_pts; }
    // Caller owns the returned midpoint. Null means present the source directly.
    AVFrame *push(const AVFrame *source, double pts, double duration, bool discontinuity);
private:
    AVFrame *previous = nullptr;
    double previous_pts = 0;
};
