#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
extern U64 Hash(U8 *bytes,I64 count);
extern I64 BackingAccountingTest();
I64 Main(I64 unused_a,I64 unused_b) { return BackingAccountingTest; }
U64 Hash(U8 *bytes,I64 count)
{
  U64 hash=0x123456789ABCDEF0; I64 i;
  for(i=0;i<count;i++) hash=(hash<<5)^(hash>>59)^bytes[i];
  return hash;
}
#include "BackingAccounting.HC"
