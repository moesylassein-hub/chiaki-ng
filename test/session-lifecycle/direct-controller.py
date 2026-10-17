"""Exercise the actual C protocol/input functions without Qt or a PS5.

Extract the function bodies from production sources; stubs capture the outgoing
controller announcement and feedback lifecycle. Full builds validate integration.
"""
from pathlib import Path
import subprocess
import tempfile
import sys
root = Path(__file__).resolve().parents[2]
stream = (root / 'lib/src/streamconnection.c').read_text()
session = (root / 'lib/src/session.c').read_text()
def function(source, name):
    start = source.index(name + '(')
    while source.index(';', start) < source.index('{', start):
        start = source.index(name + '(', start + len(name))
    start = source.rfind('\n', 0, start) + 1
    end = source.index('\n}', start) + 2
    return source[start:end]
announcement = function(stream, 'stream_connection_send_controller_connection')
state = function(session, 'chiaki_session_set_controller_state')
start = stream.index('\tif(!session->connect_info.disable_remote_controller)')
end = stream.index('\n\n\tstream_connection->state = STATE_IDLE;', start)
startup = stream[start:end]
start = stream.index('\terr = chiaki_mutex_lock(&stream_connection->feedback_sender_mutex);', end)
end = stream.index('\n\terr = CHIAKI_ERR_SUCCESS;', start)
shutdown = stream[start:end]
prefix = r'''
#include <assert.h>
#include <stdint.h>
#include <stddef.h>
#include <string.h>
#define CHIAKI_EXPORT
#define CHIAKI_ERR_SUCCESS 0
#define CHIAKI_ERR_UNKNOWN 1
#define CHIAKI_LOGE(...) ((void)0)
#define CHIAKI_LOGI(...) ((void)0)
#define tkproto_TakionMessage_PayloadType_CONTROLLERCONNECTION 21
#define tkproto_ControllerConnectionPayload_ControllerType_DUALSENSE 6
#define tkproto_ControllerConnectionPayload_ControllerType_DUALSHOCK4 2
#define tkproto_TakionMessage_fields 0
typedef int ChiakiErrorCode;
typedef int ChiakiControllerState;
struct ChiakiSession;
struct ChiakiStreamConnection {
    ChiakiSession *session; int log, feedback_sender_mutex, feedback_sender, takion;
    bool feedback_sender_active;
};
struct ChiakiSession {
    struct { bool disable_remote_controller, enable_dualsense; } connect_info;
    ChiakiStreamConnection stream_connection;
    ChiakiControllerState controller_state;
};
struct tkproto_TakionMessage {
    int type; bool has_controller_connection_payload;
    struct { bool has_connected, connected, has_controller_id, has_controller_type; int controller_type; } controller_connection_payload;
};
struct pb_ostream_t { size_t bytes_written; };
static tkproto_TakionMessage sent;
static int initialized, finalized, submitted, transmitted;
static pb_ostream_t pb_ostream_from_buffer(uint8_t*, size_t) { return {1}; }
static bool pb_encode(pb_ostream_t*, int, tkproto_TakionMessage *m) { sent=*m; return true; }
static int chiaki_takion_send_message_data(int*,int,int,uint8_t*,size_t,void*) { transmitted++; return 0; }
static int chiaki_mutex_lock(int*) { return 0; }
static int chiaki_mutex_unlock(int*) { return 0; }
static int chiaki_feedback_sender_init(int*,int*) { initialized++; return 0; }
static void chiaki_feedback_sender_fini(int*) { finalized++; }
static void chiaki_feedback_sender_set_controller_state(int*,int*) { submitted++; }
'''
lifecycle = '\nstatic void lifecycle(ChiakiSession *session) {\nChiakiStreamConnection *stream_connection=&session->stream_connection; int err;\n' + startup + '\n' + shutdown + '\nreturn;\ndisconnect: assert(false);\n}\n'
suffix = r'''
int main() {
    for(int disabled=0;disabled<2;disabled++) {
        for(int dualsense=0;dualsense<2;dualsense++) {
            ChiakiSession s={}; s.stream_connection.session=&s;
            s.connect_info.disable_remote_controller=disabled;
            s.connect_info.enable_dualsense=dualsense;
            initialized=finalized=submitted=transmitted=0;
            assert(stream_connection_send_controller_connection(&s.stream_connection)==0);
            assert(transmitted==1 && sent.type==21);
            assert(sent.has_controller_connection_payload);
            assert(sent.controller_connection_payload.has_connected);
            assert(sent.controller_connection_payload.connected==!disabled);
            assert(sent.controller_connection_payload.has_controller_type==!disabled);
            if(!disabled) assert(sent.controller_connection_payload.controller_type==(dualsense?6:2));
            lifecycle(&s);
            assert(initialized==!disabled && finalized==!disabled && submitted==!disabled);
            assert(!s.stream_connection.feedback_sender_active);
            s.stream_connection.feedback_sender_active=true;
            ChiakiControllerState input=42;
            assert(chiaki_session_set_controller_state(&s,&input)==0);
            assert(s.controller_state==(disabled?0:42));
            assert(submitted==(disabled?0:2));
        }
    }
}
'''
with tempfile.TemporaryDirectory() as temp:
    src=Path(temp)/'controller.cpp'; exe=Path(temp)/'controller'
    src.write_text(prefix+announcement+'\n'+state+lifecycle+suffix)
    subprocess.run([sys.argv[1] if len(sys.argv)>1 else 'g++','-std=c++11','-Wall','-Wextra','-Werror',str(src),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True)
print('Direct-controller announcement, feedback lifecycle and input gating passed (on/off).')
