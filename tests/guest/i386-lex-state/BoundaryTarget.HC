#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexState.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Bits.HH"
CI386Heap state_heap;
extern I64 NativeSnapshotBoundaryTest();
extern I64 NativeSnapshotNestedTest();
extern I64 NativeSnapshotAllocationTest();
I64 Main(I64 unused,I64 unused2)
{
  if(!I386HeapInit(&state_heap,0x50000,65536)) return 8;
  I64 result=NativeSnapshotBoundaryTest;
  if(result) return result;
  result=NativeSnapshotNestedTest;
  if(result) return result;
  return NativeSnapshotAllocationTest;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexState.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
I64 InputRead(CCmpCtrl *cc,I64 *lines) { return I386LexRawChar(&state_heap,cc,lines); }
#include "T:/SnapshotBoundary.HC"
