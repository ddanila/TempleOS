#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
//Link Context, Scheduler, Heap and Cpu once. Requires working Fs task binding.
public U0 I386TaskReturn()
{//Normal entry return retires the current task; another task destroys its stack.
  I386SchedFinish(I386TaskSelf->owner);
  while (1) {}
}
public CI386OwnedTask *I386TaskSpawnFrom(CI386Scheduler *s,CI386Heap *heap,
  CI386Task *parent,I64 stack_size,U0 (*entry)(I64 arg),I64 arg,
  U16 fs=0x18,U16 gs=0x20,I64 private_size=0)
{//NULL-returning bootstrap API, not the full public Spawn/OutMem contract.
  CI386OwnedTask *owned;
  CI386Heap *file_heap;
  I64 header=(sizeof(CI386OwnedTask)+offset(CTaskStk.stk_base)+7)&~7,total;
  U32 flags;
  if (!s || !s->root || !s->bind || !parent || parent->owner!=s ||
      parent->addr!=parent || parent->finished || parent->finishing ||
      !heap || !entry || stack_size<256 ||
      stack_size&7 || stack_size>0xFFFFFFFF-header) return 0;
  if (private_size<0 || private_size&7 || (private_size && private_size<24) ||
      private_size>0xFFFFFFFF-header-stack_size) return 0;
  total=header+stack_size+private_size;
  flags=I386IrqSave;
  if(parent!=s->current && (!s->current || s->current->owner!=s ||
      s->current->finished || s->current->finishing || s->current->lifetime_refs==0xFFFFFFFF)) {
    I386IrqRestore(flags); return 0;
  }
  owned=I386HeapAlloc(heap,total,TRUE);
  if (!owned) { I386IrqRestore(flags); return 0; }
  owned->heap=heap; owned->allocation_size=total; owned->signature=0x54323349;
  //The public descriptor directly precedes its eight-byte-aligned stack.
  owned->task.stk=(owned+0)(U8 *)+header-offset(CTaskStk.stk_base);
  owned->task.stk->stk_size=stack_size;
  if (private_size) {
    if (!I386HeapInit(&owned->local_heap,(owned+0)(U8 *)+header+stack_size,private_size)) {
      I386HeapFree(heap,owned); I386IrqRestore(flags); return 0;
    }
    owned->task.memory=&owned->local_heap;
  }
  if (!I386ContextInit(&owned->task.context,&owned->task.stk->stk_base,owned->task.stk->stk_size,
      entry,arg,&I386TaskReturn,fs,gs)) goto spawn_fail;
  file_heap=heap; if(owned->task.memory) file_heap=owned->task.memory;
  if(I386TaskHeapHooks(parent)) {
    if(I386TaskHeapHooks(parent)!=31 ||
        !(*parent->heap_clone)(parent,&owned->task,file_heap)) goto spawn_fail;
  }
  if(parent->file_state || parent->file_clone || parent->file_destroy) {
    if(!parent->file_state || !parent->file_clone || !parent->file_destroy ||
        !(*parent->file_clone)(parent,&owned->task,file_heap)) goto spawn_fail;
  }
  if(parent->hash_table || parent->symbol_state || parent->symbol_clone || parent->symbol_destroy) {
    if(!parent->hash_table || !parent->symbol_state || !parent->symbol_clone || !parent->symbol_destroy ||
        !(*parent->symbol_clone)(parent,&owned->task,file_heap)) goto spawn_fail;
  }
  //Inherited state belongs to the parent; entry code can belong to the creator.
  if(parent!=s->current) {
    owned->creator=s->current; owned->creator->lifetime_refs++;
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
  if(owned->task.heap_state && (!owned->task.heap_destroy || !(*owned->task.heap_destroy)(&owned->task))) {
    I386IrqRestore(flags); return 0;
  }
  if(owned->creator) owned->creator->lifetime_refs--;
  I386HeapFree(heap,owned);
  I386IrqRestore(flags);
  return 0;
}
public CI386OwnedTask *I386TaskSpawn(CI386Scheduler *s,CI386Heap *heap,
  I64 stack_size,U0 (*entry)(I64 arg),I64 arg,U16 fs=0x18,U16 gs=0x20,I64 private_size=0)
{
  if(!s) return 0;
  return I386TaskSpawnFrom(s,heap,s->current,stack_size,entry,arg,fs,gs,private_size);
}
public Bool I386TaskDestroy(CI386OwnedTask *owned)
{//Readable live owned record required. Never destroy from its own stack.
  U32 flags=I386IrqSave;
  CI386Heap *heap;
  CI386Task *creator;
  Bool result;
  if (!owned || owned->signature!=0x54323349 || !owned->task.owner ||
      !owned->task.finished || owned->task.owner->current==&owned->task) {
    I386IrqRestore(flags); return FALSE;
  }
  heap=owned->heap;
  creator=owned->creator;
  if(creator && (creator->owner!=owned->task.owner || !creator->lifetime_refs)) {
    I386IrqRestore(flags); return FALSE;
  }
  if (I386HeapSize(heap,owned)!=owned->allocation_size ||
      !I386SchedReap(owned->task.owner,&owned->task)) {
    I386IrqRestore(flags); return FALSE;
  }
  result=I386HeapFree(heap,owned);
  if(result && creator) creator->lifetime_refs--;
  I386IrqRestore(flags);
  return result;
}
