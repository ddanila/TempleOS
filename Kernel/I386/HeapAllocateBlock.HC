//Internal mutation only. Caller has validated the complete arena and selected
//a fitting physical free block while holding exclusion without intervening calls.
U8 *I386HeapAllocateBlock(CI386Heap *hc,CI386HeapBlock *block,U32 size,
    U32 need,Bool zero,Bool high)
{
  CI386HeapBlock *rest;
  U8 *result;
  U32 offset,prefix,i,requested=size;
  if(high) {
    prefix=block->span-need;
  if(prefix>=24) {
    block->span=prefix;
    block=block(U8 *)+prefix;
    block->span=need;block->reserved=0;
  }
  block->requested=size;block->tag=I386_HEAP_USED;
  hc->used+=block->span;hc->allocations++;
  if(hc->used>hc->peak)hc->peak=hc->used;
  result=block(U8 *)+16;
  if(zero)for(i=0;i<requested;i++)result[i]=0;
  return result;
  }
  offset=block(U8 *)-hc->base;
  if(block->span-need>=24) {
    rest=hc->base+offset+need;
    rest->span=block->span-need; rest->requested=0;
    rest->tag=I386_HEAP_FREE; rest->reserved=0;
    block->span=need;
  }
  block->requested=size; block->tag=I386_HEAP_USED;
  hc->used+=block->span; hc->allocations++;
  if(hc->used>hc->peak) hc->peak=hc->used;
  result=hc->base+offset+16;
  if(zero) for(i=0;i<requested;i++) result[i]=0;
  return result;
}
