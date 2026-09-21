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
#include "/Kernel/TaskWindowCore.HC"
Bool native_window_dirty;
CTask *graphics_owner;
U0 NativeWindowInvalidate() { native_window_dirty=TRUE; }
U0 TaskDerivedValsUpdate(CTask *task=NULL,Bool update_z_buf=TRUE)
{
  if(!task) task=Fs;
  if(update_z_buf) TaskWindowDerivedCore(task,&CtrlsUpdate,&NativeWindowInvalidate);
  else TaskWindowDerivedCore(task,&CtrlsUpdate,NULL);
}
#include "/Kernel/WinSize.HC"
U16 *MemSetU16(U16 *dst,I64 value,I64 count)
{
  I64 i;
  for(i=0;i<count;i++) dst[i]=value;
  return dst;
}
#include "/Adam/Gr/GrWindowVisibility.HC"
U0 WinZBufUpdate()
{//The console presentation owner anchors the native public task ring.
  //The single-CPU scheduler is cooperative; this retained path never yields.
  //Keyboard/timer IRQs may run without changing the public task ring.
  if(!graphics_owner || !gr.win_z_buf) return;
  WindowVisibilityCore(graphics_owner);
  native_window_dirty=FALSE;
}
