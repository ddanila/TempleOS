#include "/Kernel/I386/KeyboardEvent.HH"
#include "/Kernel/I386/ScanChar.HH"
public U0 I386KeyboardReset(CI386KeyboardState *state)
{
  if (!state) return;
  I386ScanSet1Reset(&state->packet);
  I386ScanStateReset(&state->keys);
}
public I64 I386KeyboardFeed(CI386KeyboardState *state,U8 data,U8 status,CI386KeyEvent *event)
{//Single consumer. 1 event, 0 incomplete/filtered, -1 invalid/discontinuous input.
  U32 raw;
  I64 result,scan;
  if (!state || !event) return -1;
  result=I386ScanSet1Feed(&state->packet,data,status,&raw);
  if (result<0) { I386KeyboardReset(state); return -1; }
  if (!result) return 0;
  if (!I386ScanStateApply(&state->keys,raw,&scan)) {
    I386KeyboardReset(state); return -1;
  }
  if (!(scan&0x8000)) return 0;
  //KbdHndlr consumes NEW_KEY before exposing the scan pair to message clients.
  scan&=~0x0000800000008000;
  event->type=2;
  if (scan&0x100) event->type=3;
  event->ch=I386ScanCode2Char(scan);
  event->scan=scan;
  return 1;
}
