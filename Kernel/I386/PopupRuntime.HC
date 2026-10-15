//Real servant execution over the existing task/job providers.
class CNativePopupScope:CNativeRenderScope {
  CTask *child,*previous;
  CTask **output;
  I64 child_num,previous_num;
  Bool synchronous;
};
U0 NativePopupRelease(CNativeRenderScope *base)
{
  CNativePopupScope *scope=base;
  CTask *child=scope->child,*previous=scope->previous;
  scope->child=NULL;
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
U0 NativePopupEntry(U8 *data) { NativeSrvCmdLine(0); }
CTask *NativePopupSpawn(CTask *parent)
{
  return (*native_user_providers.spawn)(&NativePopupEntry,NULL,"Servant",-1,parent,0,256);
}
U0 NativePopupKill(CTask *task)
{ (*native_user_providers.kill)(task,TRUE,FALSE); }
#define POPUP_CREATE NativePopupSpawn
#define POPUP_TASK_EXE NativeTaskExe
#define POPUP_KILL NativePopupKill
#define POPUP_SCOPE_LOCAL CNativePopupScope popup_scope;Bool popup_opened=FALSE
#define POPUP_SCOPE_OPEN NativePopupOpen(&popup_scope,parent,_pu_task);popup_opened=TRUE
#define POPUP_SCOPE_ATTACH popup_scope.child=task;popup_scope.child_num=task->task_num
#define POPUP_SCOPE_DETACH popup_scope.child=NULL
#define POPUP_SCOPE_CLOSE NativePopupClose(&popup_scope,&popup_opened)
#define POPUP_FUNCTION NativePopUp
#include "/Kernel/PopUpCore.HC"
