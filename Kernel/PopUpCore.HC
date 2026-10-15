//Original popup execution and handoff, with optional native lifetime hooks.
#ifndef POPUP_SCOPE_LOCAL
#define POPUP_SCOPE_LOCAL
#define POPUP_SCOPE_OPEN
#define POPUP_SCOPE_ATTACH
#define POPUP_SCOPE_DETACH
#define POPUP_SCOPE_CLOSE
#endif
#ifndef POPUP_CREATE
#define POPUP_CREATE PopUpCreateCore
CTask *PopUpCreateCore(CTask *parent)
{ return Spawn(&SrvCmdLine,NULL,"Servant",-1,parent); }
#define POPUP_TASK_EXE TaskExe
#define POPUP_KILL Kill
#endif
#ifndef POPUP_FUNCTION
#define POPUP_FUNCTION PopUp
#endif
I64 POPUP_FUNCTION(U8 *buf,CTask *parent=NULL,CTask **_pu_task=NULL)
{//Execute code in $LK,"PopUp",A="MN:PopUp"$ task.
  I64 res;
  CJob *tmpc;
  CTask *task;
  POPUP_SCOPE_LOCAL;
  try {
    POPUP_SCOPE_OPEN;
    task=POPUP_CREATE(parent);
    POPUP_SCOPE_ATTACH;
  if (!parent) {
    POPUP_TASK_EXE(task,parent,buf,1<<JOBf_EXIT_ON_COMPLETE|1<<JOBf_FREE_ON_COMPLETE);
    if (_pu_task) *_pu_task=task;
    POPUP_SCOPE_DETACH;
    POPUP_SCOPE_CLOSE;
    return 0;
  } else {
    Fs->popup_task=task;
    tmpc=POPUP_TASK_EXE(task,parent,buf,1<<JOBf_WAKE_MASTER|1<<JOBf_FOCUS_MASTER);
    if (_pu_task) *_pu_task=task;
    JobResScan(tmpc,&res);
    Fs->popup_task=NULL;
    POPUP_KILL(task);
    if (_pu_task) *_pu_task=NULL;

  }
  } catch { POPUP_SCOPE_CLOSE; }
  POPUP_SCOPE_CLOSE;
  return res;
}
