#include "/Kernel/I386/ExceptRuntime.HH"
//Install once during bootstrap. Callbacks and FS task binding must remain live.
CI386ExceptServices i386_except_services;
U32 i386_except_ready;
Bool I386ExceptInstall(CI386ExceptServices *services)
{
  U32 flags=I386IrqSave;
  if(i386_except_ready || !services || !services->invoke || !services->resume ||
      !services->report || !services->fatal) {
    I386IrqRestore(flags); return FALSE;
  }
  i386_except_services.invoke=services->invoke;
  i386_except_services.resume=services->resume;
  i386_except_services.report=services->report;
  i386_except_services.fatal=services->fatal;
  i386_except_ready=TRUE;
  I386IrqRestore(flags);
  return TRUE;
}
U0 I386ExceptAbort(CI386Task *task,I64 status,I64 ch)
{
  if(i386_except_ready) (*i386_except_services.fatal)(task,status,ch);
  //A broken/missing fatal service must never continue the failed operation.
  I386IrqSave;
  while(1) {}
}
Bool I386ExceptEnter(CI386ExceptCapture *capture)
{
  CI386Task *task=I386TaskSelf;
  if(!i386_except_ready || !task || !task->owner ||
      task->owner->current!=task || task->finished || !task->memory ||
      !capture || !capture->catch_start || !capture->untry_start ||
      !I386FrameValid(capture->ebp,task->stack_base,task->stack_size) ||
      capture->esp&3 || capture->esp<(task->stack_base+0)(U64) ||
      capture->esp>capture->ebp) I386ExceptAbort(task,I386_EXCEPT_INVALID,0);
  return I386ExceptPush(task,task->memory,capture)!=0;
}
U0 SysUntry()
{
  CI386Task *task=I386TaskSelf;
  if(!i386_except_ready || !I386ExceptPop(task))
    I386ExceptAbort(task,I386_EXCEPT_INVALID,0);
}
U0 throw(I64 ch=0,Bool no_log=FALSE)
{
  CI386Task *task=I386TaskSelf;
  I64 status,i;
  CI386Frame *frame=GetRBP;
  if(!i386_except_ready || !task || !task->owner ||
      task->owner->current!=task || task->finished)
    I386ExceptAbort(task,I386_EXCEPT_INVALID,ch);
  task->except_ch=ch; task->catch_except=FALSE;
  task->except_rbp=frame;
  for(i=0;i<I386_EXCEPT_CALLERS;i++) {
    task->except_callers[i]=I386FrameReturn(frame,task->stack_base,task->stack_size);
    frame=I386FrameParent(frame,task->stack_base,task->stack_size);
  }
  if(!no_log) (*i386_except_services.report)(task,ch);
  status=I386ExceptDispatch(task,ch,i386_except_services.invoke,
    i386_except_services.resume);
  I386ExceptAbort(task,status,ch);
}
U0 I386ExceptRegistrationFailed() { throw('OutMem',TRUE); }
