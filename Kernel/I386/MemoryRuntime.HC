//Kernel-lifetime backing provider and public task heap ownership.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/MemoryRuntime.HH"
#include "/Kernel/I386/MemoryBacking.HH"
#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/Cpu.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import Bool I386HeapValid(CI386Heap *heap);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
CI386BackingPool memory_pool;
CI386Task *memory_root;
U32 memory_runtime_version=I386_MEMORY_SERVICES_VERSION;
extern U0 MemoryReclaim(CI386PublicPool *pool);
extern U0 MemoryProbe(I64 phase);
Bool MemoryBind(CI386Task *root,CI386Heap *heap)
{//No arena is reserved until a task actually requests pages.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(memory_root || !root || !root->owner || root->owner->root!=root ||
      root->owner->current!=root || !I386MemBackingInit(&memory_pool,heap)) goto done;
  if(!I386TaskHeapsInit(root,heap,&memory_pool)) {
    if(!I386MemBackingDestroy(&memory_pool)) KernelStop;
    goto done;
  }
  memory_pool.reclaim=&MemoryReclaim; memory_root=root; result=TRUE;
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
  p=I386MemAlloc(task->data_heap,2048); q=I386MemAlloc(task->code_heap,131000);
  if(!p || !q || memory_pool.owned_count!=2 || I386MemSize(p)<2048 ||
      I386MemSize(q)<131000) KernelStop;
  p[0]=71; p[2047]=83; q[0]=97; q[130999]=109;
  if(!I386MemFree(q)) KernelStop;
  MemoryReclaim(&memory_pool);
  if(memory_pool.owned_count!=1 || p[0]!=71 || p[2047]!=83 || !I386MemFree(p)) KernelStop;
  MemoryReclaim(&memory_pool);
  if(memory_pool.owned_count || memory_pool.retained || memory_pool.used_u8s ||
      memory_pool.heap->used!=before || memory_pool.heap->allocations!=allocations ||
      !I386HeapValid(memory_pool.heap)) KernelStop;
  I386IrqRestore(flags);
  KernelLog("MEMORY PROBE "); KernelHex(phase); KernelLog("\n");
}
#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
#include "/Kernel/I386/TaskHeaps.HC"
