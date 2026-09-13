#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
//Link Context, Scheduler, Heap and Cpu once. Requires working Fs task binding.
public U0 I386TaskReturn()
{//Normal entry return retires the current task; another task destroys its stack.
  I386SchedFinish(I386TaskSelf->owner);
  while (1) {}
}
public CI386OwnedTask *I386TaskSpawn(CI386Scheduler *s,CI386Heap *heap,
  I64 stack_size,U0 (*entry)(I64 arg),I64 arg,U16 fs=0x18,U16 gs=0x20)
{//NULL-returning bootstrap API, not the full public Spawn/OutMem contract.
  CI386OwnedTask *owned;
  I64 header=(sizeof(CI386OwnedTask)+7)&~7,total;
  U32 flags;
  if (!s || !s->root || !s->bind || !heap || !entry || stack_size<256 ||
      stack_size&7 || stack_size>0xFFFFFFFF-header) return 0;
  total=header+stack_size;
  flags=I386IrqSave;
  owned=I386HeapAlloc(heap,total,TRUE);
  if (!owned) { I386IrqRestore(flags); return 0; }
  owned->heap=heap; owned->allocation_size=total; owned->signature=0x54323349;
  if (!I386ContextInit(&owned->task.context,(owned+0)(U8 *)+header,stack_size,
      entry,arg,&I386TaskReturn,fs,gs) || !I386SchedAdd(s,&owned->task)) {
    I386HeapFree(heap,owned);
    I386IrqRestore(flags);
    return 0;
  }
  I386IrqRestore(flags);
  return owned;
}
public Bool I386TaskDestroy(CI386OwnedTask *owned)
{//Readable live owned record required. Never destroy from its own stack.
  U32 flags=I386IrqSave;
  CI386Heap *heap;
  Bool result;
  if (!owned || owned->signature!=0x54323349 || !owned->task.owner ||
      !owned->task.finished || owned->task.owner->current==&owned->task) {
    I386IrqRestore(flags); return FALSE;
  }
  heap=owned->heap;
  if (I386HeapSize(heap,owned)!=owned->allocation_size ||
      !I386SchedReap(owned->task.owner,&owned->task)) {
    I386IrqRestore(flags); return FALSE;
  }
  result=I386HeapFree(heap,owned);
  I386IrqRestore(flags);
  return result;
}
