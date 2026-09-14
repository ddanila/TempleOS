#include "/Kernel/I386/String.HH"
public I64 StrCmp(U8 *left,U8 *right)
{//Match the public x64 primitive: unsigned bytes, result exactly -1, 0 or 1.
//Both arguments must be live zero-terminated strings; NULL is not a string.
  while(*left && *left==*right) { left++; right++; }
  if(*left<*right) return -1;
  if(*left>*right) return 1;
  return 0;
}
