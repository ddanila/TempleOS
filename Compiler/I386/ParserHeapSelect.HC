#include "/Kernel/I386/Heap.HH"
CI386HeapBlock *I386ParserHeapSelectKnown(CI386Heap *heap,U32 need,Bool high)
{//Caller validated this unchanged heap and holds IRQ exclusion.
  CI386HeapBlock *selected=0;
  asm {
    PUSH EAX
    PUSH ECX
    PUSH EDX
    PUSH ESI
    MOV ESI,U32 &heap[EBP]
    MOV ECX,U32 CI386Heap.size[ESI]
    MOV ESI,U32 CI386Heap.base[ESI]
    MOV EDX,U32 &need[EBP]
@@10:
    CMP U32 CI386HeapBlock.tag[ESI],I386_HEAP_FREE
    JNE @@20
    CMP U32 CI386HeapBlock.span[ESI],EDX
    JB @@20
    MOV U32 &selected[EBP],ESI
    CMP U8 &high[EBP],0
    JE @@30
@@20:
    MOV EAX,U32 CI386HeapBlock.span[ESI]
    ADD ESI,EAX
    SUB ECX,EAX
    JNZ @@10
@@30:
    POP ESI
    POP EDX
    POP ECX
    POP EAX
  }
  return selected;
}
