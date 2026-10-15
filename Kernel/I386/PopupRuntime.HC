//Real servant execution over the existing task/job providers.
class CNativePopupScope:CNativeRenderScope {
  CTask *child,*previous;
  CTask **output;
  CJob *job;
  I64 child_num,previous_num;
  Bool synchronous;
};
U0 NativePopupRelease(CNativeRenderScope *base)
{
  CNativePopupScope *scope=base;
  CTask *child=scope->child,*previous=scope->previous;
  CJob *job=scope->job;
  U32 irq=I386IrqSave;
  scope->child=NULL;scope->job=NULL;
  if(job) {
    if(Bt(&job->flags,JOBf_DONE)) {
      QueRem(job);JobDel(job);
    } else {
      //The child still owns a queued/dispatched request. Let it free the job,
      //without publishing a late result or wake/focus change to this caller.
      job->master_task=NULL;
      job->flags|=1<<JOBf_FREE_ON_COMPLETE;
      job->flags&=~(1<<JOBf_WAKE_MASTER|1<<JOBf_FOCUS_MASTER);
    }
  }
  I386IrqRestore(irq);
  if(scope->synchronous) {
    if(previous && (!TaskValidate(previous) ||
        previous->task_num!=scope->previous_num))previous=NULL;
    scope->task->popup_task=previous;
    if(scope->output && *scope->output==child)*scope->output=NULL;
  }
  if(child && TaskValidate(child) && child->task_num==scope->child_num)
    (*native_user_providers.kill)(child,FALSE,FALSE);
}
U0 NativePopupOpen(CNativePopupScope *scope,CTask *parent,CTask **output)
{
  scope->child=scope->previous=NULL;scope->child_num=scope->previous_num=0;
  scope->job=NULL;
  scope->synchronous=parent!=NULL;scope->output=output;
  if(scope->synchronous) {
    scope->previous=Fs->popup_task;
    if(TaskValidate(scope->previous))scope->previous_num=scope->previous->task_num;
  }
  NativeRenderScopeOpen(scope,&NativePopupRelease);
}
U0 NativePopupClose(CNativePopupScope *scope,Bool *opened)
{
  if(!*opened)return;
  *opened=FALSE;NativePopupRelease(scope);NativeRenderScopeClose(scope);
}
U0 NativePopupJobReleased(CJob *job)
{//Public JobResScan/JobDel may consume the request from a callback too.
  CNativeRenderScope *base=native_render_scopes;
  U32 irq=I386IrqSave;
  while(base) {
    if(base->release==&NativePopupRelease &&
        base(CNativePopupScope *)->job==job)base(CNativePopupScope *)->job=NULL;
    base=base->next;
  }
  I386IrqRestore(irq);
}
CJob *NativePopupSubmit(CTask *srv,CTask *master,U8 *data,I64 flags)
{
  CNativeRenderScope *base=native_render_scopes;
  CJob **owned=NULL;
  while(base) {
    if(base->task==I386TaskSelf && base->release==&NativePopupRelease) {
      if(master==I386TaskSelf)owned=&base(CNativePopupScope *)->job;
      return NativeTaskExeOwned(srv,master,data,flags,owned);
    }
    base=base->next;
  }
  throw('PopupReq',TRUE);return NULL;
}
U0 NativePopupEntry(U8 *data) { NativeSrvCmdLine(0); }
CTask *NativePopupSpawn(CTask *parent)
{
  return (*native_user_providers.spawn)(&NativePopupEntry,NULL,"Servant",-1,parent,0,256);
}
U0 NativePopupKill(CTask *task)
{ (*native_user_providers.kill)(task,TRUE,FALSE); }
#define POPUP_CREATE NativePopupSpawn
#define POPUP_TASK_EXE NativePopupSubmit
#define POPUP_KILL NativePopupKill
#define POPUP_SCOPE_LOCAL CNativePopupScope popup_scope;Bool popup_opened=FALSE
#define POPUP_SCOPE_OPEN NativePopupOpen(&popup_scope,parent,_pu_task);popup_opened=TRUE
#define POPUP_SCOPE_ATTACH popup_scope.child=task;popup_scope.child_num=task->task_num
#define POPUP_SCOPE_DETACH popup_scope.child=NULL;popup_scope.job=NULL
#define POPUP_SCOPE_CLOSE NativePopupClose(&popup_scope,&popup_opened)
#define POPUP_FUNCTION NativePopUp
#include "/Kernel/PopUpCore.HC"

class CNativePopupBufferScope:CNativeRenderScope {
  U8 **buffer;
};
U0 NativePopupBufferRelease(CNativeRenderScope *base)
{
  CNativePopupBufferScope *scope=base;
  U8 *buffer=*scope->buffer;
  *scope->buffer=NULL;Free(buffer);
}
U0 NativePopupBufferOpen(CNativePopupBufferScope *scope,U8 **buffer)
{
  scope->buffer=buffer;
  NativeRenderScopeOpen(scope,&NativePopupBufferRelease);
}
U0 NativePopupBufferClose(CNativePopupBufferScope *scope,Bool *opened)
{
  if(!*opened)return;
  *opened=FALSE;NativePopupBufferRelease(scope);NativeRenderScopeClose(scope);
}
#define POPUP_PRINT_FUNCTION NativePopUpPrint
#define POPUP_PRINT_RUN NativePopUp
#define POPUP_PRINT_SCOPE_LOCAL CNativePopupBufferScope popup_buffer_scope;Bool popup_buffer_opened=FALSE
#define POPUP_PRINT_SCOPE_OPEN NativePopupBufferOpen(&popup_buffer_scope,&buf);popup_buffer_opened=TRUE
#define POPUP_PRINT_SCOPE_CLOSE NativePopupBufferClose(&popup_buffer_scope,&popup_buffer_opened)
#include "/Kernel/PopUpPrintCore.HC"
