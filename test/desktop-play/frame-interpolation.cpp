// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#include "frameinterpolator.h"
extern "C" {
#include <libavutil/pixfmt.h>
}
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <initializer_list>

static AVFrame *picture(int format, int offset, bool cut = false)
{
    AVFrame *f = av_frame_alloc();
    assert(f);
    f->format = format;
    f->width = 97;
    f->height = 65;
    f->pts = offset;
    assert(av_frame_get_buffer(f, 32) == 0);
    const bool wide = format == AV_PIX_FMT_YUV420P10LE || format == AV_PIX_FMT_P010LE;
    const bool semi = format == AV_PIX_FMT_NV12 || format == AV_PIX_FMT_P010LE;
    for (int p = 0; p < (semi ? 2 : 3); ++p) {
        const int w = p ? (f->width+1)/2 : f->width, h = p ? (f->height+1)/2 : f->height;
        const int channels = p && semi ? 2 : 1;
        for (int y = 0; y < h; ++y) {
            uint8_t *line = f->data[p] + y*f->linesize[p];
            for (int x = 0; x < w*channels; ++x) {
                const int v = p ? 112 + (x % channels) * 16 : cut ? 255 : ((x-offset+160)*7 + y*3) % 120;
                if (wide)
                    reinterpret_cast<uint16_t *>(line)[x] = uint16_t(v << (semi ? 8 : 2));
                else
                    line[x] = uint8_t(v);
            }
        }
    }
    return f;
}

int main()
{
    for (int fmt : {AV_PIX_FMT_YUV420P, AV_PIX_FMT_NV12, AV_PIX_FMT_YUV420P10LE, AV_PIX_FMT_P010LE}) {
        FrameInterpolator fx;
        AVFrame *a = picture(fmt, 0), *b = picture(fmt, 8), *reference = picture(fmt, 4), *cut = picture(fmt, 8, true);
        assert(!fx.push(a, 0, 1./30, false));
        AVFrame *mid = fx.push(b, 1./30, 1./30, false);
        assert(mid && mid->format == fmt && mid->pts == 4);
        // Verify the predicted position and chroma on padded odd-sized planes.
        for (int y = 10; y < 56; y += 7) {
            for (int x = 12; x < 84; x += 7) {
                const bool wide = fmt == AV_PIX_FMT_YUV420P10LE || fmt == AV_PIX_FMT_P010LE;
                const int bytes = wide ? 2 : 1;
                for (int k = 0; k < bytes; ++k)
                    assert(mid->data[0][y*mid->linesize[0]+x*bytes+k] == reference->data[0][y*reference->linesize[0]+x*bytes+k]);
            }
        }
        assert(mid->data[1][0] == reference->data[1][0]);
        av_frame_free(&mid);
        assert(!fx.push(cut, 2./30, 1./30, false));
        assert(!fx.push(b, 3./30, 1./30, true));
        assert(!fx.push(a, 1.0, 1./30, false));
        assert(!fx.push(b, 0.0, 1./30, false));
        av_frame_free(&a);
        av_frame_free(&b);
        av_frame_free(&cut);
        av_frame_free(&reference);
    }
    puts("Motion-compensated position, chroma, cuts, discontinuities and timestamp resets passed.");
}
