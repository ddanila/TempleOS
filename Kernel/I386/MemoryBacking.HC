#include "/Kernel/I386/MemoryBacking.HH"
#include "/Kernel/I386/Cpu.HH"
extern Bool I386MemBackingGrow(CI386PublicPool *pool,I64 pages);
Bool I386MemBackingValid(CI386BackingPool *pool)
{
  CI386BackingRegion *region;
  U32 count=0;
  I64 retained=0;
  U64 address,base;
  if(!pool || pool->backing_signature!=I386_BACKING_SIGNATURE ||
      pool->grow!=&I386MemBackingGrow || !I386MemPoolValid(pool) ||
      !pool->heap || !I386HeapValid(pool->heap)) return FALSE;
  for(region=pool->owned;region;region=region->next_owned) {
    if(count++>=pool->owned_count || region->pool && region->pool!=pool ||
        I386HeapSize(pool->heap,region)!=region->request ||
        region->request<sizeof(CI386BackingRegion)+511+512 ||
        (region->span+0)(U64)<(region->request+0)(U64)+sizeof(CI386HeapBlock)) return FALSE;
    address=(region+0)(U64); base=(region->base+0)(U64);
    if(base<address+sizeof(CI386BackingRegion) || base+region->size>address+region->request) return FALSE;
    retained+=region->span;
  }
  return count==pool->owned_count && retained==pool->retained;
}
Bool I386MemBackingInit(CI386BackingPool *pool,CI386Heap *heap,I64 quantum=65536)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(!pool || (pool+0)(U64)+sizeof(CI386BackingPool)>0x100000000 ||
      pool->backing_signature==I386_BACKING_SIGNATURE || !I386HeapValid(heap) ||
      quantum<512 || quantum&511 || quantum>0xFFFFFFFF-sizeof(CI386BackingRegion)-511 ||
      pool->signature==I386_POOL_SIGNATURE && (pool->regions || pool->region_count) ||
      !I386MemPoolEmpty(pool)) goto done;
  pool->heap=heap; pool->owned=0; pool->owned_count=0; pool->retained=0;
  pool->quantum=quantum; pool->backing_signature=I386_BACKING_SIGNATURE;
  pool->grow=&I386MemBackingGrow; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
Bool I386MemBackingGrow(CI386PublicPool *base_pool,I64 pages)
{//Called once per exhausted page request, IRQs masked, pool unlocked.
  CI386BackingPool *pool=base_pool;
  CI386BackingRegion *region;
  I64 minimum,size,request,i,before;
  U64 arena;
  if(!I386MemBackingValid(pool) || !pool->growing || pool->locked_flags ||
      pages<1 || pages>(0xFFFFFFFF-sizeof(CI386BackingRegion)-511)/512 ||
      pool->owned_count==0xFFFFFFFF) return FALSE;
  minimum=pages*512; size=minimum;
  if(size<pool->quantum) size=pool->quantum;
  request=size+sizeof(CI386BackingRegion)+511;
  before=pool->heap->used;
  region=I386HeapAlloc(pool->heap,request);
  if(!region && size!=minimum) {
    size=minimum; request=size+sizeof(CI386BackingRegion)+511;
    region=I386HeapAlloc(pool->heap,request);
  }
  if(!region) return FALSE;
  for(i=0;i<sizeof(CI386BackingRegion);i++) region(U8 *)[i]=0;
  arena=((region+0)(U64)+sizeof(CI386BackingRegion)+511)&~511;
  if(!I386MemPoolAdd(pool,region,arena,size)) {
    I386HeapFree(pool->heap,region); return FALSE;
  }
  region->request=request; region->span=pool->heap->used-before;
  region->next_owned=pool->owned; pool->owned=region;
  pool->owned_count++; pool->retained+=region->span;
  return TRUE;
}
I64 I386MemBackingTrim(CI386BackingPool *pool)
{//Never call from PageFree: its caller may still need the returned block header.
  U32 flags=I386IrqSave;
  CI386BackingRegion *region,*next,**link;
  I64 released=0,span;
  if(!I386MemBackingValid(pool) || pool->locked_flags || pool->growing) {
    I386IrqRestore(flags); return -1;
  }
  link=&pool->owned;
  while(region=*link) {
    if(region->used) link=&region->next_owned;
    else {
      next=region->next_owned; span=region->span;
      if(region->pool && !I386MemPoolRemove(pool,region) || !I386HeapFree(pool->heap,region)) {
        I386IrqRestore(flags); return -1;
      }
      *link=next; pool->owned_count--; pool->retained-=span; released+=span;
    }
  }
  I386IrqRestore(flags); return released;
}
Bool I386MemBackingDestroy(CI386BackingPool *pool)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(I386MemBackingTrim(pool)<0 || pool->owned || pool->regions || pool->used_u8s) goto done;
  pool->grow=0;
  if(!I386MemPoolEmpty(pool)) goto done;
  pool->signature=0; pool->backing_signature=0; pool->heap=0; pool->quantum=0;
  result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
