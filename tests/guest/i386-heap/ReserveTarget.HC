#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
#include "/Kernel/I386/MemoryBackingConfig.HH"
extern Bool I386MemBackingReserve(CI386BackingPool *pool,I64 pages);
CI386BackingPool reserve_pool;
CI386Heap reserve_heap;
CHeapCtrl reserve_controls[2];
U64 ReserveHash(U8 *bytes,I64 count)
{
  U64 hash=0x123456789ABCDEF0;I64 i;
  for(i=0;i<count;i++)hash=(hash<<5)^(hash>>59)^bytes[i];
  return hash;
}
I64 Main(I64 unused_a,I64 unused_b)
{
  CI386BackingPool *pool=&reserve_pool;
  CI386Heap *heap=&reserve_heap;
  U8 *private_bytes,*a,*b,*c;
  I64 used,allocations,i;
  U64 before,pool_before;
  U32 flags=GetRFlags;
  if(!I386HeapInit(heap,0x40000,196608) ||
      !I386MemBackingInit(pool,heap,I386_NATIVE_BACKING_QUANTUM) ||
      !I386MemBackingReserve(pool,128) || pool->size!=65536 ||
      pool->used_u8s || pool->owned_count!=1 || !I386MemBackingValid(pool))return 470;
  //Automatic reclamation must retain explicit startup reservations.
  if(I386MemBackingTrim(pool)!=0 || pool->size!=65536 || pool->owned_count!=1)return 478;
  used=heap->used;allocations=heap->allocations;
  before=ReserveHash(heap->base,heap->size);pool_before=ReserveHash(pool,sizeof(CI386BackingPool));
  if(I386MemBackingReserve(0,1) || I386MemBackingReserve(pool,0) ||
      I386MemBackingReserve(pool,-1) || I386MemBackingReserve(pool,0x100000000) ||
      heap->used!=used || heap->allocations!=allocations || pool->growing ||
      ReserveHash(heap->base,heap->size)!=before ||
      ReserveHash(pool,sizeof(CI386BackingPool))!=pool_before)return 471;
  //Exhaust physical backing after reservation; fresh heaps must use reserved pages.
  private_bytes=I386HeapAlloc(heap,heap->size-heap->used-16);
  if(!private_bytes || heap->used!=heap->size ||
      !I386MemHeapInit(&reserve_controls[0],pool) ||
      !I386MemHeapInit(&reserve_controls[1],pool))return 472;
  a=I386MemAlloc(&reserve_controls[0],760);
  b=I386MemAlloc(&reserve_controls[1],760);
  c=I386MemAlloc(&reserve_controls[1],2048);
  if(!a || !b || !c || pool->owned_count!=1 || heap->allocations!=2 ||
      !I386MemBackingValid(pool))return 473;
  for(i=0;i<760;i++){a[i]=0xA5;b[i]=0x5A;}
  for(i=0;i<2048;i++)c[i]=i;
  before=ReserveHash(heap->base,heap->size);pool_before=ReserveHash(pool,sizeof(CI386BackingPool));
  if(I386MemBackingDestroy(pool) ||
      ReserveHash(heap->base,heap->size)!=before ||
      ReserveHash(pool,sizeof(CI386BackingPool))!=pool_before)return 479;
  if(I386MemBackingReserve(pool,16) || pool->growing ||
      ReserveHash(heap->base,heap->size)!=before ||
      ReserveHash(pool,sizeof(CI386BackingPool))!=pool_before)return 474;
  for(i=0;i<760;i++)if(a[i]!=0xA5 || b[i]!=0x5A)return 475;
  for(i=0;i<2048;i++)if(c[i]!=(i+0)(U8))return 476;
  if(!I386MemFree(a) || !I386MemFree(b) || !I386MemFree(c) ||
      !I386MemHeapDestroy(&reserve_controls[0]) || !I386MemHeapDestroy(&reserve_controls[1]) ||
      I386MemBackingTrim(pool)!=0 || !I386MemBackingReleaseReserve(pool) ||
      I386MemBackingTrim(pool)<=0 || !I386MemBackingDestroy(pool) ||
      !I386HeapFree(heap,private_bytes) || heap->used || heap->allocations ||
      !I386HeapValid(heap) || (GetRFlags^flags)&0x200)return 477;
  //Provider shutdown must also release an unused held reservation directly.
  if(!I386MemBackingInit(pool,heap,I386_NATIVE_BACKING_QUANTUM) ||
      !I386MemBackingReserve(pool,64) || !I386MemBackingDestroy(pool) ||
      heap->used || heap->allocations || !I386HeapValid(heap) ||
      (GetRFlags^flags)&0x200)return 480;
  return 0;
}
