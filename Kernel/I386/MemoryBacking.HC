#include "/Kernel/I386/MemoryBacking.HH"
#include "/Kernel/I386/Cpu.HH"
extern Bool I386MemBackingGrow(CI386PublicPool *pool,I64 pages);
I64 I386MemBackingValidatedSize(CI386Heap *heap,U8 *ptr)
{//Caller holds IRQs masked and has validated the complete heap chain.
  U32 address=(ptr+0)(U32),base=(heap->base+0)(U32),target,offset=0;
  CI386HeapBlock *block;
  if(address<base || address-base<sizeof(CI386HeapBlock) || address-base>=heap->size) return -1;
  target=address-base-sizeof(CI386HeapBlock);
#ifdef I386_HEAP_SOURCE_BUILD
  while(offset<target) {
    block=heap->base+offset;
    offset+=block->span;
  }
#else
  //The complete chain was validated above; walk its U32 spans without
  //repeating the expensive invariant checks for every owned region.
  asm {
    MOV ESI,U32 &heap[EBP]
    MOV ESI,U32 CI386Heap.base[ESI]
    MOV EDX,U32 &target[EBP]
    XOR EAX,EAX
@@10:
    CMP EAX,EDX
    JAE @@20
    MOV ECX,U32 CI386HeapBlock.span[ESI]
    ADD EAX,ECX
    ADD ESI,ECX
    JMP @@10
@@20:
    MOV U32 &offset[EBP],EAX
  }
#endif
  if(offset!=target) return -1;
  block=heap->base+offset;
  if(block->tag!=I386_HEAP_USED) return -1;
  return block->requested;
}
//Single CPU; callers cannot re-enter validation while IRQs are masked.
U32 i386_backing_region_scratch[64];
Bool I386MemBackingValid(CI386BackingPool *pool)
{
  CI386BackingRegion *region;
  CI386HeapBlock *block;
  CI386Heap *heap;
  U32 flags=I386IrqSave,count=0,i,j,offset=0,target;
  I64 retained=0;
  U64 address,base,heap_base;
  Bool result=FALSE;
  if(!pool || pool->backing_signature!=I386_BACKING_SIGNATURE ||
      pool->grow!=&I386MemBackingGrow || !I386MemPoolValid(pool) ||
      !(heap=pool->heap) || !I386HeapValid(heap)) goto done;
  if(pool->owned_count>64) {
    //No fixed limit on ownership: retain the existing bounded-memory path.
    for(region=pool->owned;region;region=region->next_owned) {
      if(count++>=pool->owned_count || region->pool && region->pool!=pool ||
          I386MemBackingValidatedSize(heap,region)!=region->request ||
          region->reserve_hold>1 || region->request<sizeof(CI386BackingRegion)+512 ||
          (region->span+0)(U64)<(region->request+0)(U64)+sizeof(CI386HeapBlock)) goto done;
      address=(region+0)(U64);base=(region->base+0)(U64);
      if(base<address+sizeof(CI386BackingRegion) || base+region->size>address+region->request) goto done;
      retained+=region->span;
    }
    result=count==pool->owned_count && retained==pool->retained;
    goto done;
  }
  //Bounds-check each link before reading it, then sort addresses without
  //mutating the ownership list. Exact block membership is checked below.
  heap_base=(heap->base+0)(U64);
  for(region=pool->owned;region;region=region->next_owned) {
    if(count>=pool->owned_count || heap->size<sizeof(CI386BackingRegion)) goto done;
    address=(region+0)(U64);
    if(address<heap_base+sizeof(CI386HeapBlock) ||
        address-heap_base>heap->size-sizeof(CI386BackingRegion)) goto done;
    target=address;
    j=count;
    while(j && i386_backing_region_scratch[j-1]>target) { i386_backing_region_scratch[j]=i386_backing_region_scratch[j-1];j--; }
    i386_backing_region_scratch[j]=target;count++;
  }
  if(count!=pool->owned_count) goto done;
  for(i=0;i<count;i++) {
    target=i386_backing_region_scratch[i]-(heap->base+0)(U32)-sizeof(CI386HeapBlock);
#ifdef I386_HEAP_SOURCE_BUILD
    while(offset<target) { block=heap->base+offset;offset+=block->span; }
#else
    asm {
      MOV ESI,U32 &heap[EBP]
      MOV ESI,U32 CI386Heap.base[ESI]
      MOV EAX,U32 &offset[EBP]
      ADD ESI,EAX
      MOV EDX,U32 &target[EBP]
@@10:
      CMP EAX,EDX
      JAE @@20
      MOV ECX,U32 CI386HeapBlock.span[ESI]
      ADD EAX,ECX
      ADD ESI,ECX
      JMP @@10
@@20:
      MOV U32 &offset[EBP],EAX
    }
#endif
    if(offset!=target) goto done;
    block=heap->base+offset;region=i386_backing_region_scratch[i];
    if(block->tag!=I386_HEAP_USED || block->requested!=region->request ||
        region->pool && region->pool!=pool || region->reserve_hold>1 ||
        region->request<sizeof(CI386BackingRegion)+512 ||
        (region->span+0)(U64)<(region->request+0)(U64)+sizeof(CI386HeapBlock)) goto done;
    address=(region+0)(U64);base=(region->base+0)(U64);
    if(base<address+sizeof(CI386BackingRegion) || base+region->size>address+region->request) goto done;
    retained+=region->span;offset+=block->span;
  }
  result=retained==pool->retained;
done:
  I386IrqRestore(flags);return result;
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
  //The page extent is aligned now; return unused worst-case tail padding.
  //Shrink before publishing the region, keeping rollback wholly arena-owned.
  request=arena+size-(region+0)(U64);
  if(!I386HeapShrink(pool->heap,region,request)) {
    I386HeapFree(pool->heap,region); return FALSE;
  }
  if(!I386MemPoolAdd(pool,region,arena,size)) {
    I386HeapFree(pool->heap,region); return FALSE;
  }
  region->request=request; region->span=pool->heap->used-before;
  region->next_owned=pool->owned; pool->owned=region;
  pool->owned_count++; pool->retained+=region->span;
  return TRUE;
}
Bool I386MemBackingReserve(CI386BackingPool *pool,I64 pages)
{//Explicit early reservation, with the same ownership and IRQ rules as lazy growth.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(!I386MemBackingValid(pool) || pool->locked_flags || pool->growing ||
      pages<1 || pages>(0xFFFFFFFF-sizeof(CI386BackingRegion)-511)/512)goto done;
  pool->growing=1;
  result=I386MemBackingGrow(pool,pages);
  if(result)pool->owned->reserve_hold=1;
  pool->growing=0;
done:
  I386IrqRestore(flags);return result;
}
Bool I386MemBackingReleaseReserve(CI386BackingPool *pool)
{//Release retention only; existing allocations and page lists remain unchanged.
  U32 flags=I386IrqSave;
  CI386BackingRegion *region;
  Bool result=FALSE;
  if(!I386MemBackingValid(pool) || pool->locked_flags || pool->growing)goto done;
  for(region=pool->owned;region;region=region->next_owned)region->reserve_hold=0;
  result=TRUE;
done:
  I386IrqRestore(flags);return result;
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
    if(region->used || region->reserve_hold) link=&region->next_owned;
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
  //The owner must detach its reclamation callback before provider shutdown.
  if(!pool || pool->reclaim || !I386MemBackingValid(pool) || pool->used_u8s ||
      !I386MemBackingReleaseReserve(pool) || I386MemBackingTrim(pool)<0 || pool->owned || pool->regions) goto done;
  pool->grow=0;
  if(!I386MemPoolEmpty(pool)) goto done;
  pool->signature=0; pool->backing_signature=0; pool->heap=0; pool->quantum=0;
  result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
