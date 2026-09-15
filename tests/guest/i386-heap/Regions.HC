CI386PublicPool region_pool;
CI386PoolRegion extra_regions[2];
CHeapCtrl region_heap;
extern I64 PublicBackingTest();
I64 PublicRegionTest()
{
  CI386PublicPool *pool=&region_pool;
  CI386PoolRegion *first=&pool->initial,*second=&extra_regions[0],*third=&extra_regions[1];
  CMemBlk *a,*b;
  U8 *p,*hole=0x48000;
  I64 i,cycle;
  U64 before;
  U32 flags=GetRFlags;
  for(cycle=0;cycle<3;cycle++) {
    if(!I386MemPoolInit(pool,0x40000,32768) || pool->region_count!=1 ||
        first->base!=0x40000 || first->size!=32768 || first->type!=MRT_RAM || first->pool!=pool) return 301;
    for(i=0;i<32768;i++) hole[i]=0xA5;
    a=I386MemPageAlloc(pool,64);
    if(!a || first->used!=32768 || I386MemPageAlloc(pool,1) ||
        I386MemPoolRemove(pool,first)) return 302;
    before=Hash(pool,sizeof(CI386PublicPool));
    if(I386MemPoolAdd(pool,second,0x40000,32768) ||
        I386MemPoolAdd(pool,0x41000,0x50000,32768) ||
        I386MemPoolAdd(pool,second,0xFFFFFE00,1024) ||
        I386MemPoolAdd(pool,0xFFFFFFF0,0x50000,32768) ||
        I386MemPoolAdd(pool,second,0x50001,32768) ||
        Hash(pool,sizeof(CI386PublicPool))!=before || second->pool) return 303;
    if(!I386MemPoolAdd(pool,second,0x50000,32768) || pool->region_count!=2 ||
        pool->size!=65536 || pool->alloced_u8s!=65536 || pool->used_u8s!=32768 ||
        second->next!=first || first->last!=second || !I386MemPoolValid(pool)) return 304;
    b=I386MemPageAlloc(pool,64);
    if(b!=0x50000 || second->used!=32768 || pool->used_u8s!=65536 || I386MemPageAlloc(pool,1)) return 305;
    p=b(U8 *)+16; p[0]=71; p[32751]=93;
    if(I386MemPageFree(pool,0x48000) || I386MemPageFree(pool,0x58000)) return 306;
    for(i=0;i<32768;i++) if(hole[i]!=0xA5) return 307;
    //Adjacent physical bytes remain distinct ownership regions.
    if(!I386MemPoolAdd(pool,third,0x48000,32768)) return 308;
    a->pags=128;
    if(I386MemPageFree(pool,a) || first->used!=32768 || pool->used_u8s!=65536) return 309;
    a->pags=64;
    if(!I386MemPageFree(pool,a) || first->used ||
        !I386MemPoolRemove(pool,first) || first->pool ||
        !I386MemPoolRemove(pool,third) || third->pool ||
        pool->region_count!=1 || pool->regions!=second || second->next || second->last) return 310;
    //Overwrite returned arenas: no free list may retain pointers into them.
    for(i=0;i<65536;i++) (0x40000)(U8 *)[i]=0x5A;
    if(p[0]!=71 || p[32751]!=93 || !I386MemPageFree(pool,b) ||
        I386MemPageAlloc(pool,64)!=b || !I386MemPageFree(pool,b)) return 311;
    if(I386MemPoolEmpty(pool) || I386MemPoolInit(pool,0x40000,32768)) return 312;
    pool->locked_flags=1;
    if(I386MemPoolRemove(pool,second) || I386MemPoolAdd(pool,third,0x48000,32768)) return 313;
    pool->locked_flags=0;
    if(!I386MemPoolRemove(pool,second) || second->pool || pool->regions || pool->region_count ||
        pool->size || pool->alloced_u8s || pool->used_u8s || !I386MemPoolValid(pool) ||
        I386MemPoolRemove(pool,second) || I386MemPageAlloc(pool,1)) return 314;
  }
  //Detach a region represented simultaneously by raw fragments and both bin kinds.
  if(!I386MemPoolInit(pool,0x40000,0x40000)) return 315;
  a=I386MemPageAlloc(pool,256); b=I386MemPageAlloc(pool,64);
  if(!a || !b || !I386MemPageFree(pool,a) || !I386MemPageFree(pool,b) ||
      !pool->mem_free_lst || !pool->free_pag_hash[64] || !pool->free_pag_hash2[8] ||
      !I386MemPoolRemove(pool,first) || !I386MemPoolValid(pool)) return 316;
  for(i=0;i<MEM_FREE_PAG_HASH_SIZE;i++) if(pool->free_pag_hash[i]) return 317;
  for(i=0;i<64-MEM_PAG_BITS;i++) if(pool->free_pag_hash2[i]) return 318;
  if(pool->mem_free_lst || !I386MemPoolEmpty(pool) ||
      !I386MemPoolAdd(pool,second,0x40000,32768) ||
      !I386MemHeapInit(&region_heap,pool)) return 319;
  p=I386MemAlloc(&region_heap,32);
  if(!p || !I386MemFree(p) || region_heap.used_u8s || !region_heap.alloced_u8s ||
      I386MemPoolRemove(pool,second) || !I386MemHeapDestroy(&region_heap) ||
      !I386MemPoolRemove(pool,second) || !I386MemPoolValid(pool)) return 320;
  if((GetRFlags^flags)&0x200) return 321;
  return PublicBackingTest;
}

#include "Backing.HC"
