//Original source helpers use the retained native function-segment lookup.
//Match KUtils' signed lower clamp followed by upper clamp, including lo>hi.
I64 NativeSourceClampI64(I64 num,I64 lo,I64 hi)
{
  if(num<lo)num=lo;
  if(num>hi)num=hi;
  return num;
}
#define ClampI64 NativeSourceClampI64
#include "/Kernel/SourceLinkCore.HC"
