#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Kbc.HH"
//Exclusive controller ownership, IF clear. Poll budgets are not calibrated time.
public Bool I386KbcWrite(Bool controller,U8 value,I64 polls=100000)
{//Wait for IBF clear; do not discard queued output while waiting.
  I64 i,status;
  if (polls<1 || polls>100000) return FALSE;
  for (i=0;i<polls;i++) {
    status=InU8(0x64);
    if (status==255) return FALSE;
    if (!(status&2)) {
      if (controller) OutU8(0x64,value);
      else OutU8(0x60,value);
      return TRUE;
    }
    InU8(0x80);
  }
  return FALSE;
}
public Bool I386KbcRead(U8 *data,U8 *status)
{//Consume one raw byte with its status, including AUX/parity/timeout flags.
  I64 value;
  if (!data || !status || data==status) return FALSE;
  value=InU8(0x64);
  if (value==255 || !(value&1)) return FALSE;
  *data=InU8(0x60); *status=value;
  return TRUE;
}
public Bool I386KbcReadWait(U8 *data,U8 *status,I64 polls=100000)
{
  I64 i;
  if (!data || !status || data==status || polls<1 || polls>100000) return FALSE;
  for (i=0;i<polls;i++) {
    if (I386KbcRead(data,status)) return TRUE;
    InU8(0x80);
  }
  return FALSE;
}
public Bool I386KbcDrain(I64 polls=100000)
{//Boot-time discard only; runtime code must route keyboard/auxiliary bytes.
  I64 i,status;
  if (polls<1 || polls>100000) return FALSE;
  for (i=0;i<polls;i++) {
    status=InU8(0x64);
    if (status==255) return FALSE;
    if (!(status&1)) return TRUE;
    InU8(0x60); InU8(0x80);
  }
  return FALSE;
}
