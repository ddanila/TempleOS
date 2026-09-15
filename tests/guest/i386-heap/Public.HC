#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Memory.HC"
#include "MemoryLayout.HC"
CI386PublicPool public_pool;
CHeapCtrl public_heaps[2];
I64 requests[12]={0,1,4,5,100,1004,1005,1011,1024,4096,65536,131000};
I64 PublicHeapTest()
{
  CI386PublicPool *pool=&public_pool;
  CHeapCtrl *hc=&public_heaps[0],*other=&public_heaps[1];
  CMemBlk *a,*b,*block;
  CMemUsed *used;
  U8 *p,*q,*slots[64],*guard=0x3FFF8;
  I64 i,j,round,index,sizes[64],total,old,old_pool;
  U32 flags=GetRFlags,seed=0x12345678;
  if(!MemoryLayoutCheck) return 131;
  if(I386MemPoolInit(pool,0x40001,0x40000) ||
      I386MemPoolInit(pool,0x40000,511) ||
      I386MemPoolInit(pool,0x40000,0x40001) ||
      I386MemPoolInit(pool,0xFFFFFE00,1024) ||
      I386MemPoolInit(0x40000,0x40000,0x40000)) return 101;
  for(i=0;i<8;i++) { guard[i]=0xA5; guard[0x40008+i]=0xA5; }
  if(!I386MemPoolInit(pool,0x40000,0x40000) || pool->used_u8s ||
      pool->alloced_u8s!=0x40000 || I386MemPageAlloc(pool,0) ||
      I386MemPageAlloc(pool,-1) || I386MemPageAlloc(pool,513)) return 102;
  a=I386MemPageAlloc(pool,256);
  if(!a || a->pags!=258 || a->mb_signature!=MBS_USED_SIGNATURE_VAL ||
      pool->used_u8s!=258*512 || I386MemPoolInit(pool,0x40000,0x40000)) return 103;
  b=I386MemPageAlloc(pool,254);
  if(!b || b->pags!=254 || pool->used_u8s!=0x40000 || I386MemPageAlloc(pool,1)) return 104;
  if(!I386MemPageFree(pool,a) || I386MemPageFree(pool,a) || pool->used_u8s!=254*512) return 105;
  block=I386MemPageAlloc(pool,1);
  if(block!=a || block->pags!=258 || pool->used_u8s!=0x40000 ||
      !I386MemPageFree(pool,block) || !I386MemPageFree(pool,b) || pool->used_u8s) return 106;
  //The small exact-size bin must return the same block.
  if(I386MemPageAlloc(pool,254)!=b || !I386MemPageFree(pool,b)) return 107;
  if(!I386MemPoolInit(pool,0x40000,0x40000) ||
      !I386MemHeapInit(hc,pool,0x1234) || !I386MemHeapInit(other,pool,0x5678) ||
      hc->mem_task!=0x1234 || other->mem_task!=0x5678 ||
      hc->next_mem_blk!=&hc->next_mem_blk || hc->last_mem_blk!=hc->next_mem_blk) return 108;
  if(I386MemAlloc(hc,-1) || I386MemAlloc(hc,0x100000000) ||
      I386MemAlloc(0,1) || I386MemSize(0) || !I386MemFree(0)) return 109;
  for(i=0;i<12;i++) {
    p=I386MemAlloc(hc,requests[i]);
    if(!p || (p+0)(U64)&7 || I386MemSize(p)<requests[i]) return 110;
    used=p-offset(CMemUsed.start);
    if(used->hc!=hc || used->size!=I386MemSize(p)+offset(CMemUsed.start) ||
        hc->used_u8s!=used->size || pool->used_u8s!=hc->alloced_u8s) return 111;
    for(j=0;j<requests[i];j++) p[j]=i+17;
    old=hc->used_u8s; old_pool=pool->used_u8s;
    hc->locked_flags=1;
    if(I386MemAlloc(hc,1) || I386MemFree(p) || I386MemHeapDestroy(hc) ||
        hc->used_u8s!=old || pool->used_u8s!=old_pool) return 112;
    hc->locked_flags=0;
    for(j=0;j<requests[i];j++) if(p[j]!=i+17) return 113;
    if(!I386MemFree(p) || hc->used_u8s) return 114;
    if(requests[i]<=1004) {
      q=I386MemAlloc(hc,requests[i]);
      if(q!=p || !I386MemFree(q)) return 115;
    }
  }
  p=I386MemAlloc(hc,32); q=I386MemAlloc(other,32);
  if(!p || !q || hc->used_u8s!=other->used_u8s) return 116;
  old=hc->used_u8s;
  if(!I386MemFree(q) || other->used_u8s || hc->used_u8s!=old ||
      !I386MemFree(p)) return 117;
  if(!I386MemHeapDestroy(hc) || !I386MemHeapDestroy(other) || pool->used_u8s ||
      !I386MemPoolInit(pool,0x40000,0x40000) || !I386MemHeapInit(hc,pool) ||
      !I386MemHeapInit(other,pool)) return 130;
  for(i=0;i<64;i++) slots[i]=0;
  for(round=0;round<1024;round++) {
    seed=seed*1664525+1013904223; index=(seed>>16)&63;
    if(p=slots[index]) {
      for(j=0;j<sizes[index];j++) if(p[j]!=(index+31)(U8)) return 118;
      if(!I386MemFree(p)) return 119;
      slots[index]=0;
    } else {
      sizes[index]=((seed>>8)&2047)+1;
      p=I386MemAlloc(hc,sizes[index]);
      if(!p || (p+0)(U64)&7 || I386MemSize(p)<sizes[index]) return 120;
      slots[index]=p;
      for(j=0;j<sizes[index];j++) p[j]=index+31;
    }
    total=0;
    for(i=0;i<64;i++) if(slots[i]) total+=I386MemSize(slots[i])+offset(CMemUsed.start);
    if(total!=hc->used_u8s || pool->used_u8s!=hc->alloced_u8s+other->alloced_u8s) return 121;
  }
  for(i=0;i<64;i++) if(slots[i] && !I386MemFree(slots[i])) return 122;
  if(hc->used_u8s || !I386MemHeapDestroy(hc) || !I386MemHeapDestroy(other) ||
      pool->used_u8s || hc->alloced_u8s || other->alloced_u8s) return 123;
  //Repeated lifetime cycles reclaim live allocations as well as free bins.
  for(round=0;round<3;round++) {
    if(!I386MemPoolInit(pool,0x40000,0x40000) || !I386MemHeapInit(hc,pool)) return 124;
    for(i=0;i<64;i++) if(!I386MemAlloc(hc,round*8+i)) return 125;
    for(i=0;i<64;i++) { p=I386MemAlloc(hc,4096); if(!p) break; }
    if(i==64 || !i || I386MemAlloc(hc,131000)) return 126;
    if(!I386MemHeapDestroy(hc) || pool->used_u8s || hc->alloced_u8s ||
        I386MemAlloc(hc,1) || I386MemHeapDestroy(hc)) return 127;
  }
  for(i=0;i<8;i++) if(guard[i]!=0xA5 || guard[0x40008+i]!=0xA5) return 128;
  if((GetRFlags^flags)&0x200) return 129;
  return 0;
}
