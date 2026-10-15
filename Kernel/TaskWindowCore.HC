#ifndef TASK_DERIVED_SCOPE_LOCAL
#define TASK_DERIVED_SCOPE_LOCAL
#define TASK_DERIVED_SCOPE_OPEN
#define TASK_DERIVED_SCOPE_CLOSE
#endif
U0 TaskWindowDerivedRelease(CTask *task,I64 flags,Bool *locked)
{
  if(*locked) {
    *locked=FALSE;
    LBtr(&task->task_flags,TASKf_TASK_LOCK);
  }
  SetRFlags(flags);
}
//Both callers use the original task-lock, control-update and invalidation policy.
U0 TaskWindowDerivedCore(CTask *task,U0 (*controls)(CTask *task),U0 (*invalidate)())
{
  I64 flags=GetRFlags;
  Bool locked=FALSE;
  TASK_DERIVED_SCOPE_LOCAL;
  try {
    TASK_DERIVED_SCOPE_OPEN;
    SetRFlags(flags&~0x200);
    while(LBts(&task->task_flags,TASKf_TASK_LOCK)) {}
    locked=TRUE;
    WinDerivedValsUpdate(task);
    if(controls) (*controls)(task);
    if(invalidate && Bt(&task->display_flags,DISPLAYf_SHOW)) (*invalidate)();
    TaskWindowDerivedRelease(task,flags,&locked);
    TASK_DERIVED_SCOPE_CLOSE;
  } catch {
    //Geometry has changed even if a control callback failed.
    if(locked && invalidate && Bt(&task->display_flags,DISPLAYf_SHOW)) (*invalidate)();
    TaskWindowDerivedRelease(task,flags,&locked);
    TASK_DERIVED_SCOPE_CLOSE;
  }
}
