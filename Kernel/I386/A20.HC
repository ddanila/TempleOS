#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/A20.HH"
public Bool I386A20Test()
{//Boot-only, interrupts disabled: caller reserves both scratch bytes and has RAM there.
//The memory selector reserves the first 64 KiB above 1 MiB for this purpose.
  U8 *low=0x5100,*high=0x105100,saved_low=*low,saved_high=*high;
  Bool result;
  *low=0x55; *high=0xAA;
  InU8(0x80);
  result=*low==0x55 && *high==0xAA;
  if (result) {
    *low=0xAA; *high=0x55;
    InU8(0x80);
    result=*low==0xAA && *high==0x55;
  }
  *high=saved_high; *low=saved_low;
  return result;
}

Bool I386A20KbcEmpty(I64 polls)
{//Boot ownership: discard pending keyboard bytes before issuing a controller command.
  I64 i,missing=0,status;
  for (i=0;i<polls;i++) {
    InU8(0x80);
    status=InU8(0x64);
    if (status==255) {
      if (++missing==32) return FALSE;
    } else missing=0;
    if (status&1) InU8(0x60);
    else if (!(status&2)) return TRUE;
  }
  return FALSE;
}

Bool I386A20Wait()
{
  I64 i;
  for (i=0;i<128;i++) if (I386A20Test()) return TRUE;
  return FALSE;
}

public I64 I386A20Enable(Bool allow_fast=FALSE,I64 poll_limit=100000)
{//Returns 1 already enabled, 2 keyboard controller, 3 fast gate, or 0 failure.
//Use before keyboard/mouse initialization; the output-port value is a boot default.
//The caller must establish scratch RAM coverage before testing addresses above 1 MiB.
  I64 value;
  if (poll_limit<0 || poll_limit>100000) return 0;
  if (I386A20Test()) return 1;
  if (I386A20KbcEmpty(poll_limit)) {
    OutU8(0x64,0xD1);
    if (I386A20KbcEmpty(poll_limit)) {
      //8042 output port: deassert reset and enable A20 with the standard boot value.
      OutU8(0x60,0xDF);
      if (I386A20KbcEmpty(poll_limit) && I386A20Wait()) return 2;
    }
  }
  if (allow_fast) {
    value=InU8(0x92);
    if (value!=255) {
      OutU8(0x92,(value|2)&0xFE);
      if (I386A20Wait()) return 3;
    }
  }
  return 0;
}
