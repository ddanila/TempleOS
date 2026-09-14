#include "/Kernel/I386/Debug.HH"
#include "/Kernel/I386/Frame.HH"
#include "/Kernel/I386/Task.HH"
//Requires current-task FS binding and live stack bounds. Link Frame once.
U8 *Caller(I64 num=1)
{
  CI386Task *task=I386TaskSelf;
  CI386Frame *frame=GetRBP;
  if(!task || num<0 || num>task->stack_size/sizeof(CI386Frame)) return 0;
  while(num--) {
    frame=I386FrameParent(frame,task->stack_base,task->stack_size);
    if(!frame) return 0;
  }
  return I386FrameReturn(frame,task->stack_base,task->stack_size);
}
