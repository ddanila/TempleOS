#include "/Kernel/DisplayFlags.HH"
I64 DocReportStateCheck()
{
  CTask *task=Fs;
  U32 irq=GetRFlags;
  I64 display=task->display_flags,flags=task->task_flags;
  I64 used=task->data_heap->used_u8s;
  Bool result;
  task->display_flags|=1<<DISPLAYf_NOT_RAW;
  task->task_flags|=1<<TASKf_INPUT_FILTER_TASK;
  DocReportLiteral(25,"Doc report\n");
  result=(GetRFlags&0x200)==(irq&0x200) &&
    task->display_flags==(display|1<<DISPLAYf_NOT_RAW) &&
    task->task_flags==(flags|1<<TASKf_INPUT_FILTER_TASK);
  SetRFlags(GetRFlags&~0x200);
  DocReportLiteral(25,"IRQ-off report\n");
  result=result && !(GetRFlags&0x200) &&
    task->display_flags==(display|1<<DISPLAYf_NOT_RAW) &&
    task->task_flags==(flags|1<<TASKf_INPUT_FILTER_TASK) && task->data_heap->used_u8s==used;
  task->display_flags=display; task->task_flags=flags;
  SetRFlags(irq);
  return result;
}
