#include "/Kernel/I386/ScanSet1.HH"
public U0 I386ScanSet1Reset(CI386ScanSet1 *state)
{
  if (state) { state->extended=0; state->pause=0; }
}
public I64 I386ScanSet1Feed(CI386ScanSet1 *state,U8 data,U8 status,U32 *scan)
{//Single consumer. Return 1 event, 0 no event, -1 invalid/corrupt input.
  U32 value,expected;
  if (!state || !scan) return -1;
  if (!(status&1) || (status&0x20)) return 0;
  if ((status&0xC0) || !data || data==255) {
    I386ScanSet1Reset(state); return -1;
  }
  //Command replies are routed by a transaction owner, never emitted as keys.
  if (data==0xFA || data==0xFE || data==0xEE) {
    I386ScanSet1Reset(state); return 0;
  }
  if (state->pause) {
    expected=0;
    if (state->pause==1) expected=0x1D;
    if (state->pause==2) expected=0x45;
    if (state->pause==3) expected=0xE1;
    if (state->pause==4) expected=0x9D;
    if (state->pause==5) expected=0xC5;
    if (data!=expected) { I386ScanSet1Reset(state); return -1; }
    state->pause++;
    if (state->pause==6) {
      I386ScanSet1Reset(state); *scan=0x61; return 1;
    }
    return 0;
  }
  if (data==0xE1) { state->extended=0; state->pause=1; return 0; }
  if (data==0xE0) { state->extended=1; return 0; }
  value=data&0x7F;
  if (state->extended) value|=0x80;
  state->extended=0;
  //Print Screen/keypad fake shifts must not change real Shift state.
  if (value==0xAA || value==0xB6) return 0;
  if (data&0x80) value|=0x100;
  *scan=value; return 1;
}
