#include "/Kernel/I386/MemoryBacking.HH"
#include "/Kernel/I386/MemoryBackingConfig.HH"
#include "/Kernel/I386/Cpu.HH"
extern Bool I386MemBackingGrow(CI386PublicPool *pool,I64 pages);
//Single CPU; callers cannot re-enter validation while IRQs are masked.
#define I386_BACKING_BATCH 256
U32 i386_backing_region_scratch[I386_BACKING_BATCH];
Bool I386MemBackingDisjoint(CI386Heap *first,CI386Heap *second)
{
  U64 a=(first->base+0)(U64),b=(second->base+0)(U64);
  return first!=second && !(a<b+second->size && b<a+first->size) &&
    !(a<(second+0)(U64)+sizeof(CI386Heap) && (second+0)(U64)<a+first->size) &&
    !(b<(first+0)(U64)+sizeof(CI386Heap) && (first+0)(U64)<b+second->size);
}
CI386Heap *I386MemBackingRegionHeap(CI386BackingPool *pool,U64 address)
{//Validate the complete record range before following a link in either arena.
  CI386Heap *heap=pool->heap;
  U64 base=(heap->base+0)(U64);
  if(heap->size>=sizeof(CI386BackingRegion) &&
      address>=base+sizeof(CI386HeapBlock) &&
      address-base<=heap->size-sizeof(CI386BackingRegion))return heap;
  if(heap=pool->fallback) {
    base=(heap->base+0)(U64);
    if(heap->size>=sizeof(CI386BackingRegion) &&
        address>=base+sizeof(CI386HeapBlock) &&
        address-base<=heap->size-sizeof(CI386BackingRegion))return heap;
  }
  return 0;
}
Bool I386MemBackingFits(CI386Heap *heap,I64 request)
{//The caller validated the arena and holds IRQs masked across allocation.
  CI386HeapBlock *block;
  U32 offset=0,need;
  if(!heap || request<0 || request>0xFFFFFFFF-23)return FALSE;
  need=((request+7)&~7)+sizeof(CI386HeapBlock);
  while(offset<heap->size) {
    block=heap->base+offset;
    if(block->tag==I386_HEAP_FREE && block->span>=need)return TRUE;
    offset+=block->span;
  }
  return FALSE;
}
Bool I386MemBackingValid(CI386BackingPool *pool)
{
  CI386BackingRegion *region,*cursor;
  CI386HeapBlock *block;
  CI386Heap *heap,*previous;
  U32 flags=I386IrqSave,count=0,chunk,gap,i,j,offset,target;
  U32 *scratch=i386_backing_region_scratch,limit;
  I64 retained=0;
  U64 address,base;
  Bool result=FALSE;
  if(!pool || pool->backing_signature!=I386_BACKING_SIGNATURE ||
      pool->grow!=&I386MemBackingGrow || !I386MemPoolValid(pool) ||
      !(heap=pool->heap) || !I386HeapValid(heap) ||
      pool->fallback && (!I386HeapValid(pool->fallback) ||
        !I386MemBackingDisjoint(heap,pool->fallback) ||
        (pool->fallback->base+0)(U64)<(pool+0)(U64)+sizeof(CI386BackingPool) &&
        (pool+0)(U64)<(pool->fallback->base+0)(U64)+pool->fallback->size)) goto done;
  //Each bounded batch is sorted without changing the ownership list. Validate
  //links are within the mapped heap before reading the next link, then check
  //exact block membership while walking the already-validated chain.
  cursor=pool->owned;
  while(cursor) {
    chunk=0;
    while(cursor && chunk<I386_BACKING_BATCH) {
      if(count>=pool->owned_count) goto done;
      address=(cursor+0)(U64);
      if(!I386MemBackingRegionHeap(pool,address)) goto done;
      i386_backing_region_scratch[chunk]=address;chunk++;count++;
      cursor=cursor->next_owned;
    }
    //Sort in place with fewer shifts on reverse-ordered regions. The final gap
    //of one preserves exact ascending block matching.
#ifdef I386_HEAP_SOURCE_BUILD
    for(gap=chunk/2;gap;gap=gap/2)
      for(i=gap;i<chunk;i++) {
        target=i386_backing_region_scratch[i];j=i;
        while(j>=gap && i386_backing_region_scratch[j-gap]>target) {
          i386_backing_region_scratch[j]=i386_backing_region_scratch[j-gap];j-=gap;
        }
        i386_backing_region_scratch[j]=target;
      }
#else
    //The bootstrap compiler expands each indexed U32 operation to wide stack
    //arithmetic; retain the same gap sort using bounded byte offsets here.
    limit=chunk*4;
    asm {
      MOV EDI,U32 &scratch[EBP]
      MOV EBX,U32 &chunk[EBP]
      SHR EBX,1
      SHL EBX,2
@@10:
      TEST EBX,EBX
      JZ I32 @@90
      MOV ECX,EBX
@@20:
      CMP ECX,U32 &limit[EBP]
      JAE @@80
      LEA EAX,U32 [EDI+ECX]
      MOV EDX,U32 [EAX]
@@30:
      MOV ESI,EAX
      SUB ESI,EDI
      CMP ESI,EBX
      JB @@40
      MOV ESI,EAX
      SUB ESI,EBX
      CMP U32 [ESI],EDX
      JBE @@40
      PUSH EAX
      MOV EAX,U32 [ESI]
      MOV U32 [ESI+EBX],EAX
      POP EAX
      MOV EAX,ESI
      JMP @@30
@@40:
      MOV U32 [EAX],EDX
      ADD ECX,4
      JMP @@20
@@80:
      SHR EBX,1
      AND EBX,-4
      JNZ I32 @@10
@@90:
    }
#endif
    offset=0;previous=0;
    for(i=0;i<chunk;i++) {
      heap=I386MemBackingRegionHeap(pool,i386_backing_region_scratch[i]);
      if(!heap)goto done;
      if(heap!=previous) {offset=0;previous=heap;}
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
  }
  result=count==pool->owned_count && retained==pool->retained;
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
  pool->heap=heap; pool->fallback=0; pool->owned=0; pool->owned_count=0; pool->retained=0;
  pool->quantum=quantum; pool->backing_signature=I386_BACKING_SIGNATURE;
  pool->grow=&I386MemBackingGrow; result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
Bool I386MemBackingSetFallback(CI386BackingPool *pool,CI386Heap *fallback)
{//Only configure an empty provider; existing ownership must never change source.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  U64 base;
  if(!I386MemBackingValid(pool) || pool->owned || pool->regions ||
      pool->locked_flags || pool->growing || pool->fallback || !fallback ||
      !I386HeapValid(fallback) || !I386MemBackingDisjoint(pool->heap,fallback))goto done;
  base=(fallback->base+0)(U64);
  if(base<(pool+0)(U64)+sizeof(CI386BackingPool) &&
      (pool+0)(U64)<base+fallback->size)goto done;
  pool->fallback=fallback;result=TRUE;
done:
  I386IrqRestore(flags);return result;
}
Bool I386MemBackingGrow(CI386PublicPool *base_pool,I64 pages)
{//Called once per exhausted page request, IRQs masked, pool unlocked.
  CI386BackingPool *pool=base_pool;
  CI386BackingRegion *region;
  CI386Heap *source;
  I64 minimum,size,request,i,before;
  U64 arena;
  if(!I386MemBackingValid(pool) || !pool->growing || pool->locked_flags ||
      pages<1 || pages>(0xFFFFFFFF-sizeof(CI386BackingRegion)-511)/512 ||
      pool->owned_count==0xFFFFFFFF) return FALSE;
  minimum=pages*512; size=minimum;
  if(size<pool->quantum) size=pool->quantum;
  request=size+sizeof(CI386BackingRegion)+511;
  //Use validated low memory first, preserving the main arena for the
  //bootstrap compiler and other consumers that cannot use the fallback.
  source=pool->fallback;
  if(!I386MemBackingFits(source,request))source=pool->heap;
  if(!I386MemBackingFits(source,request) && size!=minimum) {
    size=minimum;request=size+sizeof(CI386BackingRegion)+511;
    source=pool->fallback;
    if(!I386MemBackingFits(source,request))source=pool->heap;
  }
  if(!I386MemBackingFits(source,request))return FALSE;
  before=source->used;
  //Keep the initial reserve and large regions first-fit. Later native-sized
  //batches use the high end, leaving room for large contiguous consumers.
  if(pool->owned_count && size==I386_NATIVE_BACKING_QUANTUM)region=I386HeapAllocHigh(source,request);
  else region=I386HeapAlloc(source,request);
  if(!region) return FALSE;
  for(i=0;i<sizeof(CI386BackingRegion);i++) region(U8 *)[i]=0;
  arena=((region+0)(U64)+sizeof(CI386BackingRegion)+511)&~511;
  //The page extent is aligned now; return unused worst-case tail padding.
  //Shrink before publishing the region, keeping rollback wholly arena-owned.
  request=arena+size-(region+0)(U64);
  if(!I386HeapShrink(source,region,request)) {
    I386HeapFree(source,region); return FALSE;
  }
  if(!I386MemPoolAdd(pool,region,arena,size)) {
    I386HeapFree(source,region); return FALSE;
  }
  region->request=request; region->span=source->used-before;
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
  CI386Heap *source;
  I64 released=0,span;
  if(!I386MemBackingValid(pool) || pool->locked_flags || pool->growing) {
    I386IrqRestore(flags); return -1;
  }
  link=&pool->owned;
  while(region=*link) {
    if(region->used || region->reserve_hold) link=&region->next_owned;
    else {
      next=region->next_owned; span=region->span;
      source=I386MemBackingRegionHeap(pool,(region+0)(U64));
      if(!source || region->pool && !I386MemPoolRemove(pool,region) || !I386HeapFree(source,region)) {
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
  pool->signature=0; pool->backing_signature=0; pool->heap=0; pool->fallback=0; pool->quantum=0;
  result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
