"""Compile production packet accounting and disconnect wait predicates against small stubs."""
from pathlib import Path
import subprocess, tempfile, sys, re
root = Path(__file__).resolve().parents[2]
def function(s, name):
    for m in re.finditer(r'[^\n]*\b'+re.escape(name)+r'\([^;]*?\)\n\{', s):
        start=m.start();end=s.index('\n}',m.end())+2
        return s[start:end]
    raise ValueError(name)
header=(root/'lib/include/chiaki/packetstats.h').read_text()
struct=header[header.index('typedef struct'):header.index('CHIAKI_EXPORT')]
source=(root/'lib/src/packetstats.c').read_text()
source=re.sub(r'^#include.*$', '', source, flags=re.M)
prefix=r'''
#include <cstdint>
#include <cstring>
#include <cassert>
#include <mutex>
#include <thread>
#define CHIAKI_EXPORT
#define CHIAKI_ERR_SUCCESS 0
using ChiakiErrorCode=int;
using ChiakiSeqNum16=uint16_t;
using ChiakiMutex=std::mutex;
int chiaki_mutex_init(ChiakiMutex*, bool) { return 0; }
int chiaki_mutex_lock(ChiakiMutex* m) { m->lock(); return 0; }
int chiaki_mutex_unlock(ChiakiMutex* m) { m->unlock(); return 0; }
void chiaki_mutex_fini(ChiakiMutex*) {}
bool chiaki_seq_num_16_gt(uint16_t a,uint16_t b) { return a!=b && uint16_t(a-b)<32768; }
'''
main=r'''
int main() {
 ChiakiPacketStats s; assert(chiaki_packet_stats_init(&s)==0);
 uint64_t r,l;
 // First sequence can be arbitrary; duplicates do not become loss.
 chiaki_packet_stats_push_seq(&s,65533);
 chiaki_packet_stats_push_seq(&s,65533);
 chiaki_packet_stats_push_seq(&s,65535);
 chiaki_packet_stats_push_seq(&s,65534); // reordered inside interval
 chiaki_packet_stats_get(&s,true,&r,&l); assert(r==3 && l==0);
 chiaki_packet_stats_push_seq(&s,0); // wraps, without 64-bit underflow
 chiaki_packet_stats_push_seq(&s,2); // sequence 1 genuinely missing
 chiaki_packet_stats_push_seq(&s,2);
 chiaki_packet_stats_get(&s,true,&r,&l); assert(r==2 && l==1);
 chiaki_packet_stats_push_seq(&s,1); // too late; already reported missing
 chiaki_packet_stats_get(&s,true,&r,&l); assert(r==0 && l==0);
 chiaki_packet_stats_get_totals(&s,&r,&l); assert(r==5 && l==1);
 std::thread writer([&] { for(int i=0;i<10000;i++) chiaki_packet_stats_push_generation(&s,9,1); });
 for(int i=0;i<1000;i++) chiaki_packet_stats_get(&s,true,&r,&l);
 writer.join(); chiaki_packet_stats_get(&s,true,&r,&l);
 chiaki_packet_stats_get_totals(&s,&r,&l); assert(r==90005 && l==10001);
 chiaki_packet_stats_fini(&s);
}
'''
stream=(root/'lib/src/streamconnection.c').read_text()
senk=(root/'lib/src/senkusha.c').read_text()
# Exercise both predicates: failures must wake waiters immediately.
predicates=function(stream,'state_finished_cond_check').replace('state_finished_cond_check','stream_pred')+'\n'+function(senk,'state_finished_cond_check').replace('state_finished_cond_check','senk_pred')
predicates=predicates.replace('= user;', '= static_cast<ChiakiStreamConnection *>(user);', 1)
predicates=predicates.replace('= user;', '= static_cast<ChiakiSenkusha *>(user);', 1)
predsource=r'''
#include <cassert>
struct ChiakiStreamConnection { bool state_finished, state_failed, should_stop, remote_disconnected; };
struct ChiakiSenkusha { bool state_finished, state_failed, should_stop; };
'''+predicates+r'''
int main() {
 ChiakiStreamConnection s={}; ChiakiSenkusha k={};
 assert(!stream_pred(&s) && !senk_pred(&k));
 s.state_failed=true; k.state_failed=true;
 assert(stream_pred(&s) && senk_pred(&k));
 s={}; k={}; s.should_stop=true; k.should_stop=true;
 assert(stream_pred(&s) && senk_pred(&k));
}
'''
with tempfile.TemporaryDirectory() as d:
 for name,body in [('packets',prefix+struct+source+main),('disconnect',predsource)]:
  src=Path(d)/(name+'.cpp');exe=Path(d)/name;src.write_text(body)
  subprocess.run([sys.argv[1] if len(sys.argv)>1 else 'c++','-std=c++11','-pthread','-fsanitize=address,undefined',str(src),'-o',str(exe)],check=True)
  subprocess.run([str(exe)],check=True)
print('Packet accounting and disconnect regressions passed')
