//Kernel-lifetime backing provider and public task heap ownership.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/MemoryRuntime.HH"
#include "/Kernel/I386/MemoryBacking.HH"
#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/KernelSymbols.HH"
#include "/Kernel/I386/MemoryPublic.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import Bool I386HeapValid(CI386Heap *heap);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import U0 HashAdd(CHash *entry,CHashTable *table);
import U0 throw(I64 ch=0,Bool no_log=FALSE);
CI386BackingPool memory_pool;
CI386Task *memory_root;
U32 memory_runtime_version=I386_MEMORY_SERVICES_VERSION;
CI386KernelSymbol memory_exports[8];
extern U0 MemoryReclaim(CI386PublicPool *pool);
extern U0 MemoryProbe(I64 phase);
Bool MemoryBind(CI386Task *root,CI386Heap *heap,CHashTable *symbols)
{//No arena is reserved until a task actually requests pages.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  U8 *addresses[8],*names="_MALLOC\0_FREE\0_MSIZE\0_MSIZE2\0_MHEAP_CTRL\0_CALLOC\0_MALLOC_ALIGNED\0_CALLOC_ALIGNED\0";
  I64 i;
  if(memory_root || !symbols || !symbols->body || symbols->locked_flags ||
      !root || !root->owner || root->owner->root!=root ||
      root->owner->current!=root || !I386MemBackingInit(&memory_pool,heap)) goto done;
  if(!I386TaskHeapsInit(root,heap,&memory_pool)) {
    if(!I386MemBackingDestroy(&memory_pool)) KernelStop;
    goto done;
  }
  memory_pool.reclaim=&MemoryReclaim; memory_root=root; result=TRUE;
  addresses[0]=&MemoryAlloc; addresses[1]=&MemoryFree; addresses[2]=&MemorySize;
  addresses[3]=&MemorySize2; addresses[4]=&MemoryHeap; addresses[5]=&MemoryCAlloc;
  addresses[6]=&MemoryAligned; addresses[7]=&MemoryCAligned;
  for(i=0;i<8;i++) {
    memory_exports[i].str=names; memory_exports[i].type=HTT_EXPORT_SYS_SYM;
    memory_exports[i].kind=1; memory_exports[i].val=(addresses[i]+0)(U64);
    HashAdd(&memory_exports[i],symbols);
    while(*names) names++;
    names++;
  }
done:
  I386IrqRestore(flags); return result;
}
I64 Main(CI386MemoryServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386MemoryServices)) return 0;
  services->version=memory_runtime_version; services->bytes=bytes;
  services->bind=&MemoryBind; services->probe=&MemoryProbe;
  return 1;
}
U0 MemoryReclaim(CI386PublicPool *pool)
{//TaskHeapsDestroy has released its control and stopped reading page headers.
  if(pool!=&memory_pool || I386MemBackingTrim(&memory_pool)<0) KernelStop;
}
U0 MemoryProbe(I64 phase)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskHeaps *state=task->heap_state;
  U32 flags=I386IrqSave;
  I64 before=memory_pool.heap->used,allocations=memory_pool.heap->allocations;
  U8 *p,*q;
  if(!memory_root || !state || task->code_heap!=task->data_heap ||
      task->data_heap!=&state->control || state->control.mem_task!=task ||
      state->control.bp!=&memory_pool ||
      !phase && (task!=memory_root || state->parent) ||
      phase && (task==memory_root || state->parent!=memory_root->heap_state)) KernelStop;
  //Separate large allocations return pages immediately; a large request also
  //forces growth beyond the first region. Both regions must return to bootstrap.
  p=MemoryAligned(2048,64,task,3); q=MemoryCAlloc(131000,task->code_heap);
  if(!p || !q || memory_pool.owned_count!=2 || MemorySize(p)<2048 ||
      MemorySize(q)<131000 || (p+0)(U64)%64!=3 || p(I64 *)[-1]>=0 || q[0] || q[130999] ||
      MemoryHeap(p)!=task->data_heap || MemoryHeap(q)!=task->code_heap ||
      MemorySize2(p)!=MemorySize(p)+offset(CMemUsed.start)) KernelStop;
  p[0]=71; p[2047]=83; q[0]=97; q[130999]=109;
  MemoryFree(q);
  if(memory_pool.owned_count!=1 || p[0]!=71 || p[2047]!=83) KernelStop;
  MemoryFree(p);
  p=MemoryCAligned(2048,256,0,5);
  if((p+0)(U64)%256!=5 || p[0] || p[2047]) KernelStop;
  MemoryFree(p); MemoryFree(0);
  if(MemorySize(0) || MemorySize2(0) || MemoryHeap(0)) KernelStop;
  if(memory_pool.owned_count || memory_pool.retained || memory_pool.used_u8s ||
      memory_pool.heap->used!=before || memory_pool.heap->allocations!=allocations ||
      !I386HeapValid(memory_pool.heap)) KernelStop;
  I386IrqRestore(flags);
  KernelLog("MEMORY PROBE "); KernelHex(phase); KernelLog("\n");
}
#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
#include "/Kernel/I386/TaskHeaps.HC"
#include "/Kernel/I386/MemoryPublic.HC"
