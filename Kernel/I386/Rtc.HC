#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Rtc.HH"
//Boot-owned CMOS: one CPU, IF clear, NMI disabled throughout ownership.
//Port 0x70 is not read to infer an old selector or NMI policy.
public U8 I386RtcRead(U8 index)
{
  OutU8(0x70,(index&0x7F)|0x80); InU8(0x80);
  return InU8(0x71);
}
public U0 I386RtcWrite(U8 index,U8 value)
{
  OutU8(0x70,(index&0x7F)|0x80); InU8(0x80);
  OutU8(0x71,value); InU8(0x80);
}
public U8 I386RtcAck()
{//Read-to-clear interrupt flags and deassert IRQ8 before PIC EOI.
  return I386RtcRead(0x0C);
}
public Bool I386RtcStart(CI386RtcState *state,I64 rate)
{//Caller zeroes state; IRQ8 must be masked during start/stop.
  I64 a,b;
  if (!state || state->active || rate<3 || rate>15) return FALSE;
  a=I386RtcRead(0x0A)&0x7F; b=I386RtcRead(0x0B);
  //Require the standard running 32768 Hz divider; do not restart a stopped clock.
  if ((a&0x70)!=0x20 || (b&0x80)) return FALSE;
  state->status_a=a; state->status_b=b;
  I386RtcWrite(0x0B,b&~0x70);
  I386RtcWrite(0x0A,(a&0x70)|rate);
  I386RtcAck;
  state->active=1;
  I386RtcWrite(0x0B,(b&~0x70)|0x40);
  return TRUE;
}
public Bool I386RtcStop(CI386RtcState *state)
{//Restore configuration, not interrupt events consumed during ownership.
  if (!state || state->active!=1) return FALSE;
  I386RtcWrite(0x0B,state->status_b&~0x70);
  I386RtcWrite(0x0A,state->status_a);
  I386RtcAck;
  I386RtcWrite(0x0B,state->status_b);
  state->active=0;
  return TRUE;
}
