#include "/Kernel/I386/MemoryBacking.HC"
CI386BackingPool backing_pool;
CI386Heap backing_heap;
CHeapCtrl backing_heaps[2];
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
    //Free bytes are split around the private allocation; neither hole fits 258 pages.
    if(!I386MemHeapInit(first,pool) || I386MemAlloc(first,131000) || pool->retained ||
        !I386HeapFree(&backing_heap,private_bytes) || backing_heap.used) return 414;
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
  return 0;
}
