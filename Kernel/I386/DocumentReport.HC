#include "/Kernel/DisplayFlags.HH"
#include "/Kernel/I386/Timer.HH"
#include "/Kernel/I386/ConsolePitRead.HC"
U8 native_report_pending[2048];
I64 native_report_pending_length;
CTask *native_report_pending_task;
U0 NativeReportFlush()
{
  if(native_report_pending_task==Fs && native_report_pending_length &&
      GetRFlags&0x200)
    NativeTerminalDiagnosticRecord(native_report_pending);
  native_report_pending_length=0;native_report_pending_task=NULL;
}
U0 DocReportLiteral(I64 mS,U8 *message)
{//Keep the direct, allocation-free display path for IRQ-off reports.
  CTask *task=Fs;
  U32 irq;
  I64 index=0;
  //Retain reports without allocating inside the guest call, including with
  //IRQs disabled. The answer callback appends after the caller's heap check.
  if(message) {
    if(native_report_pending_task!=task)native_report_pending_length=0;
    native_report_pending_task=task;
    while(message[index] && native_report_pending_length<sizeof(native_report_pending)-1)
      native_report_pending[native_report_pending_length++]=message[index++];
    native_report_pending[native_report_pending_length]=0;
  }
  irq=I386IrqSave;
  Bool filtered=LBtr(&task->task_flags,TASKf_INPUT_FILTER_TASK);
  Bool windowed=LBtr(&task->display_flags,DISPLAYf_NOT_RAW);
  I64 previous,current,delta,remaining=0;
  I386TextWrite(&console_text,message); ConsolePresent;
  if(mS>0) remaining=(mS*I386_PIT_FREQUENCY+999)/1000;
  previous=NativeRandPitRead;
  while(remaining>0) {
    current=NativeRandPitRead;
    delta=previous-current;
    if(delta<0) delta+=console_config->pit_divisor;
    remaining-=delta; previous=current;
  }
  if(filtered) LBts(&task->task_flags,TASKf_INPUT_FILTER_TASK);
  if(windowed) LBts(&task->display_flags,DISPLAYf_NOT_RAW);
  I386IrqRestore(irq);
}

U0 UndefinedDefine(U8 *name)
{//Keep the original diagnostic text and exception without interpreting the name.
  KernelLog("UNDEFINED DEFINE "); KernelLog(name); KernelLog("\n");
  DocReportLiteral(0,"ERROR: Undefined Define: '");
  DocReportLiteral(0,name);
  DocReportLiteral(0,"'.\n");
  throw('UndefDef');
}
