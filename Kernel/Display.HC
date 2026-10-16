#include "/Kernel/RawOutputCore.HC"

#include "/Kernel/VGAFlushCore.HC"

#include "/Kernel/WinGeometry.HC"

U0 WinDerivedValsUpdate(CTask *task)
{//Those things calculated from other variables.
  if (!task) task=Fs;
  //Assert: This is called with TASKf_TASK_LOCK set
  PUSHFD
  CLI
  WinGeometryCore(task);
  POPFD
}

#include "/Kernel/WinInside.HC"