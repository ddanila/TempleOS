#include "/Kernel/I386/Except.HH"
//Single CPU. Requires live task, heap and capture objects; no NMI callers.
CI386Except *I386ExceptPush(CI386Task *task,CI386Heap *heap,CI386ExceptCapture *capture)
{
  U32 flags=I386IrqSave;
  CI386Except *record;
  I64 i;
  if(!task || !task->owner || task->owner->current!=task || task->finished ||
      !capture || !capture->catch_start || !capture->untry_start ||
      !I386FrameValid(capture->ebp,task->stack_base,task->stack_size) ||
      capture->esp&3 || capture->esp<(task->stack_base+0)(U64) ||
      capture->esp>capture->ebp) {
    I386IrqRestore(flags); return 0;
  }
  record=I386HeapAlloc(heap,sizeof(CI386Except),TRUE);
  if(!record) { I386IrqRestore(flags); return 0; }
  record->previous=task->except_top; record->task=task; record->heap=heap;
  record->signature=I386_EXCEPT_MAGIC;
  for(i=0;i<sizeof(CI386ExceptCapture)/4;i++)
    (&record->capture)(U32 *)[i]=capture(U32 *)[i];
  task->except_top=record;
  I386IrqRestore(flags);
  return record;
}
Bool I386ExceptPop(CI386Task *task)
{
  U32 flags=I386IrqSave;
  CI386Except *record,*previous;
  //An inactive live task owns its records. A finished task may be drained by its owner.
  if(!task || !task->owner || (!task->finished && task->owner->current!=task) ||
      !(record=task->except_top)) { I386IrqRestore(flags); return FALSE; }
  if(record->signature!=I386_EXCEPT_MAGIC || record->task!=task ||
      I386HeapSize(record->heap,record)!=sizeof(CI386Except)) {
    I386IrqRestore(flags); return FALSE;
  }
  previous=record->previous;
  if(!I386HeapFree(record->heap,record)) { I386IrqRestore(flags); return FALSE; }
  task->except_top=previous;
  I386IrqRestore(flags);
  return TRUE;
}
Bool I386ExceptClear(CI386Task *task)
{
  if(!task || !task->owner || (!task->finished && task->owner->current!=task))
    return FALSE;
  while(task->except_top) if(!I386ExceptPop(task)) return FALSE;
  return TRUE;
}

//Task-context dispatch. Accepted catches resume at SysUntry and do not return.
//A returned status requires the caller's error/unhandled policy, never success.
I64 I386ExceptDispatch(CI386Task *task,I64 ch,
  U0 (*invoke)(CI386ExceptCapture *capture),
  U0 (*resume)(CI386ExceptCapture *capture))
{
  CI386Except *record;
  CI386ExceptCapture *capture;
  if(!task || !task->owner || task->owner->current!=task || task->finished ||
      !invoke || !resume) return I386_EXCEPT_INVALID;
  task->except_ch=ch; task->catch_except=FALSE;
  while(record=task->except_top) {
    if(record->signature!=I386_EXCEPT_MAGIC || record->task!=task ||
        I386HeapSize(record->heap,record)!=sizeof(CI386Except))
      return I386_EXCEPT_INVALID;
    capture=&record->capture;
    if(!capture->catch_start || !capture->untry_start ||
        !I386FrameValid(capture->ebp,task->stack_base,task->stack_size) ||
        capture->esp&3 || capture->esp<(task->stack_base+0)(U64) ||
        capture->esp>capture->ebp) return I386_EXCEPT_INVALID;
    (*invoke)(capture);
    //A catch may run balanced nested try blocks and yield. It must return
    //with the same live task and selected record, unless it exits nonlocally.
    if(!task->owner || task->owner->current!=task || task->finished ||
        task->except_top!=record) return I386_EXCEPT_INVALID;
    if(task->catch_except) {
      (*resume)(capture);
      return I386_EXCEPT_RESUME_RETURNED;
    }
    if(!I386ExceptPop(task)) return I386_EXCEPT_INVALID;
  }
  return I386_EXCEPT_UNHANDLED;
}
