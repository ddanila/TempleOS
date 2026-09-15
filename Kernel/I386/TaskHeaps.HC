#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/Cpu.HH"
CI386TaskHeaps *I386TaskHeapsValid(CI386Task *task)
{
  CI386TaskHeaps *state;
  if(!task || !(state=task->heap_state) || state->signature!=I386_TASK_HEAPS_MAGIC ||
      state->task!=task || task->code_heap!=&state->control || task->data_heap!=&state->control ||
      task->heap_clone!=&I386TaskHeapsClone || task->heap_destroy!=&I386TaskHeapsDestroy ||
      state->control.mem_task!=task || state->control.hc_signature!=HEAP_CTRL_SIGNATURE_VAL ||
      I386HeapSize(state->storage,state)!=sizeof(CI386TaskHeaps)) return 0;
  return state;
}
U8 *I386TaskCodeAllocate(CI386TaskHeaps *owner,I64 bytes)
{
  U32 flags=I386IrqSave;
  U8 *result=0;
  if(owner && I386TaskHeapsValid(owner->task)==owner && !owner->control.bp->locked_flags)
    result=I386MemAlloc(&owner->control,bytes);
  I386IrqRestore(flags); return result;
}
I64 I386TaskCodeCapacity(CI386TaskHeaps *owner,U8 *allocation)
{
  CMemUsed *used;
  U32 flags=I386IrqSave;
  I64 result=-1;
  if(allocation && owner && I386TaskHeapsValid(owner->task)==owner) {
    used=allocation-offset(CMemUsed.start);
    if(used->hc==&owner->control) result=I386MemSize(allocation);
  }
  I386IrqRestore(flags); return result;
}
Bool I386TaskCodeRelease(CI386TaskHeaps *owner,U8 *allocation)
{
  U32 flags=I386IrqSave;
  CI386PublicPool *pool;
  Bool result=FALSE;
  if(I386TaskCodeCapacity(owner,allocation)<0) goto done;
  pool=owner->control.bp;
  if(owner->control.locked_flags || pool->locked_flags) goto done;
  if(!I386MemFree(allocation)) goto done;
  //All object/page-header reads have finished before empty arenas can disappear.
  if(!owner->control.used_u8s && !I386MemHeapTrim(&owner->control)) goto done;
  if(pool->reclaim) (*pool->reclaim)(pool);
  result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskHeapsAttach(CI386Task *task,CI386Heap *storage,CI386PublicPool *pool,
  CI386TaskHeaps *parent)
{//Caller masks interrupts and validates the exclusive target and parent.
  CI386TaskHeaps *state=I386HeapAlloc(storage,sizeof(CI386TaskHeaps),TRUE);
  if(!state) return FALSE;
  if(!I386MemHeapInit(&state->control,pool,task)) {
    I386HeapFree(storage,state); return FALSE;
  }
  state->task=task; state->parent=parent; state->storage=storage;
  state->signature=I386_TASK_HEAPS_MAGIC;
  state->code_allocate=&I386TaskCodeAllocate;
  state->code_release=&I386TaskCodeRelease; state->code_capacity=&I386TaskCodeCapacity;
  if(parent) { parent->children++; parent->task->lifetime_refs++; }
  task->code_heap=task->data_heap=&state->control; task->heap_state=state;
  task->heap_clone=&I386TaskHeapsClone; task->heap_destroy=&I386TaskHeapsDestroy;
  return TRUE;
}
Bool I386TaskHeapsInit(CI386Task *root,CI386Heap *storage,CI386PublicPool *pool)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(root && root->owner && root==root->owner->root && root==root->owner->current &&
      !root->finished && !root->finishing && !root->code_heap && !root->data_heap &&
      !root->heap_state && !root->heap_clone && !root->heap_destroy)
    result=I386TaskHeapsAttach(root,storage,pool,0);
  I386IrqRestore(flags); return result;
}
Bool I386TaskHeapsClone(CI386Task *source,CI386Task *target,CI386Heap *storage)
{
  U32 flags=I386IrqSave;
  CI386TaskHeaps *parent=I386TaskHeapsValid(source);
  Bool result=FALSE;
  if(parent && source->owner && !source->finished && !source->finishing &&
      target && target!=source && !target->owner && !target->code_heap && !target->data_heap &&
      !target->heap_state && !target->heap_clone && !target->heap_destroy &&
      parent->children!=0xFFFFFFFF && source->lifetime_refs!=0xFFFFFFFF)
    result=I386TaskHeapsAttach(target,storage,parent->control.bp,parent);
  I386IrqRestore(flags); return result;
}
Bool I386TaskHeapsDestroy(CI386Task *task)
{
  U32 flags=I386IrqSave;
  CI386TaskHeaps *state=I386TaskHeapsValid(task),*parent;
  CI386PublicPool *pool;
  Bool result=FALSE;
  if(!state || state->children || task->lifetime_refs || task->active_controls ||
      task->compiler_cleanup || task->compiler_cleanup_failed || task->compiler_busy ||
      task->file_state || task->file_clone || task->file_destroy || task->hash_table ||
      task->symbol_state || task->symbol_clone || task->symbol_destroy || task->io_locks ||
      task->except_top || task->messages || task->join_head || task->join_target) goto done;
  if(task->owner) {
    if(task==task->owner->root && task!=task->owner->current ||
        task->next_cc!=&task->next_cc || task->last_cc!=&task->next_cc ||
        task==task->owner->current && task!=task->owner->root ||
        task!=task->owner->root && !task->finished || task->finishing && !task->finished) goto done;
  } else if(task->next_cc || task->last_cc) goto done;
  parent=state->parent;
  if(parent && (I386TaskHeapsValid(parent->task)!=parent || !parent->children ||
      !parent->task->lifetime_refs)) goto done;
  pool=state->control.bp;
  if(!I386MemHeapDestroy(&state->control) || !I386HeapFree(state->storage,state)) goto done;
  if(parent) { parent->children--; parent->task->lifetime_refs--; }
  task->code_heap=0; task->data_heap=0; task->heap_state=0;
  task->heap_clone=0; task->heap_destroy=0;
  if(pool->reclaim) (*pool->reclaim)(pool);
  result=TRUE;
done:
  I386IrqRestore(flags); return result;
}
