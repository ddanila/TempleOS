#ifndef I386_HEAP_IRQ_INCLUDED
#define I386_HEAP_IRQ_INCLUDED
#include "/Kernel/I386/Heap.HH"
public extern Bool I386HeapIrqInit(CI386Heap *hc,U8 *base,I64 size);
public extern Bool I386HeapIrqValid(CI386Heap *hc);
public extern U8 *I386HeapIrqAlloc(CI386Heap *hc,I64 size,Bool zero=FALSE);
public extern Bool I386HeapIrqFree(CI386Heap *hc,U8 *ptr);
public extern I64 I386HeapIrqSize(CI386Heap *hc,U8 *ptr);
#endif
