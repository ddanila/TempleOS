#ifndef I386_HEAP_KNOWN_INCLUDED
#define I386_HEAP_KNOWN_INCLUDED
#include "/Kernel/I386/Heap.HH"
I64 I386HeapKnownRequested(CI386Heap *heap,U8 *ptr)
{//Caller holds IRQ exclusion and has just validated this unchanged heap.
  //Walk physical block boundaries before interpreting any candidate header.
  U8 *target=ptr-16;
  U32 requested=0xFFFFFFFF;
  asm {
    PUSH EAX
    PUSH ECX
    PUSH ESI
    MOV ESI,U32 &heap[EBP]
    MOV ECX,U32 CI386Heap.size[ESI]
    MOV ESI,U32 CI386Heap.base[ESI]
@@10:
    CMP ESI,U32 &target[EBP]
    JE @@20
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    ADD ESI,EAX
    SUB ECX,EAX
    JNZ @@10
    JMP @@30
@@20:
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_USED
    JNE @@30
    MOV EAX,U32 CI386HeapBlock.requested[ESI]
    MOV U32 &requested[EBP],EAX
@@30:
    POP ESI
    POP ECX
    POP EAX
  }
  if(requested==0xFFFFFFFF) return -1;
  return requested;
}
Bool I386HeapKnownSize(CI386Heap *heap,U8 *ptr,U32 expected)
{
  I64 requested=I386HeapKnownRequested(heap,ptr);
  return requested>=0 && requested==expected;
}
Bool I386HeapKnownAtLeast(CI386Heap *heap,U8 *ptr,U32 minimum)
{
  I64 requested=I386HeapKnownRequested(heap,ptr);
  return requested>=0 && requested>=minimum;
}
#endif
