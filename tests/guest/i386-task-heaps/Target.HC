#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
class CTaskTestControl {
  U8 *irq;
  U0 (*idle)();
  I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs);
  U8 *task_descriptor,*cpu_descriptor;
};
CTaskTestControl *test_control;
CI386Scheduler scheduler;
CI386Task root;
CI386Cpu bound_cpu;
U32 errors;
U0 (*swap)(CI386Context *old,CI386Context *next);
extern U0 BindTask(CI386Task *task);
extern I64 PublicTaskHeapTest();
extern I64 RunHeapTasks();
I64 Main(I64 a,I64 b)
{
  swap=b;
  test_control=a;
  return (*test_control->segments)(&RunHeapTasks);
}
I64 RunHeapTasks()
{
  //Exercise IF preservation with hardware IRQs masked; the task suite tests delivery.
  OutU8(0x21,0xFF); OutU8(0xA1,0xFF);
  if(!I386SchedInit(&scheduler,&root,swap)) return 1;
  bound_cpu.addr=&bound_cpu; bound_cpu.scheduler=&scheduler;
  if(!I386DataSegment(test_control->cpu_descriptor,&bound_cpu,sizeof(CI386Cpu)) ||
      !I386SchedSetBind(&scheduler,&BindTask) || I386TaskSelf!=&root) return 2;
  return PublicTaskHeapTest;
}
U0 BindTask(CI386Task *task)
{
  if(GetRFlags&0x200 || task->addr!=task || scheduler.current!=task ||
      !I386DataSegment(test_control->task_descriptor,task,sizeof(CI386Task))) errors++;
  (*test_control->reload)(0x18,0x20);
  if(I386TaskSelf!=task) errors++;
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/SchedulerCore.HC"
#include "/Kernel/I386/TaskLifetime.HC"
#include "T:/PublicHeaps.HC"
