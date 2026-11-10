#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define NULL 0
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
CI386BackingPool preferred_pool;
CI386Heap preferred_main,preferred_low;
I64 Main(I64 unused_a,I64 unused_b)
{
  CMemBlk *page;
  I64 test,i,main_size,low_size,expected_size;
  U32 flags=GetRFlags;
  for(test=0;test<4;test++) {
    for(i=0;i<sizeof(preferred_pool);i++) (&preferred_pool)(U8 *)[i]=0;
    main_size=0x20000;low_size=512;expected_size=8192;
    if(!test)low_size=4096;
    if(test==2) { main_size=4096;expected_size=512; }
    if(test==3)main_size=512;
    if(!I386HeapInit(&preferred_main,0x48000,main_size) ||
        !I386HeapInit(&preferred_low,0x68000,low_size) ||
        !I386MemBackingInit(&preferred_pool,&preferred_main,8192) ||
        !I386MemBackingSetFallback(&preferred_pool,&preferred_low))return 600+test;
    page=I386MemPageAlloc(&preferred_pool,1,TRUE);
    if(!test) {
      //The preferred arena fits the request, even though its batch hint does not.
      if(!page || preferred_main.used || !preferred_low.used ||
          preferred_pool.owned->size!=512)return 610;
    } else if(test<3) {
      //An undersized preferred arena still falls through to the main arena.
      if(!page || !preferred_main.used || preferred_low.used ||
          preferred_pool.owned->size!=expected_size)return 611+test;
    } else if(page || preferred_main.used || preferred_low.used ||
        preferred_pool.owned_count)return 614;
    if(!I386MemBackingValid(&preferred_pool) ||
        !I386HeapValid(&preferred_main) || !I386HeapValid(&preferred_low))return 620+test;
    if(page && !I386MemPageFree(&preferred_pool,page))return 630+test;
    I386MemBackingTrim(&preferred_pool);
    if(!I386MemBackingDestroy(&preferred_pool) ||
        preferred_main.used || preferred_main.allocations ||
        preferred_low.used || preferred_low.allocations ||
        !I386HeapValid(&preferred_main) || !I386HeapValid(&preferred_low) ||
        (GetRFlags^flags)&0x200)return 640+test;
  }
  return 0;
}
