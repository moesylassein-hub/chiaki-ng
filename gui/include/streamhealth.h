// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
#pragma once
#include <algorithm>
#include <cstdint>

// Clock supplied by caller: deterministic and independent of wall-clock changes.
class StreamHealth
{
public:
    enum Action { None, RepairVideo, ReconnectVideo, ReconnectAudio, LowerBitrate, RaiseBitrate };
    void reset(int64_t now) { started = now; bad = good = 0; repair = -1; last = now; }
    Action tick(int64_t now, int64_t video, int64_t audio, double loss,
                bool videoEnabled, bool audioEnabled, bool recover, bool adaptive,
                unsigned bitrate, unsigned ceiling)
    {
        // Ignore a suspended event loop instead of interpreting sleep as packet loss.
        if (now - last > 5000) { reset(now); return None; }
        const int64_t elapsed = std::max<int64_t>(0, now - last); last = now;
        if (now - started < 15000) return None;
        if (recover && videoEnabled && now - std::max(video, started) >= 5000) {
            if (repair < 0) { repair = now; return RepairVideo; }
            if (now - repair >= 5000) return ReconnectVideo;
            return None;
        }
        repair = -1;
        if (recover && audioEnabled && audio > 0 && now - audio >= 10000
            && videoEnabled && now - video < 2000) return ReconnectAudio;
        if (!adaptive) { bad = good = 0; return None; }
        bad = loss >= 0.03 ? bad + elapsed : 0;
        good = loss <= 0.005 ? good + elapsed : 0;
        if (now - started < 30000) return None;
        if (bad >= 5000 && bitrate > floor(ceiling)) { bad = good = 0; return LowerBitrate; }
        if (good >= 120000 && bitrate < ceiling) { bad = good = 0; return RaiseBitrate; }
        return None;
    }
    static unsigned floor(unsigned ceiling) { return std::min(ceiling, 8000u); }
    static unsigned lower(unsigned value, unsigned ceiling) { return std::max(floor(ceiling), value - value / 4); }
    static unsigned raise(unsigned value, unsigned ceiling) { return std::min(ceiling, value + std::max(1000u, ceiling / 10)); }
private:
    int64_t started = 0, last = 0, bad = 0, good = 0, repair = -1;
};
