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
class CI386PublicPool:CBlkPool { U8 *arena; U32 size,signature; };
extern Bool I386MemPoolInit(CI386PublicPool *pool,U8 *arena,I64 size);
extern CMemBlk *I386MemPageAlloc(CI386PublicPool *pool,I64 pages);
extern Bool I386MemPageFree(CI386PublicPool *pool,CMemBlk *block);
extern Bool I386MemHeapInit(CHeapCtrl *hc,CI386PublicPool *pool,CTask *task=0);
extern Bool I386MemHeapDestroy(CHeapCtrl *hc);
extern U8 *I386MemAlloc(CHeapCtrl *hc,I64 size);
extern Bool I386MemFree(U8 *ptr);
extern I64 I386MemSize(U8 *ptr);
#endif
