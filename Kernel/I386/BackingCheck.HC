#ifndef I386_BACKING_CHECK_IMPLEMENTED
#define I386_BACKING_CHECK_IMPLEMENTED
#include "/Kernel/I386/MemoryBacking.HH"
Bool I386BackingCheckValid(CI386BackingPool *pool,CI386Heap *heap)
{//Count only verified backing allocations when separating cache from payloads.
  CI386BackingRegion *region;
  CI386HeapBlock *block;
  I64 count=0,retained=0;
  U64 address,base;
  if(!pool || pool->heap!=heap || pool->signature!=I386_POOL_SIGNATURE ||
      pool->backing_signature!=I386_BACKING_SIGNATURE || pool->locked_flags || pool->growing ||
      !I386HeapValid(heap)) return FALSE;
  for(region=pool->owned;region;region=region->next_owned) {
    if(count++>=pool->owned_count || I386HeapSize(heap,region)!=region->request ||
        region->pool!=pool || region->reserve_hold>1) return FALSE;
    block=region(U8 *)-sizeof(CI386HeapBlock);
    address=(region+0)(U64); base=(region->base+0)(U64);
    if(block->span!=region->span || base<address+sizeof(CI386BackingRegion) ||
        base+region->size>address+region->request) return FALSE;
    retained+=region->span;
  }
  return count==pool->owned_count && retained==pool->retained;
}
class CI386BackingCheck {
  CI386Heap *heap,*backing_heap;
  CHeapCtrl *control;
  CI386BackingPool *pool;
  I64 used,allocations,public_used,retained,count,backing_used,backing_allocations;
};
Bool I386BackingCheckSave(CI386BackingCheck *check,CI386Heap *heap,CHeapCtrl *control)
{//Diagnostic baseline: owned backing cache is distinct from live payloads.
  CI386BackingPool *pool;
  if(!check || !control || control->hc_signature!=HEAP_CTRL_SIGNATURE_VAL ||
      !(pool=control->bp) || !I386HeapValid(heap) ||
      !I386BackingCheckValid(pool,pool->heap)) return FALSE;
  check->heap=heap; check->backing_heap=pool->heap;
  check->control=control; check->pool=pool;
  check->used=heap->used; check->allocations=heap->allocations;
  check->public_used=control->used_u8s;
  check->retained=pool->retained; check->count=pool->owned_count;
  check->backing_used=pool->heap->used; check->backing_allocations=pool->heap->allocations;
  return TRUE;
}
Bool I386BackingCheckRestored(CI386BackingCheck *check)
{
  if(!check || check->control->bp!=check->pool ||
      check->control->hc_signature!=HEAP_CTRL_SIGNATURE_VAL ||
      check->control->used_u8s!=check->public_used ||
      check->pool->heap!=check->backing_heap || !I386HeapValid(check->heap) ||
      !I386BackingCheckValid(check->pool,check->backing_heap)) return FALSE;
  if(check->backing_heap->used-check->pool->retained!=check->backing_used-check->retained ||
      check->backing_heap->allocations-check->pool->owned_count!=check->backing_allocations-check->count)
    return FALSE;
  //A private compiler arena is separate from the public backing allocator.
  //Its complete bytes and allocation count must recover without normalization.
  if(check->heap!=check->backing_heap)
    return check->heap->used==check->used && check->heap->allocations==check->allocations;
  return TRUE;
}
#endif
