#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Arc.HH"
#include "/Kernel/I386/Heap.HH"
#assert sizeof(CArcCompress)==17
#assert sizeof(CArcEntry)==12
#assert sizeof(CArcCtrl)==65664
public extern U64 ArcCoreTest(CArcCtrl *c,I64 bits);
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;
  CArcCtrl *c;
  U64 result;
  if(!I386HeapInit(&heap,0x40000,131072)) return 1;
  c=I386HeapAlloc(&heap,sizeof(CArcCtrl),TRUE); if(!c) return 2;
  result=ArcCoreTest(c,7);
  if(result!=ARC_EXPECTED7 || !I386HeapFree(&heap,c)) return 3;
  c=I386HeapAlloc(&heap,sizeof(CArcCtrl),TRUE); if(!c) return 4;
  result=ArcCoreTest(c,8);
  if(result!=ARC_EXPECTED8 || !I386HeapFree(&heap,c)) return 5;
  if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 6;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Arc.HC"
U0 ArcStep(CArcCtrl *c) { I386ArcEntryGet(c); }
#include "T:/Core.HC"
