#include "/Kernel/I386/MemoryBackingConfig.HH"
I64 BackingPlaneBudgetTest()
{//Four logical planes fit in 192 KiB without changing public sizes or buckets.
  CI386BackingPool *pool=&backing_pool;
  CHeapCtrl *hc=&backing_heaps[0];
  U8 *planes[4];
  I64 p,i,capacity;
  U32 flags=GetRFlags;
  if(!I386HeapInit(&backing_heap,0x40000,196608) ||
      !I386MemBackingInit(pool,&backing_heap,I386_NATIVE_BACKING_QUANTUM) ||
      !I386MemHeapInit(hc,pool))return 450;
  for(p=0;p<4;p++) {
    planes[p]=I386MemAlloc(hc,38400);
    if(!planes[p])return 451;
    capacity=I386MemSize(planes[p]);
    if(capacity<38400 || capacity>=38912 || !I386MemBackingValid(pool))return 452;
    for(i=0;i<38400;i++)planes[p][i]=i+p;
  }
  //Retain all four simultaneously and preserve each plane while growing others.
  for(p=0;p<4;p++)for(i=0;i<38400;i++)
    if(planes[p][i]!=(i+p)(U8))return 453;
  if(backing_heap.used>160000 || pool->owned_count!=4)return 454;
  for(p=0;p<4;p++)if(!I386MemFree(planes[p]))return 455;
  if(!I386MemHeapDestroy(hc) || I386MemBackingTrim(pool)<=0 ||
      !I386MemBackingDestroy(pool) || backing_heap.used ||
      backing_heap.allocations || !I386HeapValid(&backing_heap))return 456;
  if((GetRFlags^flags)&0x200)return 457;
  return 0;
}
