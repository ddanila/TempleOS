#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Heap.HC"
extern U64 Hash(U8 *base,I64 size);
#include "Public.HC"
I64 Main(I64 a,I64 b) { return PublicHeapTest; }
U64 Hash(U8 *base,I64 size)
{
  U64 h=0x123456789ABCDEF0;
  I64 i;
  for (i=0;i<size;i++) h=(h<<5)^base[i]^(h>>59);
  return h;
}
