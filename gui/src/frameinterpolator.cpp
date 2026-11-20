// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#include "frameinterpolator.h"
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <cstddef>
#include <cstdint>
#include <vector>
extern "C" {
#include <libavutil/hwcontext.h>
#include <libavutil/pixdesc.h>
}

namespace {
constexpr int block = 32;
constexpr int poor_match = 26; // Mean luma difference on an 8-bit scale.
struct Motion { int x = 0, y = 0, error = 255; };

template<typename T>
const T *row(const AVFrame *f, int plane, int y)
{
    return reinterpret_cast<const T *>(f->data[plane] + std::ptrdiff_t(y) * f->linesize[plane]);
}

// Each vector points from a midpoint block to its location in the second frame.
// Restrict comparison to valid pixels in both frames, including at image edges.
template<typename T>
Motion estimate(const AVFrame *a, const AVFrame *b, int x, int y, int shift)
{
    Motion best;
    const int w = std::min(block, a->width - x), h = std::min(block, a->height - y);
    auto cost = [&](int dx, int dy) {
        const int x0 = std::max(0, std::abs(dx)-x), x1 = std::min(w, a->width-x-std::abs(dx));
        const int y0 = std::max(0, std::abs(dy)-y), y1 = std::min(h, a->height-y-std::abs(dy));
        int error = 0, samples = 0;
        for (int j = y0; j < y1; j += 5) {
            const T *r0 = row<T>(a, 0, y+j-dy), *r1 = row<T>(b, 0, y+j+dy);
            for (int i = x0; i < x1; i += 5) {
                error += std::abs(int(r0[x+i-dx] >> shift) - int(r1[x+i+dx] >> shift));
                ++samples;
            }
        }
        return samples ? (error + samples/2)/samples : 256;
    };
    best.error = cost(0, 0);
    if (best.error <= 1)
        return best;
    auto try_vector = [&](int dx, int dy) {
        if (std::abs(dx)>12 || std::abs(dy)>12)
            return;
        int error = cost(dx, dy);
        if (error < best.error)
            best = {dx, dy, error};
    };
    for (int step : {4, 2, 1}) {
        const int cx = best.x, cy = best.y;
        for (int j = -step; j <= step; j += step)
            for (int i = -step; i <= step; i += step)
                if (i || j)
                    try_vector(cx+i, cy+j);
        if (!best.error)
            break;
    }
    return best;
}

template<typename T>
AVFrame *midpoint(const AVFrame *a, const AVFrame *b, int luma_shift, int packing_shift, bool interleaved)
{
    const int cols = (a->width + block - 1) / block, rows = (a->height + block - 1) / block;
    std::vector<Motion> motion(size_t(cols) * rows);
    int unmatched = 0;
    for (int by = 0; by < rows; ++by) {
        for (int bx = 0; bx < cols; ++bx) {
            Motion &m = motion[by*cols + bx];
            m = estimate<T>(a, b, bx*block, by*block, luma_shift);
            unmatched += m.error > poor_match;
        }
    }
    if (unmatched * 3 >= cols * rows * 2)
        return nullptr; // Hold the real frame across cuts instead of synthesizing a dissolve.

    AVFrame *out = av_frame_alloc();
    if (!out)
        return nullptr;
    out->format = b->format;
    out->width = b->width;
    out->height = b->height;
    if (av_frame_get_buffer(out, 32) < 0 || av_frame_copy_props(out, b) < 0) {
        av_frame_free(&out);
        return nullptr;
    }
    for (int p = 0; p < (interleaved ? 2 : 3); ++p) {
        const int scale = p ? 2 : 1, channels = p && interleaved ? 2 : 1;
        const int width = (a->width+scale-1)/scale, height = (a->height+scale-1)/scale;
        for (int y = 0; y < height; ++y) {
            T *dst = reinterpret_cast<T *>(out->data[p] + std::ptrdiff_t(y)*out->linesize[p]);
            for (int bx = 0; bx < cols; ++bx) {
                const auto &m = motion[(y*scale/block)*cols + bx];
                int dx = m.x/scale, dy = m.y/scale;
                const T *first = row<T>(a, p, std::clamp(y-dy, 0, height-1));
                const T *second = row<T>(b, p, std::clamp(y+dy, 0, height-1));
                const int end = std::min(width, (bx+1)*block/scale);
                const int start = bx*block/scale;
                if (m.error > poor_match) {
                    std::copy_n(row<T>(a, p, y)+start*channels, (end-start)*channels, dst+start*channels);
                    continue;
                }
                for (int x = start; x < end; ++x) {
                    const int x0 = std::clamp(x-dx, 0, width-1)*channels;
                    const int x1 = std::clamp(x+dx, 0, width-1)*channels;
                    for (int c = 0; c < channels; ++c)
                        dst[x*channels+c] = T((((first[x0+c] >> packing_shift) + (second[x1+c] >> packing_shift) + 1)/2) << packing_shift);
                }
            }
        }
    }
    // The application uses seconds for presentation. Keep decoder timestamps consistent where known.
    if (a->pts != AV_NOPTS_VALUE && b->pts >= a->pts)
        out->pts = a->pts + (b->pts-a->pts)/2;
    out->duration = b->duration/2;
    return out;
}

bool supported(int format)
{
    return format == AV_PIX_FMT_YUV420P || format == AV_PIX_FMT_YUVJ420P || format == AV_PIX_FMT_NV12 ||
           format == AV_PIX_FMT_YUV420P10LE || format == AV_PIX_FMT_P010LE;
}

AVFrame *host_frame(const AVFrame *f)
{
    if (f->width < 2 || f->height < 2 || f->width > 4096 || f->height > 2160)
        return nullptr;
    if (!f->hw_frames_ctx)
        return supported(f->format) ? av_frame_clone(f) : nullptr;
    const auto *ctx = reinterpret_cast<const AVHWFramesContext *>(f->hw_frames_ctx->data);
    if (!ctx || !supported(ctx->sw_format))
        return nullptr;
    AVFrame *copy = av_frame_alloc();
    if (copy) {
        copy->format = ctx->sw_format;
        if (av_hwframe_transfer_data(copy, f, 0) < 0 || av_frame_copy_props(copy, f) < 0)
            av_frame_free(&copy);
    }
    return copy;
}
}

FrameInterpolator::~FrameInterpolator() { av_frame_free(&previous); }

AVFrame *FrameInterpolator::push(const AVFrame *source, double pts, double duration, bool discontinuity)
{
    AVFrame *current = host_frame(source), *out = nullptr;
    const double interval = pts - previous_pts;
    if (previous && current && !discontinuity && duration > 0 && interval >= 0.65*duration &&
        interval <= 1.5*duration && previous->width == current->width && previous->height == current->height &&
        previous->format == current->format && previous->colorspace == current->colorspace &&
        previous->color_trc == current->color_trc && previous->color_range == current->color_range &&
        previous->color_primaries == current->color_primaries) {
        const int fmt = current->format;
        if (fmt == AV_PIX_FMT_P010LE || fmt == AV_PIX_FMT_YUV420P10LE)
            out = midpoint<uint16_t>(previous, current, fmt == AV_PIX_FMT_P010LE ? 8 : 2,
                                     fmt == AV_PIX_FMT_P010LE ? 6 : 0, fmt == AV_PIX_FMT_P010LE);
        else
            out = midpoint<uint8_t>(previous, current, 0, 0, fmt == AV_PIX_FMT_NV12);
    }
    av_frame_free(&previous);
    previous = current;
    previous_pts = pts;
    return out;
}
