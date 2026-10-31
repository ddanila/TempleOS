#include "/Kernel/I386/MemoryBacking.HC"
CI386BackingPool backing_pool;
CI386Heap backing_heap;
CHeapCtrl backing_heaps[2];
extern I64 BackingPlaneBudgetTest();
//The previous complete-scan implementation remains an independent oracle.
Bool BackingValidationOracle(CI386BackingPool *pool)
{
  CI386BackingRegion *region;
  U32 count=0;I64 retained=0;U64 address,base;
  if(!pool || pool->backing_signature!=I386_BACKING_SIGNATURE ||
      pool->grow!=&I386MemBackingGrow || !I386MemPoolValid(pool) ||
      !pool->heap || !I386HeapValid(pool->heap)) return FALSE;
  for(region=pool->owned;region;region=region->next_owned) {
    if(count++>=pool->owned_count || region->pool && region->pool!=pool ||
        I386HeapSize(pool->heap,region)!=region->request ||
        region->reserve_hold>1 || region->request<sizeof(CI386BackingRegion)+512 ||
        (region->span+0)(U64)<(region->request+0)(U64)+sizeof(CI386HeapBlock)) return FALSE;
    address=(region+0)(U64);base=(region->base+0)(U64);
    if(base<address+sizeof(CI386BackingRegion) || base+region->size>address+region->request) return FALSE;
    retained+=region->span;
  }
  return count==pool->owned_count && retained==pool->retained;
}
I64 BackingValidationParity(CI386BackingPool *pool,U8 *private_bytes)
{
  CI386BackingRegion *region=pool->owned,*saved,*fake;
  CI386HeapBlock *block=private_bytes-sizeof(CI386HeapBlock);
  U32 flags=GetRFlags,request=region->request,hold=region->reserve_hold;
  U32 reserved=block->reserved,count=pool->owned_count;
  I64 retained=pool->retained,i;
  if(!BackingValidationOracle(pool) || !I386MemBackingValid(pool)) return 480;
  region->request++;if(BackingValidationOracle(pool) || I386MemBackingValid(pool))return 481;region->request=request;
  region->reserve_hold=2;if(BackingValidationOracle(pool) || I386MemBackingValid(pool))return 482;region->reserve_hold=hold;
  pool->owned_count++;if(BackingValidationOracle(pool) || I386MemBackingValid(pool))return 483;pool->owned_count=count;
  pool->retained++;if(BackingValidationOracle(pool) || I386MemBackingValid(pool))return 484;pool->retained=retained;
  block->reserved=1;if(BackingValidationOracle(pool) || I386MemBackingValid(pool))return 485;block->reserved=reserved;
  //A plausible record inside a different live allocation is not a heap block.
  fake=private_bytes+128;for(i=0;i<sizeof(CI386BackingRegion);i++) fake(U8 *)[i]=0;
  saved=pool->owned;pool->owned=fake;
  if(BackingValidationOracle(pool) || I386MemBackingValid(pool))return 486;
  pool->owned=saved;
  if(!BackingValidationOracle(pool) || !I386MemBackingValid(pool) || (GetRFlags^flags)&0x200) return 487;
  return 0;
}
I64 PublicBackingTest()
{
  CI386BackingPool *pool=&backing_pool;
  CHeapCtrl *first=&backing_heaps[0],*second=&backing_heaps[1];
  U8 *a,*b,*c,*private_bytes,*reuse;
  I64 cycle,i,before,retained,root_span,other_span,small_span;
  U32 flags=GetRFlags;
  for(cycle=0;cycle<3;cycle++) {
    if(!I386HeapInit(&backing_heap,0x40000,0x40000) ||
        I386MemBackingInit(pool,&backing_heap,513) ||
        !I386MemBackingInit(pool,&backing_heap) ||
        I386MemBackingInit(pool,&backing_heap) ||
        I386MemPoolEmpty(pool) || pool->size || pool->retained || backing_heap.used ||
        !I386MemHeapInit(first,pool) || !I386MemHeapInit(second,pool)) return 401;
    a=I386MemAlloc(first,32768);
    if(!a || pool->owned_count!=1 || pool->size!=65536 ||
        pool->retained!=backing_heap.used || pool->retained<=pool->alloced_u8s) return 402;
    root_span=pool->retained;
    b=I386MemAlloc(second,40000);
    if(!b || pool->owned_count!=2 || pool->size!=131072 ||
        pool->retained!=backing_heap.used || I386MemBackingTrim(pool)) return 403;
    other_span=pool->retained-root_span;
    for(i=0;i<32768;i++) a[i]=i+17;
    for(i=0;i<40000;i++) b[i]=i+31;
    private_bytes=I386HeapAlloc(&backing_heap,65536);
    if(!private_bytes) return 404;
    private_bytes[0]=0xA7; private_bytes[65535]=0x5A;
    //The normal growth quantum cannot fit: retry with the requested page span.
    c=I386MemAlloc(first,40000);
    if(!c || pool->owned_count!=3 || pool->owned->size>=pool->quantum ||
        pool->owned->size<40000 || !I386MemBackingValid(pool)) return 405;
    if(i=BackingValidationParity(pool,private_bytes))return i;
    small_span=pool->retained-root_span-other_span;
    c[0]=0x39; c[39999]=0x93;
    before=backing_heap.used; retained=pool->retained;
    if(I386MemAlloc(first,40000) || I386MemAlloc(first,-1) ||
        I386MemAlloc(first,0x100000000) || backing_heap.used!=before ||
        pool->retained!=retained || pool->owned_count!=3 || pool->growing ||
        pool->locked_flags || I386MemBackingDestroy(pool)) return 406;
    if(!I386MemFree(a) || I386MemBackingTrim(pool)!=root_span ||
        pool->owned_count!=2 || backing_heap.used!=before-root_span) return 407;
    //The bootstrap allocator can immediately use memory returned by the public pool.
    reuse=I386HeapAlloc(&backing_heap,66000);
    if(!reuse) return 408;
    for(i=0;i<66000;i++) reuse[i]=0xC3;
    for(i=0;i<40000;i++) if(b[i]!=(i+31)(U8)) return 409;
    if(c[0]!=0x39 || c[39999]!=0x93 || private_bytes[0]!=0xA7 ||
        private_bytes[65535]!=0x5A || !I386HeapFree(&backing_heap,reuse)) return 410;
    if(!I386MemFree(b) || I386MemBackingTrim(pool)!=other_span ||
        !I386MemHeapDestroy(first) || I386MemBackingTrim(pool)!=small_span ||
        pool->retained || pool->owned_count || pool->regions || pool->size ||
        !I386MemHeapDestroy(second)) return 411;
    //Neither hole fits the 258-page bucket, but the actual 256 pages fit.
    //Pressure fallback must preserve the private bytes and reclaim every span.
    before=backing_heap.used;
    if(!I386MemHeapInit(first,pool) || !(a=I386MemAlloc(first,131000)) ||
        pool->owned_count!=1 || pool->owned->size!=256*512 ||
        I386MemSize(a)<131000 || !I386MemBackingValid(pool)) return 414;
    a[0]=0x39; a[130999]=0x93;
    if(a[0]!=0x39 || a[130999]!=0x93 || private_bytes[0]!=0xA7 ||
        private_bytes[65535]!=0x5A || !I386MemFree(a) ||
        I386MemBackingTrim(pool)<=0 || pool->retained || pool->owned_count ||
        backing_heap.used!=before || !I386HeapValid(&backing_heap) ||
        !I386HeapFree(&backing_heap,private_bytes) || backing_heap.used) return 415;
    //An empty provider grows again, rounding a large request only once on retry.
    if(!(a=I386MemAlloc(first,131000)) ||
        pool->owned->size!=258*512 || !I386MemFree(a) || I386MemBackingTrim(pool)<=0 ||
        !(a=I386MemAlloc(first,32)) ||
        !I386MemFree(a) || I386MemBackingTrim(pool) ||
        !I386MemHeapDestroy(first) || I386MemBackingTrim(pool)<=0 ||
        !I386MemBackingDestroy(pool) || pool->signature || pool->grow ||
        pool->backing_signature || pool->heap || backing_heap.used ||
        backing_heap.allocations || !I386HeapValid(&backing_heap)) return 412;
  }
  if((GetRFlags^flags)&0x200) return 413;
  return BackingPlaneBudgetTest;
}

#include "BackingPlaneBudget.HC"
