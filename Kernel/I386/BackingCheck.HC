#ifndef I386_BACKING_CHECK_IMPLEMENTED
#define I386_BACKING_CHECK_IMPLEMENTED
#include "/Kernel/I386/MemoryBacking.HH"
Bool I386BackingCheckValid(CI386BackingPool *pool,CI386Heap *heap)
{//Count only verified backing allocations when separating cache from payloads.
  CI386BackingRegion *region;
  CI386HeapBlock *block;
  CI386Heap *source,*fallback;
  I64 count=0,retained=0;
  U64 address,base,first,second;
  if(!pool || pool->heap!=heap || pool->signature!=I386_POOL_SIGNATURE ||
      pool->backing_signature!=I386_BACKING_SIGNATURE || pool->locked_flags || pool->growing ||
      !I386HeapValid(heap)) return FALSE;
  fallback=pool->fallback;
  if(fallback) {
    if(!I386HeapValid(fallback) || fallback==heap)return FALSE;
    first=(heap->base+0)(U64);second=(fallback->base+0)(U64);
    if(first<second+fallback->size && second<first+heap->size ||
        second<(pool+0)(U64)+sizeof(CI386BackingPool) &&
        (pool+0)(U64)<second+fallback->size)return FALSE;
  }
  for(region=pool->owned;region;region=region->next_owned) {
    address=(region+0)(U64);base=(heap->base+0)(U64);source=heap;
    if(heap->size<sizeof(CI386BackingRegion) ||
        address<base+sizeof(CI386HeapBlock) ||
        address-base>heap->size-sizeof(CI386BackingRegion)) {
      if(!fallback)return FALSE;
      source=fallback;base=(fallback->base+0)(U64);
      if(fallback->size<sizeof(CI386BackingRegion) ||
          address<base+sizeof(CI386HeapBlock) ||
          address-base>fallback->size-sizeof(CI386BackingRegion))return FALSE;
    }
    if(count++>=pool->owned_count || I386HeapSize(source,region)!=region->request ||
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
  CI386Heap *heap,*backing_heap,*fallback;
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
  check->heap=heap; check->backing_heap=pool->heap;check->fallback=pool->fallback;
  check->control=control; check->pool=pool;
  check->used=heap->used; check->allocations=heap->allocations;
  check->public_used=control->used_u8s;
  check->retained=pool->retained; check->count=pool->owned_count;
  check->backing_used=pool->heap->used; check->backing_allocations=pool->heap->allocations;
  if(pool->fallback) {
    check->backing_used+=pool->fallback->used;
    check->backing_allocations+=pool->fallback->allocations;
  }
  return TRUE;
}
Bool I386BackingCheckRestored(CI386BackingCheck *check)
{
  I64 used,allocations;
  if(!check || check->control->bp!=check->pool ||
      check->control->hc_signature!=HEAP_CTRL_SIGNATURE_VAL ||
      check->control->used_u8s!=check->public_used ||
      check->pool->heap!=check->backing_heap || check->pool->fallback!=check->fallback ||
      !I386HeapValid(check->heap) ||
      !I386BackingCheckValid(check->pool,check->backing_heap)) return FALSE;
  used=check->backing_heap->used;allocations=check->backing_heap->allocations;
  if(check->fallback) {used+=check->fallback->used;allocations+=check->fallback->allocations;}
  if(used-check->pool->retained!=check->backing_used-check->retained ||
      allocations-check->pool->owned_count!=check->backing_allocations-check->count)
    return FALSE;
  //A private compiler arena is separate from the public backing allocator.
  //Its complete bytes and allocation count must recover without normalization.
  if(check->heap!=check->backing_heap && check->heap!=check->fallback)
    return check->heap->used==check->used && check->heap->allocations==check->allocations;
  return TRUE;
}
#endif
