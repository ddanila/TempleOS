#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/KbcInput.HH"
#include "/Kernel/I386/Irq.HH"
extern U0 I386PicInit();
extern U0 I386PicMask(U16 mask);
extern Bool I386PicAccept(I64 irq);
extern Bool I386PicEoi(I64 irq);
class CDispatch { U0 (*handler)(CI386IrqFrame *frame); };
class CControl {
  CDispatch *irq; U0 (*idle)(); I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs); U8 *task_descriptor,*cpu_descriptor;
};
CI386Scheduler scheduler;
CI386Task tasks[3];
CI386KbcInput input,uninitialized;
CControl *control;
U32 errors,received,interrupts,competitors;
extern U0 Reader(I64 id);
extern U0 EndTask();
extern U0 OnKeyboard(CI386IrqFrame *frame);
I64 Main(I64 a,I64 b)
{
  U0 (*swap)(CI386Context *old,CI386Context *next);
  U8 config,data=0x55,status=0xAA;
  I64 i;
  control=a; swap=b;
  I386PicInit;
  if (!I386SchedInit(&scheduler,&tasks[0],swap) ||
      I386KbcInputInit(0,&scheduler) || I386KbcInputInit(&input,0) ||
      !I386KbcInputInit(&input,&scheduler) || I386KbcInputInit(&input,&scheduler)) return 1;
  if (I386KbcInputPut(&uninitialized,1,1) ||
      I386KbcInputRead(&uninitialized,&data,&status) ||
      I386KbcInputRead(&input,&data,&status) || data!=0x55 || status!=0xAA) return 2;
  if (!I386KbcInputPut(&input,0x33,0xE1) ||
      I386KbcInputRead(&input,0,&status) || I386KbcInputRead(&input,&data,0) ||
      I386KbcInputRead(&input,&data,&data) || input.queue.count!=1) return 3;
  for (i=1;i<=2;i++)
    if (!I386ContextInit(&tasks[i].context,0x50000+i*8192,8192,&Reader,i,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[i])) return 4;
  if (!I386SchedYield(&scheduler) || errors || !tasks[1].blocked ||
      !tasks[2].finished || competitors!=1 || input.waiter!=&tasks[1]) return 5;
  //An unrelated wake must return to waiting without consuming phantom data.
  if (!I386SchedWake(&scheduler,&tasks[1]) || !I386SchedYield(&scheduler) ||
      !tasks[1].blocked || received || errors) return 6;
  if (!I386KbcDrain || !I386KbcWrite(TRUE,0x20) ||
      !I386KbcReadWait(&config,&status) || (status&0xE0) ||
      !I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,(config|1)&~0x10)) return 7;
  I386PicInit; control->irq->handler=&OnKeyboard;
  for (i=0;i<4;i++) {
    if (!tasks[1].blocked || !I386KbcWrite(FALSE,0xEE)) return 8;
    I386PicMask(0xFFFD);
    if (!I386SchedIdle(&scheduler,control->idle) || (GetRFlags&0x200)) return 9;
    I386PicMask(0xFFFF);
    if (tasks[1].blocked || scheduler.current!=&tasks[0] ||
        interrupts!=i+1 || input.queue.count!=1 || received!=i) return 10;
    //A second publication while the reader is runnable must remain queued.
    if (!I386KbcInputPut(&input,0x40+i,0xA1) || input.queue.count!=2) return 14;
    //Root cannot steal a byte reserved for the registered reader.
    data=0x55; status=0xAA;
    if (I386KbcInputRead(&input,&data,&status,FALSE) || data!=0x55 || status!=0xAA ||
        !I386SchedYield(&scheduler) || received!=i+1 || errors) return 11;
  }
  if (!tasks[1].finished || input.waiter || input.queue.count || input.queue.dropped ||
      !I386SchedReap(&scheduler,&tasks[1]) || !I386SchedReap(&scheduler,&tasks[2])) return 12;
  if (!I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,config) ||
      !I386KbcWrite(TRUE,0x20) || !I386KbcReadWait(&data,&status) || data!=config ||
      (status&0xE0)) return 13;
  return errors;
}
U0 Reader(I64 id)
{
  U8 data=0x55,status=0xAA;
  I64 i;
  SetRFlags(GetRFlags|0x200);
  if (id==2) {
    if (I386KbcInputRead(&input,&data,&status) || data!=0x55 || status!=0xAA ||
        !(GetRFlags&0x200)) errors++;
    competitors++; return;
  }
  if (!I386KbcInputRead(&input,&data,&status) || data!=0x33 || status!=0xE1 ||
      I386KbcInputRead(&input,&data,&status,FALSE) || !(GetRFlags&0x200)) errors++;
  for (i=0;i<4;i++) {
    if (!I386KbcInputRead(&input,&data,&status) || data!=0xEE || (status&0xE0) ||
        !(GetRFlags&0x200) || scheduler.current!=&tasks[1] || input.waiter) errors++;
    if (!I386KbcInputRead(&input,&data,&status) || data!=0x40+i || status!=0xA1 ||
        !(GetRFlags&0x200)) errors++;
    received++;
  }
}
U0 EndTask() { I386SchedFinish(&scheduler); while (TRUE) {} }
U0 OnKeyboard(CI386IrqFrame *frame)
{
  U8 data,status;
  if (!I386PicAccept(frame->irq)) return;
  if (frame->irq!=1 || (GetRFlags&0x600) || !(frame->eflags&0x200) ||
      scheduler.current!=&tasks[0]) errors++;
  if (!I386KbcRead(&data,&status) || !I386KbcInputPut(&input,data,status) ||
      scheduler.current!=&tasks[0] || (GetRFlags&0x200)) errors++;
  interrupts++; I386PicEoi(frame->irq);
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/KbcQueue.HC"
#include "/Kernel/I386/KbcInput.HC"
#include "/Kernel/I386/Kbc.HC"
#include "/Kernel/I386/PicPit.HC"
