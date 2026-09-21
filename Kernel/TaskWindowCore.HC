//Both callers use the original task-lock, control-update and invalidation policy.
U0 TaskWindowDerivedCore(CTask *task,U0 (*controls)(CTask *task),U0 (*invalidate)())
{
  I64 flags=GetRFlags;
  SetRFlags(flags&~0x200);
  while(LBts(&task->task_flags,TASKf_TASK_LOCK)) {}
  try {
    WinDerivedValsUpdate(task);
    if(controls) (*controls)(task);
    if(invalidate && Bt(&task->display_flags,DISPLAYf_SHOW)) (*invalidate)();
  } catch {
    //Geometry has changed even if a control callback failed.
    if(invalidate && Bt(&task->display_flags,DISPLAYf_SHOW)) (*invalidate)();
    LBtr(&task->task_flags,TASKf_TASK_LOCK);
    SetRFlags(flags);
  }
  LBtr(&task->task_flags,TASKf_TASK_LOCK);
  SetRFlags(flags);
}
