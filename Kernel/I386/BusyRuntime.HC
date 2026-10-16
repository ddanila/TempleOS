#include "/Kernel/TimeTypes.HH"
import CCntsGlbls cnts;
#include "/Kernel/PortNopCore.HC"
U32 NativeHPETWord(I64 offset)
{//The native flat address space maps the HPET physical registers directly.
  return *(0xFED000F0+offset)(U32 *);
}
I64 HPET()
{//Retry a split 64-bit counter read if the high word changes across the low read.
  I64 high,low,again;
  do {
    high=NativeHPETWord(4);
    low=NativeHPETWord(0);
    again=NativeHPETWord(4);
  } while(high!=again);
  return high<<32|low;
}
#include "/Kernel/BusyCore.HC"
