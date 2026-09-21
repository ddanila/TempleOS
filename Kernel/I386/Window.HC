#include "/Kernel/WinGeometry.HC"
#include "/Kernel/WinScroll.HC"
#include "/Adam/Gr/GrTextRect.HC"
U0 WinDerivedValsUpdate(CTask *task)
{//As in the original kernel, the caller owns TASKf_TASK_LOCK.
  U32 flags;
  if(!task) task=Fs;
  flags=I386IrqSave;
  WinGeometryCore(task);
  I386IrqRestore(flags);
}
