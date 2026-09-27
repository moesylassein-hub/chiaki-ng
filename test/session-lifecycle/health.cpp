#include "streamhealth.h"
#include <cassert>
#include <iostream>
using H = StreamHealth;
int main()
{
    H h;
    // Defaults can leave both automation features disabled even with total loss.
    h.reset(0);
    for(int t=1000;t<=200000;t+=1000)
        assert(h.tick(t,0,0,1,true,true,false,false,30000,30000)==H::None);
    // Five seconds without frames after startup: soft repair, then reconnect.
    h.reset(0);
    for(int t=1000;t<15000;t+=1000)
        assert(h.tick(t,0,0,0,true,true,true,false,30000,30000)==H::None);
    assert(h.tick(15000,0,0,0,true,true,true,false,30000,30000)==H::RepairVideo);
    for(int t=16000;t<20000;t+=1000)
        assert(h.tick(t,0,0,0,true,true,true,false,30000,30000)==H::None);
    assert(h.tick(20000,0,0,0,true,true,true,false,30000,30000)==H::ReconnectVideo);
    // A resumed frame cancels escalation; a later freeze gets another soft repair.
    assert(h.tick(21000,21000,21000,0,true,true,true,false,30000,30000)==H::None);
    for(int t=22000;t<26000;t+=1000) h.tick(t,21000,t,0,true,true,true,false,30000,30000);
    assert(h.tick(26000,21000,26000,0,true,true,true,false,30000,30000)==H::RepairVideo);
    // No video / intentional audio disabling does not cause recovery.
    h.reset(0);
    for(int t=1000;t<60000;t+=1000)
        assert(h.tick(t,0,1,0,false,false,true,false,30000,30000)==H::None);
    // Audio detection waits for evidence that audio actually started.
    h.reset(0);
    for(int t=1000;t<=20000;t+=1000)
        assert(h.tick(t,t,0,0,true,true,true,false,30000,30000)==H::None);
    assert(h.tick(21000,21000,1000,0,true,true,true,false,30000,30000)==H::ReconnectAudio);
    // Sustained loss reduces only after startup cooldown, respecting the floor.
    h.reset(0);
    for(int t=1000;t<30000;t+=1000)
        assert(h.tick(t,t,t,.1,true,true,false,true,30000,30000)==H::None);
    assert(h.tick(30000,30000,30000,.1,true,true,false,true,30000,30000)==H::LowerBitrate);
    assert(H::lower(30000,30000)==22500);
    assert(H::lower(9000,30000)==8000);
    assert(H::lower(5000,5000)==5000);
    assert(H::raise(29000,30000)==30000);
    // Restore only after two minutes continuously healthy; one burst resets it.
    h.reset(0);
    for(int t=1000;t<=120000;t+=1000)
        assert(h.tick(t,t,t,0,true,true,false,true,15000,30000)==H::None);
    assert(h.tick(121000,121000,121000,.02,true,true,false,true,15000,30000)==H::None);
    for(int t=122000;t<241000;t+=1000)
        assert(h.tick(t,t,t,0,true,true,false,true,15000,30000)==H::None);
    assert(h.tick(241000,241000,241000,0,true,true,false,true,15000,30000)==H::RaiseBitrate);
    // Wake from suspend is not a freeze or evidence for raising bitrate.
    assert(h.tick(500000,0,0,1,true,true,true,true,15000,30000)==H::None);
    std::cout << "Stream health regression checks passed\n";
}
