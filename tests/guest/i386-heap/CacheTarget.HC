#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Memory.HC"
CI386PublicPool cache_pool;
CHeapCtrl cache_heap;
I64 Main(I64 a,I64 b)
{
  CI386PublicPool *pool=&cache_pool;
  CHeapCtrl *hc=&cache_heap;
  CMemUsed *used;
  U8 *slots[64],*q;
  I64 total,old,i;
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
  return 0;
}
