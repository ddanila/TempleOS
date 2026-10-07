#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexState.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/CharBitmaps.HC"
CI386Heap state_heap;
I64 state_free_errors;
extern I64 NativeControlTest();
I64 Main(I64 unused,I64 unused2)
{
  if(!I386HeapInit(&state_heap,0x50000,65536)) return 8;
  OutU8(0x21,255); OutU8(0xA1,255);
  return NativeControlTest;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexState.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"
U8 *StateAlloc(I64 size) { return I386HeapAlloc(&state_heap,size,TRUE); }
U0 StateFree(U8 *allocation) { if(!I386HeapFree(&state_heap,allocation)) state_free_errors++; }
#include "/Kernel/I386/Hash.HC"
#include "/Kernel/I386/HashTableCore.HC"
#include "T:/Control.HC"
