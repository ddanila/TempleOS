#ifndef I386_KEYBOARD_EVENT_INCLUDED
#define I386_KEYBOARD_EVENT_INCLUDED
#include "/Kernel/I386/ScanSet1.HH"
#include "/Kernel/I386/ScanState.HH"
class CI386KeyboardState { CI386ScanSet1 packet; CI386ScanState keys; };
class CI386KeyEvent { I64 type,ch,scan; };
public extern U0 I386KeyboardReset(CI386KeyboardState *state);
public extern I64 I386KeyboardFeed(CI386KeyboardState *state,U8 data,U8 status,CI386KeyEvent *event);
//IRQ-side observer state must be distinct from the buffered reader state.
public extern Bool I386KeyboardBreakKey(CI386KeyboardState *state,U8 data,U8 status);
#endif
