#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
//Link Context, Scheduler, Heap and Cpu once. Requires working Fs task binding.
public U0 I386TaskReturn()
{//Normal entry return retires the current task; another task destroys its stack.
  I386SchedFinish(I386TaskSelf->owner);
  while (1) {}
}
public CI386OwnedTask *I386TaskSpawn(CI386Scheduler *s,CI386Heap *heap,
  I64 stack_size,U0 (*entry)(I64 arg),I64 arg,U16 fs=0x18,U16 gs=0x20,I64 private_size=0)
{//NULL-returning bootstrap API, not the full public Spawn/OutMem contract.
  CI386OwnedTask *owned;
  CI386Heap *file_heap;
  I64 header=(sizeof(CI386OwnedTask)+7)&~7,total;
  U32 flags;
  if (!s || !s->root || !s->bind || !heap || !entry || stack_size<256 ||
      stack_size&7 || stack_size>0xFFFFFFFF-header) return 0;
  if (private_size<0 || private_size&7 || (private_size && private_size<24) ||
      private_size>0xFFFFFFFF-header-stack_size) return 0;
  total=header+stack_size+private_size;
  flags=I386IrqSave;
  owned=I386HeapAlloc(heap,total,TRUE);
  if (!owned) { I386IrqRestore(flags); return 0; }
  owned->heap=heap; owned->allocation_size=total; owned->signature=0x54323349;
  owned->task.stack_base=(owned+0)(U8 *)+header;
  owned->task.stack_size=stack_size;
  if (private_size) {
    if (!I386HeapInit(&owned->local_heap,(owned+0)(U8 *)+header+stack_size,private_size)) {
      I386HeapFree(heap,owned); I386IrqRestore(flags); return 0;
    }
    owned->task.memory=&owned->local_heap;
  }
  if (!I386ContextInit(&owned->task.context,owned->task.stack_base,owned->task.stack_size,
      entry,arg,&I386TaskReturn,fs,gs)) goto spawn_fail;
  if(s->current && (s->current->file_state || s->current->file_clone || s->current->file_destroy)) {
    file_heap=heap; if(owned->task.memory) file_heap=owned->task.memory;
    if(!s->current->file_state || !s->current->file_clone || !s->current->file_destroy ||
        !(*s->current->file_clone)(s->current,&owned->task,file_heap)) goto spawn_fail;
  }
  if(s->current && (s->current->hash_table || s->current->symbol_state || s->current->symbol_clone || s->current->symbol_destroy)) {
    file_heap=heap; if(owned->task.memory) file_heap=owned->task.memory;
    if(!s->current->hash_table || !s->current->symbol_state || !s->current->symbol_clone || !s->current->symbol_destroy ||
        !(*s->current->symbol_clone)(s->current,&owned->task,file_heap)) goto spawn_fail;
  }
  if(!I386SchedAdd(s,&owned->task)) goto spawn_fail;
  I386IrqRestore(flags);
  return owned;
spawn_fail:
  if(owned->task.symbol_state && (!owned->task.symbol_destroy || !(*owned->task.symbol_destroy)(&owned->task))) {
    I386IrqRestore(flags); return 0;
  }
  if(owned->task.file_state && (!owned->task.file_destroy || !(*owned->task.file_destroy)(&owned->task))) {
    I386IrqRestore(flags); return 0;
  }
  I386HeapFree(heap,owned);
  I386IrqRestore(flags);
  return 0;
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
public U8 *I386TaskAlloc(I64 size,Bool zero=FALSE)
{//Try-allocation in the current task's optional private arena.
  U32 flags=I386IrqSave;
  U8 *result=I386HeapAlloc(I386TaskSelf->memory,size,zero);
  I386IrqRestore(flags);
  return result;
}
public Bool I386TaskFree(U8 *ptr)
{
  U32 flags=I386IrqSave;
  Bool result=I386HeapFree(I386TaskSelf->memory,ptr);
  I386IrqRestore(flags);
  return result;
}
