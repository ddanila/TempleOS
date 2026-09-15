#ifndef I386_TASK_STORAGE_IMPLEMENTED
#define I386_TASK_STORAGE_IMPLEMENTED
#include "/Kernel/I386/TaskSymbols.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386TaskStorageValid(CI386Heap *heap,CI386TaskStorage *storage)
{//Preflight while interrupts are masked; no free or callback may yield.
  I64 i;
  CI386StoredAllocation *item;
  if(!storage || !storage->count || storage->count>0xFFFFFFD ||
      I386HeapSize(heap,storage)!=sizeof(CI386TaskStorage)+
        (storage->count-1)*sizeof(CI386StoredAllocation)) return FALSE;
  for(i=0;i<storage->count;i++) {
    item=&storage->allocations[i];
    if(!item->allocation) return FALSE;
    if(item->owner) {
      if(!item->owner->code_capacity || !item->owner->code_release ||
          (*item->owner->code_capacity)(item->owner,item->allocation)<0 ||
          item->owner->control.locked_flags || item->owner->control.bp->locked_flags) return FALSE;
    } else if(I386HeapSize(heap,item->allocation)<0) return FALSE;
  }
  return TRUE;
}
Bool I386TaskStorageRelease(CI386Heap *heap,CI386TaskStorage *storage)
{//Caller detached this exclusive storage record; providers outlive task symbols.
  I64 i;
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  CI386StoredAllocation *item;
  if(!I386TaskStorageValid(heap,storage)) goto done;
  for(i=0;i<storage->count;i++) {
    item=&storage->allocations[i];
    if(item->owner) {
      if(!item->owner->code_release ||
          !(*item->owner->code_release)(item->owner,item->allocation)) goto done;
    } else if(!I386HeapFree(heap,item->allocation)) goto done;
  }
  result=I386HeapFree(heap,storage);
done:
  I386IrqRestore(flags); return result;
}
#endif
