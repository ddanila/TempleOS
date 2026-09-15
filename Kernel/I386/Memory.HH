#ifndef I386_MEMORY_INCLUDED
#define I386_MEMORY_INCLUDED
#ifndef CTask
extern class CTask;
#endif
#ifndef CHeapCtrl
extern class CHeapCtrl;
#endif
#include "/Kernel/MemoryAllocTypes.HH"
#include "/Kernel/MemoryTypes.HH"
//Internal backing provider for the complete public pool/heap records.
//Caller owns the pool record, arena and controls. This core does not allocate
//control storage or bind tasks; those lifetimes belong to the retained service.
#define I386_POOL_SIGNATURE 'P32S'
extern class CI386PublicPool;
class CI386PoolRegion:CMemRange {
  CI386PublicPool *pool;
  U32 used;
};
class CI386PublicPool:CBlkPool {
  CI386PoolRegion *regions;
  U32 size,signature,region_count,growing;
  Bool (*grow)(CI386PublicPool *pool,I64 pages);
  //Notification after task heap teardown; never invoked while reading page headers.
  //Provider and callback code outlive every attached task. Callback must not yield.
  U0 (*reclaim)(CI386PublicPool *pool);
  CI386PoolRegion initial;
};
//Region records and their backing bytes are borrowed and must remain live until
//Remove succeeds. Additional records start zeroed, outside all managed arenas.
extern Bool I386MemPoolValid(CI386PublicPool *pool);
extern Bool I386MemPoolEmpty(CI386PublicPool *pool);
extern Bool I386MemPoolAdd(CI386PublicPool *pool,CI386PoolRegion *region,U8 *arena,I64 size);
extern Bool I386MemPoolRemove(CI386PublicPool *pool,CI386PoolRegion *region);
extern Bool I386MemPoolInit(CI386PublicPool *pool,U8 *arena,I64 size);
extern CMemBlk *I386MemPageAlloc(CI386PublicPool *pool,I64 pages);
extern Bool I386MemPageFree(CI386PublicPool *pool,CMemBlk *block);
extern Bool I386MemHeapInit(CHeapCtrl *hc,CI386PublicPool *pool,CTask *task=0);
extern Bool I386MemHeapDestroy(CHeapCtrl *hc);
extern U8 *I386MemAlloc(CHeapCtrl *hc,I64 size);
extern Bool I386MemFree(U8 *ptr);
extern I64 I386MemSize(U8 *ptr);
#endif
