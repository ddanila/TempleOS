#include "/Kernel/WindowInhibitFlags.HH"
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

#include "/Kernel/DisplayFlags.HH"
#include "/Kernel/ControlTypes.HH"
#include "/Kernel/TaskValidate.HC"
#include "/Kernel/WinInside.HC"
#include "/Adam/Ctrls/CtrlsCore.HC"
Bool native_window_dirty;
CTask *graphics_owner;
U0 NativeWindowInvalidate() { native_window_dirty=TRUE; }
extern U0 TaskDerivedValsUpdate(CTask *task=NULL,Bool update_z_buf=TRUE);
#include "/Kernel/WinSize.HC"
U16 *MemSetU16(U16 *dst,I64 value,I64 count)
{
  I64 i;
  asm { CLD }
  for(i=0;i<count;i++) dst[i]=value;
  return dst+count;
}
#include "/Adam/Gr/GrWindowVisibility.HC"
U0 WinZBufUpdate()
{//Window order and visibility use the same public window-manager anchor.
  //The single-CPU scheduler is cooperative; this retained path never yields.
  //Keyboard/timer IRQs may run without changing the public task ring.
  if(!graphics_owner || !gr.win_z_buf || !TaskValidate(sys_winmgr_task)) return;
  WindowVisibilityCore(sys_winmgr_task);
  native_window_dirty=FALSE;
}

#include "/Adam/Gr/GrPixelCoverageCore.HC"
Bool IsPixCovered0(CTask *task,I64 x,I64 y)
{//Original unsigned window-cell visibility comparison, without clipping.
  return GrPixelCoveredCore(task,x,y);
}
