#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Memory.HC"
CI386PublicPool cache_pool;
CI386PoolRegion cache_extra_region;
CHeapCtrl cache_heap;
I64 Main(I64 a,I64 b)
{
  CI386PublicPool *pool=&cache_pool;
  CHeapCtrl *hc=&cache_heap;
  CMemUsed *used;
  CMemBlk *page_a,*page_b,*joined;
  U8 *slots[64],*q;
  I64 total,old,i;
  U32 saved_flags=GetRFlags;
  if(!I386MemPoolInit(pool,0x40000,0x40000) ||
      !I386MemHeapInit(hc,pool,0x1234)) return 131;
  //Fill one small-allocation batch, leaving only an exact-size cached span.
  //A smaller request must split that span without reserving another page batch.
  slots[0]=I386MemAlloc(hc,1000); total=1;
  while(hc->malloc_free_lst) {
    old=hc->malloc_free_lst->size;
    if(total>=64 || old<sizeof(CMemUnused)) return 132;
    if(old>1016) old=1016;
    slots[total]=I386MemAlloc(hc,old-offset(CMemUsed.start));
    if(!slots[total]) return 133;
    slots[total][0]=0xA5; total++;
  }
  old=hc->alloced_u8s;
  if(!I386MemFree(slots[0])) return 134;
  q=I386MemAlloc(hc,32); used=q-offset(CMemUsed.start);
  if(!q || (q+0)(U64)&7 || I386MemSize(q)!=36 ||
      hc->alloced_u8s!=old || used->hc!=hc)
    return 135;
  q[0]=71; q[31]=83;
  for(i=1;i<total;i++) {
    if(slots[i][0]!=0xA5 || !I386MemFree(slots[i])) return 136;
  }
  if(q[0]!=71 || q[31]!=83 || !I386MemFree(q) || hc->used_u8s ||
      !I386MemHeapDestroy(hc) || pool->used_u8s) return 137;
  if(!I386MemHeapInit(hc,pool,0x1234)) return 138;
  //Two adjacent cached spans must jointly satisfy a larger small request.
  slots[0]=I386MemAlloc(hc,300); slots[1]=I386MemAlloc(hc,300); total=2;
  if(!slots[0] || !slots[1]) return 139;
  while(hc->malloc_free_lst) {
    old=hc->malloc_free_lst->size;
    if(total>=64 || old<sizeof(CMemUnused)) return 140;
    if(old>1016) old=1016;
    slots[total]=I386MemAlloc(hc,old-offset(CMemUsed.start));
    if(!slots[total]) return 141;
    slots[total][0]=0xA5; total++;
  }
  old=hc->alloced_u8s;
  if(!I386MemFree(slots[0]) || !I386MemFree(slots[1])) return 142;
  q=I386MemAlloc(hc,500);
  if(!q || hc->alloced_u8s!=old || (q+0)(U64)&7 ||
      I386MemSize(q)!=500) return 143;
  q[0]=71; q[499]=83;
  for(i=2;i<total;i++) {
    if(slots[i][0]!=0xA5 || !I386MemFree(slots[i])) return 144;
  }
  if(q[0]!=71 || q[499]!=83 || !I386MemFree(q) || hc->used_u8s ||
      !I386MemHeapDestroy(hc) || pool->used_u8s) return 145;
  //Returned page blocks in the same ownership region must recover a larger
  //contiguous request without growing the pool. Both exact-size caches are
  //individually too small, and every page has first been allocated.
  if(!I386MemPoolRemove(pool,&pool->initial) ||
      !I386MemPoolInit(pool,0x40000,8192)) return 146;
  page_a=I386MemPageAlloc(pool,8); page_b=I386MemPageAlloc(pool,8);
  if(!page_a || !page_b || pool->used_u8s!=8192 ||
      !I386MemPageFree(pool,page_a) || !I386MemPageFree(pool,page_b)) return 147;
  joined=I386MemPageAlloc(pool,16);
  if(joined!=0x40000 || joined->pags!=16 || pool->used_u8s!=8192 ||
      !I386MemPoolValid(pool)) return 148;
  if(!I386MemPageFree(pool,joined) || pool->used_u8s ||
      !I386MemPoolRemove(pool,&pool->initial) || !I386MemPoolEmpty(pool)) return 149;
  //Adjacent addresses belonging to distinct borrowed regions cannot merge.
  if(!I386MemPoolInit(pool,0x40000,4096) ||
      !I386MemPoolAdd(pool,&cache_extra_region,0x41000,4096)) return 150;
  page_a=I386MemPageAlloc(pool,8); page_b=I386MemPageAlloc(pool,8);
  if(!page_a || !page_b || !I386MemPageFree(pool,page_a) ||
      !I386MemPageFree(pool,page_b) || I386MemPageAlloc(pool,16) ||
      pool->used_u8s || !I386MemPoolValid(pool)) return 151;
  page_a=I386MemPageAlloc(pool,8); page_b=I386MemPageAlloc(pool,8);
  if(!page_a || !page_b || page_a==page_b || pool->used_u8s!=8192 ||
      !I386MemPageFree(pool,page_a) || !I386MemPageFree(pool,page_b) ||
      !I386MemPoolRemove(pool,&cache_extra_region) ||
      !I386MemPoolRemove(pool,&pool->initial) || !I386MemPoolEmpty(pool)) return 152;
  //A small allocation must fit an available page even when the usual cached
  //batch cannot be reserved. Payload size and alignment stay unchanged.
  if(!I386MemPoolInit(pool,0x40000,512) ||
      !I386MemHeapInit(hc,pool,0x1234)) return 153;
  q=I386MemAlloc(hc,160);
  if(!q || (q+0)(U64)&7 || I386MemSize(q)<160 ||
      hc->alloced_u8s!=512 || pool->used_u8s!=512) return 154;
  q[0]=71; q[159]=83;
  if(q[0]!=71 || q[159]!=83 || !I386MemFree(q) || hc->used_u8s ||
      !I386MemHeapDestroy(hc) || pool->used_u8s ||
      !I386MemPoolRemove(pool,&pool->initial) || !I386MemPoolEmpty(pool)) return 155;
  //A non-power-of-two large request must fit without its speculative bucket.
  if(!I386MemPoolInit(pool,0x40000,300*512)) return 156;
  page_a=I386MemPageAlloc(pool,280);
  if(!page_a || page_a->pags!=280 || pool->used_u8s!=280*512 ||
      !I386MemPageFree(pool,page_a)) return 157;
  page_b=I386MemPageAlloc(pool,280);
  if(page_b!=page_a || page_b->pags!=280 || !I386MemPageFree(pool,page_b) ||
      pool->used_u8s || !I386MemPoolValid(pool)) return 158;
  if(!I386MemHeapInit(hc,pool,0x1234)) return 159;
  q=I386MemAlloc(hc,140000);
  if(!q || (q+0)(U64)&7 || I386MemSize(q)<140000 ||
      hc->alloced_u8s>300*512 || !I386MemPoolValid(pool)) return 160;
  q[0]=71; q[139999]=83;
  if(q[0]!=71 || q[139999]!=83 || !I386MemFree(q) || hc->used_u8s ||
      !I386MemHeapDestroy(hc) || pool->used_u8s ||
      !I386MemPoolRemove(pool,&pool->initial) || !I386MemPoolEmpty(pool)) return 161;
  //Opt-in exact pages preserve normal buckets while fitting fixed buffers.
  if(!I386MemPoolInit(pool,0x40000,600*512)) return 162;
  page_a=I386MemPageAlloc(pool,280,TRUE);
  page_b=I386MemPageAlloc(pool,280,TRUE);
  if(!page_a || !page_b || page_a->pags!=280 || page_b->pags!=280 ||
      pool->used_u8s!=560*512) return 163;
  page_a(U8 *)[16]=71; page_a(U8 *)[280*512-1]=83;
  page_b(U8 *)[16]=97; page_b(U8 *)[280*512-1]=109;
  if(page_a(U8 *)[16]!=71 || page_a(U8 *)[280*512-1]!=83 ||
      page_b(U8 *)[16]!=97 || page_b(U8 *)[280*512-1]!=109 ||
      (GetRFlags^saved_flags)&0x200) return 167;
  if(!I386MemPageFree(pool,page_a) || !I386MemPageFree(pool,page_b) ||
      !I386MemPoolRemove(pool,&pool->initial)) return 164;
  if(!I386MemPoolInit(pool,0x40000,600*512)) return 165;
  page_a=I386MemPageAlloc(pool,280);
  if(!page_a || page_a->pags!=514 || !I386MemPageFree(pool,page_a) ||
      !I386MemPoolRemove(pool,&pool->initial)) return 166;
  //Exact requests split a larger returned bucket rather than consuming it.
  if(!I386MemPoolInit(pool,0x40000,600*512)) return 168;
  page_a=I386MemPageAlloc(pool,280);
  if(!page_a || page_a->pags!=514 || !I386MemPageFree(pool,page_a)) return 169;
  page_a=I386MemPageAlloc(pool,280,TRUE);
  page_b=I386MemPageAlloc(pool,200,TRUE);
  if(!page_a || !page_b || page_a->pags!=280 || page_b->pags!=200 ||
      pool->used_u8s!=480*512) return 170;
  if(!I386MemPageFree(pool,page_a) || !I386MemPageFree(pool,page_b) ||
      !I386MemPoolRemove(pool,&pool->initial) ||
      (GetRFlags^saved_flags)&0x200) return 171;
  return 0;
}
