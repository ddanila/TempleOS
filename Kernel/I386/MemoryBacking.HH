#ifndef I386_MEMORY_BACKING_INCLUDED
#define I386_MEMORY_BACKING_INCLUDED
#include "/Kernel/I386/Memory.HH"
#include "/Kernel/I386/Heap.HH"
#define I386_BACKING_SIGNATURE 'B32S'
class CI386BackingRegion:CI386PoolRegion {
  CI386BackingRegion *next_owned;
  U32 request,span;
};
class CI386BackingPool:CI386PublicPool {
  CI386Heap *heap;
  CI386BackingRegion *owned;
  U32 backing_signature,quantum,owned_count;
  I64 retained;
};
//The caller retains this record and the bootstrap heap. Page allocation grows
//lazily; trim runs after heap/free operations finish using returned block headers.
extern Bool I386MemBackingInit(CI386BackingPool *pool,CI386Heap *heap,I64 quantum=65536);
extern I64 I386MemBackingTrim(CI386BackingPool *pool);
extern Bool I386MemBackingDestroy(CI386BackingPool *pool);
#endif
