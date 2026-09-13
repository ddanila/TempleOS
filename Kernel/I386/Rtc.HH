#ifndef I386_RTC_INCLUDED
#define I386_RTC_INCLUDED
class CI386RtcState { U32 status_a,status_b,active; };
public extern U8 I386RtcRead(U8 index);
public extern U0 I386RtcWrite(U8 index,U8 value);
public extern Bool I386RtcStart(CI386RtcState *state,I64 rate);
public extern Bool I386RtcStop(CI386RtcState *state);
public extern U8 I386RtcAck();
#endif
