#ifndef I386_SCAN_STATE_INCLUDED
#define I386_SCAN_STATE_INCLUDED
class CI386ScanState { U32 locks; U8 down[256],mapped[256]; };
public extern U8 I386ScanMap(U8 code,Bool num=FALSE);
public extern U0 I386ScanStateReset(CI386ScanState *state);
public extern Bool I386ScanStateApply(CI386ScanState *state,U32 raw,I64 *event);
#endif
