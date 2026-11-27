#ifndef I386_HEAP_FREE_BLOCK_INCLUDED
#define I386_HEAP_FREE_BLOCK_INCLUDED
#include "/Kernel/I386/Heap.HH"
U0 I386HeapFreeBlock(CI386Heap *heap,CI386HeapBlock *block,CI386HeapBlock *previous)
{//The caller has validated the arena and found the exact live block.
  CI386HeapBlock *next;
  heap->used-=block->span;heap->allocations--;
  block->tag=I386_HEAP_FREE;block->requested=0;
  if(block(U8 *)+block->span<heap->base+heap->size) {
    next=block(U8 *)+block->span;
    if(next->tag==I386_HEAP_FREE)block->span+=next->span;
  }
  if(previous && previous->tag==I386_HEAP_FREE)previous->span+=block->span;
}
#endif
