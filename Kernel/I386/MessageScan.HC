//Public job-backed message consumption. Include after JobDispatch.HC.
#include "/Kernel/MessageCodes.HH"
I64 MemoryScanMsg(I64 *arg1=0,I64 *arg2=0,I64 mask=~1,CTask *task=0)
{
  U32 old_flags=I386IrqSave;
  CJob *job,*head;
  I64 code,a,b;
  if(!task) task=I386TaskSelf;
  head=&task->srv_ctrl.next_waiting;
  while(TRUE) {
    I386IrqSave;
    if(task==I386TaskSelf) MemoryJobsHndlr(old_flags,task);
    job=head->next;
    if(job==head) break;
    if(job->job_code==JOBT_MSG) {
      MemoryJobRemove(job);
      I386IrqRestore(old_flags);
      code=job->msg_code; a=job->aux1; b=job->aux2;
      if(arg1) *arg1=a;
      if(arg2) *arg2=b;
      //Capture both arguments before freeing; original uses aux2 after JobDel.
      MemoryFree(job->aux_str); MemoryFree(job);
      //Original SCf_KEY_DESC is scan bit 31; WIf_SELF_KEY_DESC is inhibit bit 12.
      if((code!=MSG_KEY_DOWN || !(b&(1<<31)) ||
          !(task->win_inhibit&(1<<12))) && ((mask>>code)&1)) {
        I386IrqRestore(old_flags);
        return code;
      }
    }
    I386IrqRestore(old_flags);
  }
  if(arg1) *arg1=0;
  if(arg2) *arg2=0;
  I386IrqRestore(old_flags);
  if(task->parent_task && task->parent_task->popup_task==task)
    return MemoryScanMsg(arg1,arg2,mask,task->parent_task);
  return MSG_NULL;
}
I64 MemoryFlushMsgs(CTask *task=0)
{
  I64 count=0,a,b;
  while(MemoryScanMsg(&a,&b,~1,task)) count++;
  return count;
}
I64 MemoryGetMsg(I64 *arg1=0,I64 *arg2=0,I64 mask=~1,CTask *task=0)
{
  I64 code;
  if(!task) task=I386TaskSelf;
  task->task_flags&=~(1<<TASKf_IDLE);
  while(!(code=MemoryScanMsg(arg1,arg2,mask,task))) {
    task->task_flags|=1<<TASKf_IDLE;
    Yield;
  }
  task->task_flags&=~(1<<TASKf_IDLE);
  return code;
}
