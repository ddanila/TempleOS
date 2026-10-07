//Public job-backed messages. Include after the task lifetime and heap provider.
#include "/Kernel/NumericLimits.HH"
#include "/Kernel/MessageCodes.HH"
#define TaskValidate MemoryTaskValidate
#include "/Kernel/TaskValidate.HC"
U0 MemoryMessageWake(CTask *task)
{
  while(task && MemoryTaskValidate(task)) {
    task->task_flags&=~(1<<TASKf_AWAITING_MSG);
    task=task->popup_task;
  }
}
class CI386TimedMessageJob:CJob { I64 arrival_jiffy; U64 timing_signature; };
CJob *MemoryMessageNew(CTask *master,I64 msg_code,I64 arg1,I64 arg2,I64 flags)
{
  CI386TimedMessageJob *job=MemoryCAlloc(sizeof(CI386TimedMessageJob),memory_root);
  job->arrival_jiffy=-1; job->timing_signature=0x54494D454B455931;
  job->master_task=master; job->job_code=JOBT_MSG;
  job->msg_code=msg_code;
  if(msg_code<0) job->msg_code=-msg_code;
  job->aux1=arg1; job->aux2=arg2; job->flags=flags;
  return job;
}
CJob *MemoryTaskMsg(CTask *target,CTask *master,
  I64 msg_code,I64 arg1,I64 arg2,I64 flags)
{
  CTask *task=target;
  CJob *job=0,*last,*copy;
  U32 irq;
  if(!MemoryTaskValidate(task) || master && !MemoryTaskValidate(master) ||
      task->popup_task && !(task->task_flags&(1<<TASKf_FILTER_INPUT))) return 0;
  //Match original TaskMsg: record only positive key-down, before filtering.
  if((memory_semas[SEMA_RECORD_MACRO].val&1) &&
      target!=memory_macro_task && msg_code==MSG_KEY_DOWN) {
    try {
      //Registration itself can fail: allocate nothing until it has succeeded.
      job=MemoryMessageNew(master,msg_code,arg1,arg2,flags);
      copy=MemoryIdent(job,memory_root);
    }
    catch {
      //The job has not entered either ring. Release it before propagation;
      //leaving catch_except clear preserves the original allocation exception.
      MemoryFree(job);
    }
    irq=I386IrqSave;
    last=memory_macro_head.last;
    copy->last=last; copy->next=last->next;
    last->next->last=copy; last->next=copy;
    I386IrqRestore(irq);
  } else job=MemoryMessageNew(master,msg_code,arg1,arg2,flags);
  irq=I386IrqSave;
  while(task->task_flags&(1<<TASKf_FILTER_INPUT) && !(flags&(1<<JOBf_DONT_FILTER)))
    task=task->next_input_filter_task;
  job->ctrl=&task->srv_ctrl;
  while(task->srv_ctrl.flags&(1<<JOBCf_LOCKED)) {}
  task->srv_ctrl.flags|=1<<JOBCf_LOCKED;
  if(!MemoryTaskValidate(task)) {
    task->srv_ctrl.flags&=~(1<<JOBCf_LOCKED);
    MemoryFree(job); job=0;
  } else {
    task->task_flags&=~(1<<TASKf_IDLE);
    MemoryMessageWake(task);
    last=task->srv_ctrl.last_waiting;
    job->last=last; job->next=last->next;
    last->next->last=job; last->next=job;
    task->srv_ctrl.flags&=~(1<<JOBCf_LOCKED);
  }
  I386IrqRestore(irq);
  if(msg_code<0) MemoryTaskMsg(target,master,-msg_code+1,arg1,arg2,flags);
  return job;
}
CJob *MemoryPostMsgCore(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags)
{
  if(!MemoryTaskValidate(task)) return 0;
  if(task->task_flags&(1<<TASKf_INPUT_FILTER_TASK))
    return MemoryTaskMsg(task->last_input_filter_task,0,msg_code,arg1,arg2,
      flags|1<<JOBf_DONT_FILTER);
  return MemoryTaskMsg(task,0,msg_code,arg1,arg2,flags);
}
U0 MemoryPostMsg(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags=0)
{
  MemoryPostMsgCore(task,msg_code,arg1,arg2,flags);
}
U0 MemoryPostKeyTimed(CTask *task,I64 code,I64 a,I64 b,I64 flags,I64 arrival)
{//Use the same public filtering path; attach time before a consumer can run.
  U32 irq=I386IrqSave;
  CI386TimedMessageJob *job;
  try {
    job=MemoryPostMsgCore(task,code,a,b,flags);
    if(job) job->arrival_jiffy=arrival;
  } catch { I386IrqRestore(irq); }
  I386IrqRestore(irq);
}
U0 MemoryMsg(I64 msg_code,I64 arg1,I64 arg2,I64 flags=0)
{
  MemoryPostMsg(I386TaskSelf,msg_code,arg1,arg2,flags);
}

Bool MemorySuspend(CTask *task=0,Bool state=TRUE)
{//Return the previous bit, preserving the original public contract.
  Bool result=FALSE;
  U32 irq=I386IrqSave;
  if(!task) task=I386TaskSelf;
  if(MemoryTaskValidate(task)) {
    result=(task->task_flags&(1<<TASKf_SUSPENDED))!=0;
    if(state) task->task_flags|=1<<TASKf_SUSPENDED;
    else task->task_flags&=~(1<<TASKf_SUSPENDED);
  }
  I386IrqRestore(irq);
  return result;
}
Bool MemoryIsSuspended(CTask *task=0)
{
  if(!task) task=I386TaskSelf;
  if(MemoryTaskValidate(task))
    return (task->task_flags&(1<<TASKf_SUSPENDED))!=0;
  return FALSE;
}
