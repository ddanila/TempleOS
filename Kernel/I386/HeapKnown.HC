#ifndef I386_HEAP_KNOWN_INCLUDED
#define I386_HEAP_KNOWN_INCLUDED
#include "/Kernel/I386/Heap.HH"
Bool I386HeapKnownSize(CI386Heap *heap,U8 *ptr,U32 expected)
{//Caller holds IRQ exclusion and has just validated this unchanged heap.
  //Still walk physical block boundaries: an interior pointer can contain a
  //forged header, and must never be accepted as an allocation.
  U8 *target=ptr-16;
  U32 found=0;
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
    CMP EAX,U32 &expected[EBP]
    JNE @@30
    MOV U32 &found[EBP],1
@@30:
    POP ESI
    POP ECX
    POP EAX
  }
  return found!=0;
}
Bool I386HeapKnownAtLeast(CI386Heap *heap,U8 *ptr,U32 minimum)
{//Caller holds IRQ exclusion and has just validated this unchanged heap.
  //Accept only an actual used block with enough requested bytes.
  //Still walk physical block boundaries: an interior pointer can contain a
  //forged header, and must never be accepted as an allocation.
  U8 *target=ptr-16;
  U32 found=0;
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
    CMP EAX,U32 &minimum[EBP]
    JB @@30
    MOV U32 &found[EBP],1
@@30:
    POP ESI
    POP ECX
    POP EAX
  }
  return found!=0;
}
#endif
