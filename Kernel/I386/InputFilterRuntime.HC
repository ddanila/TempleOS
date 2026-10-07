//Executable InFile jobs, distinct from the terminal's raw character queue.
class CNativeInputFilter {
  CNativeInputFilter *next;
  CTask *task,*recipient;
  CJob *active;
  Bool entered,old_filter;
};
CNativeInputFilter *native_input_filters;
I64 (*native_input_jobs)(I64 run_flags,CTask *task);
U0 (*native_input_yield)();
CNativeInputFilter *NativeInputFilterFind(CTask *task)
{
  CNativeInputFilter *state=native_input_filters;
  while(state && state->task!=task) state=state->next;
  return state;
}
U0 NativeInputFilterCleanup(CI386Task *task)
{//The end callback runs before Exit unlinks the task; scheduler cleanup is a fallback.
  CNativeInputFilter *state,*previous=NULL;
  CTask *recipient;
  U32 irq=I386IrqSave;
  state=native_input_filters;
  while(state && state->task!=task) { previous=state; state=state->next; }
  if(state) {
    recipient=task->last_input_filter_task;
    if(recipient==task) recipient=state->recipient;
    if(state->entered && !state->old_filter && TaskValidate(recipient))
      LBtr(&recipient->task_flags,TASKf_FILTER_INPUT);
    task->last_input_filter_task->next_input_filter_task=task->next_input_filter_task;
    task->next_input_filter_task->last_input_filter_task=task->last_input_filter_task;
    task->last_input_filter_task=task->next_input_filter_task=task;
    if(previous) previous->next=state->next;
    else native_input_filters=state->next;
    if(state->active) JobDel(state->active);
    Free(state);
  }
  task->cleanup=NULL; task->task_end_cb=NULL;
  I386IrqRestore(irq);
}
U0 NativeInputFilterEnd()
{
  NativeInputFilterCleanup(I386TaskSelf);
}
U0 NativeInputFilterEntry(U8 *data)
{
  CNativeInputFilter *state=NativeInputFilterFind(Fs);
  CJob *job,*head=&Fs->srv_ctrl.next_waiting;
  U32 irq;
  if(!state) throw('InFilter');
  irq=I386IrqSave;
  //Original WIG_USER_TASK_DFT is WIF_SELF_KEY_DESC (bit 12).
  Fs->win_inhibit=1<<12;
  LBts(&Fs->task_flags,TASKf_INPUT_FILTER_TASK);
  state->old_filter=LBts(&Fs->last_input_filter_task->task_flags,TASKf_FILTER_INPUT);
  if(state->old_filter) LBts(&Fs->task_flags,TASKf_FILTER_INPUT);
  else LBtr(&Fs->task_flags,TASKf_FILTER_INPUT);
  state->entered=TRUE;
  I386IrqRestore(irq);
  while(TRUE) {
    irq=I386IrqSave;
    (*native_input_jobs)(irq,Fs);
    job=head->next;
    if(job==head || job->job_code!=JOBT_TEXT_INPUT) {
      I386IrqRestore(irq); break;
    }
    QueRem(job); state->active=job;
    I386IrqRestore(irq);
    try { NativeJobSource(job->aux_str); }
    catch { Fs->catch_except=TRUE; }
    irq=I386IrqSave;
    state->active=NULL; JobDel(job);
    I386IrqRestore(irq);
    I386TaskBreakPoll;
  }
  NativeInputFilterCleanup(I386TaskSelf);
}
CJob *NativeTaskText(CTask *srv,CTask *master,U8 *data,I64 flags,U8 *owned_text=NULL)
{
  CJob *job=NULL;
  CNativeInputFilter *state=NULL;
  CTask *task,*root=I386TaskSelf->owner->root;
  U32 irq;
  if(!data || !TaskValidate(srv) || master && !TaskValidate(master) ||
      srv->popup_task && !Bt(&srv->task_flags,TASKf_FILTER_INPUT)) return NULL;
  if(Bt(&flags,JOBf_HIGHEST_PRIORITY) && srv->last_input_filter_task!=srv)
    NativeTaskWait(srv);
  irq=I386IrqSave;
  try {
    if(!TaskValidate(srv) || srv(CI386Task *)->finishing) {
      I386IrqRestore(irq); return NULL;
    }
    job=CAlloc(sizeof(CJob),root);
    job->aux_str=StrNew(data,root);
    job->master_task=master; job->job_code=JOBT_TEXT_INPUT; job->flags=flags;
    task=srv->last_input_filter_task;
    if(Bt(&flags,JOBf_HIGHEST_PRIORITY) || task==srv) {
      state=CAlloc(sizeof(CNativeInputFilter),root);
      task=(*native_user_providers.spawn)(&NativeInputFilterEntry,NULL,
        "Input Filter",-1,srv,0,256);
      if(!task) throw('Task');
      state->task=task; state->recipient=srv;
      state->next=native_input_filters; native_input_filters=state;
      task->task_end_cb=&NativeInputFilterEnd;
      task(CI386Task *)->cleanup=&NativeInputFilterCleanup;
      task->next_input_filter_task=srv->next_input_filter_task;
      task->last_input_filter_task=srv;
      srv->next_input_filter_task=task;
      task->next_input_filter_task->last_input_filter_task=task;
    } else task=srv->next_input_filter_task;
    job->ctrl=&task->srv_ctrl;
    QueIns(job,task->srv_ctrl.last_waiting);
    task->task_flags&=~(1<<TASKf_IDLE|1<<TASKf_AWAITING_MSG);
    I386SchedWake(task(CI386Task *)->owner,task);
    //Commit payload ownership only after every fallible publication step.
    job->fun_arg=owned_text;
  } catch {
    if(job) JobDel(job);
    Free(state); I386IrqRestore(irq);
  }
  I386IrqRestore(irq); return job;
}
U0 InStr(U8 *fmt,...)
{
  U8 *text=StrPrintJoin(NULL,fmt,argc,argv);
  try {
    if(Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) NativeJobSource(text);
    else NativeTaskText(Fs,NULL,text,1<<JOBf_HIGHEST_PRIORITY);
  } catch { Free(text); }
  Free(text);
}
U0 XTalkStrWait(CTask *task,U8 *fmt,...)
{
  U8 *text=StrPrintJoin(NULL,fmt,argc,argv);
  try { NativeTaskText(task,NULL,text,0); }
  catch { Free(text); }
  Free(text); NativeTaskWait(task);
}

U0 InTextSubmit(U8 *st)
{//Successful return transfers the root payload to execution or job retirement.
  U8 *source=NULL;
  CJob *job;
  try {
    source=MStrPrint("\"%%s\",%d;",st);
    if(Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) {
      NativeJobSource(source);
      Free(st);
    } else {
      job=NativeTaskText(Fs,NULL,source,1<<JOBf_HIGHEST_PRIORITY,st);
      if(!job) throw('InFilter');
    }
  } catch { Free(source); }
  Free(source);
}
#define I386_IN_TEXT_SUBMIT

U8 *NativeAStrNew(U8 *text)
{//Adam is the native scheduler root; queued text outlives its submitting task.
  return StrNew(text,I386TaskSelf->owner->root);
}
#define AStrNew NativeAStrNew
#include "/Kernel/JobInCore.HC"

#include "/Kernel/I386/JobRequests.HC"
