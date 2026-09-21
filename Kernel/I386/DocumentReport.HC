#include "/Kernel/DisplayFlags.HH"
#include "/Kernel/I386/Timer.HH"
#include "/Kernel/I386/PitRead.HC"
U0 DocReportLiteral(I64 mS,U8 *message)
{//Direct native display, with no formatter/document dependency or allocation.
  CTask *task=Fs;
  U32 irq=I386IrqSave;
  Bool filtered=LBtr(&task->task_flags,TASKf_INPUT_FILTER_TASK);
  Bool windowed=LBtr(&task->display_flags,DISPLAYf_NOT_RAW);
  I64 previous,current,delta,remaining=0;
  I386TextWrite(&console_text,message); ConsolePresent;
  if(mS>0) remaining=(mS*I386_PIT_FREQUENCY+999)/1000;
  previous=I386PitRead;
  while(remaining>0) {
    current=I386PitRead;
    delta=previous-current;
    if(delta<0) delta+=console_config->pit_divisor;
    remaining-=delta; previous=current;
  }
  if(filtered) LBts(&task->task_flags,TASKf_INPUT_FILTER_TASK);
  if(windowed) LBts(&task->display_flags,DISPLAYf_NOT_RAW);
  I386IrqRestore(irq);
}
