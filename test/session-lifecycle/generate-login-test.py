"""Compile the actual login-message handler and fallback gate with small stubs."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[2]
ctrl = (root / 'lib/src/ctrl.c').read_text()
session = (root / 'lib/src/session.c').read_text()

def function(source, name):
    start = source.index(name + '(')
    while source.index(';', start) < source.index('{', start):
        start = source.index(name + '(', start + len(name))
    start = source.rfind('\n', 0, start) + 1
    return source[start:source.index('\n}', start) + 2]

enum_start = ctrl.index('typedef enum ctrl_login_state_t')
enum_end = ctrl.index('} CtrlLoginState;', enum_start) + len('} CtrlLoginState;')
prefix = r'''
#undef NDEBUG
#include <cassert>
#include <cstddef>
#include <cstdint>
using ChiakiErrorCode = int;
constexpr int CHIAKI_ERR_SUCCESS = 0;
#define CHIAKI_LOGW(...) ((void)0)
#define CHIAKI_LOGI(...) ((void)0)
static int signals = 0;
struct Mutex { bool held = false; };
static int chiaki_mutex_lock(Mutex *m) { assert(!m->held); m->held = true; return 0; }
static void chiaki_mutex_unlock(Mutex *m) { assert(m->held); m->held = false; }
static void chiaki_cond_signal(int*) { ++signals; }
struct ChiakiSession {
    Mutex state_mutex;
    int state_cond = 0;
    int ctrl_login_state = -1;
    bool ctrl_session_id_received = false;
    bool ctrl_login_pin_requested = false;
};
struct ChiakiCtrl { ChiakiSession *session; bool login_pin_requested = false; };
'''
suffix = r'''
int main() {
    ChiakiSession s;
    ChiakiCtrl c;
    c.session = &s;
    assert(!session_ctrl_login_incomplete(&s)); // no status: preserve legacy fallback
    ctrl_message_received_login(&c, nullptr, 0);
    assert(s.ctrl_login_state == -1); // empty message must not dereference payload
    for (unsigned int status = 2; status <= 255; ++status) {
        uint8_t p = static_cast<uint8_t>(status);
        ctrl_message_received_login(&c, &p, 1);
        assert(s.ctrl_login_state == int(status));
        assert(session_ctrl_login_incomplete(&s));
        assert(!s.state_mutex.held && signals == 0);
        s.ctrl_session_id_received = true;
        assert(!session_ctrl_login_incomplete(&s)); // real session ID wins
        s.ctrl_session_id_received = false;
    }
    uint8_t success = 0;
    c.login_pin_requested = true;
    ctrl_message_received_login(&c, &success, 1);
    assert(!session_ctrl_login_incomplete(&s)); // late success replaces unknown state
    assert(!c.login_pin_requested);
    uint8_t incorrect = 1;
    ctrl_message_received_login(&c, &incorrect, 1);
    assert(signals == 0); // no unsolicited PIN prompt
    c.login_pin_requested = true;
    ctrl_message_received_login(&c, &incorrect, 1);
    assert(s.ctrl_login_pin_requested && signals == 1);
    assert(!s.state_mutex.held && !session_ctrl_login_incomplete(&s));
}
'''

Path(sys.argv[1]).write_text(prefix + ctrl[enum_start:enum_end] + '\n' +
    function(ctrl, 'ctrl_message_received_login') + '\n' +
    function(session, 'session_ctrl_login_incomplete') + suffix)
