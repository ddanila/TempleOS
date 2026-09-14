#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/ExceptRuntime.HH"
#include "/Kernel/I386/Debug.HH"
class CControl {
  U8 *irq,*idle;
  I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs);
  U8 *task_descriptor,*cpu_descriptor;
  U0 (*invoke)(CI386ExceptCapture *capture);
  U0 (*resume)(CI386ExceptCapture *capture);
};
CControl *control;
U0 (*swap_context)(CI386Context *old,CI386Context *next);
CI386Scheduler scheduler;
CI386Task root;
CI386Cpu cpu;
CI386Heap heap;
CI386OwnedTask *workers[2];
U32 failures,progress[2],reports[2];
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
extern I64 Run();
extern U0 Bind(CI386Task *task);
extern U0 Worker(I64 id);
extern U0 Report(CI386Task *task,I64 ch);
extern U0 Fatal(CI386Task *task,I64 status,I64 ch);
I64 Main(CControl *arg,U0 (*swap)(CI386Context *old,CI386Context *next))
{
  CI386ExceptServices services;
  control=arg; swap_context=swap;
  root.addr=&root; cpu.addr=&cpu; cpu.scheduler=&scheduler;
  if(!I386DataSegment(control->task_descriptor,&root,sizeof(root)) ||
      !I386DataSegment(control->cpu_descriptor,&cpu,sizeof(cpu))) return 1;
  services.invoke=control->invoke; services.resume=control->resume;
  services.report=&Report; services.fatal=&Fatal;
  if(!I386ExceptInstall(&services)) return 2;
  return (*control->segments)((&Run+0)(U64));
}
I64 Run()
{
  I64 cycle,i,round;
  if(!I386SchedInit(&scheduler,&root,swap_context) ||
      !I386SchedSetBind(&scheduler,&Bind) ||
      !I386HeapInit(&heap,0x40000,32768)) return 3;
  for(cycle=0;cycle<2;cycle++) {
    for(i=0;i<2;i++) {
      progress[i]=0; reports[i]=0;
      workers[i]=I386TaskSpawn(&scheduler,&heap,8192,&Worker,i,0x18,0x20,4096);
      if(!workers[i]) return 4;
    }
    for(round=0;round<40;round++) {
      if(!I386SchedYield(&scheduler) || I386TaskSelf!=&root) return 5;
      if(workers[0]->task.finished && workers[1]->task.finished) break;
    }
    for(i=0;i<2;i++) {
      if(!workers[i]->task.finished || progress[i]!=4 || reports[i]!=8 ||
          workers[i]->task.except_top || workers[i]->local_heap.used ||
          !I386TaskDestroy(workers[i])) return 6;
    }
    if(failures || heap.used || heap.allocations || !I386HeapValid(&heap)) return 7;
  }
  return 0;
}
U0 Bind(CI386Task *task)
{
  if(GetRFlags&0x200 || scheduler.current!=task ||
      !I386DataSegment(control->task_descriptor,task,sizeof(CI386Task))) failures++;
  (*control->reload)(0x18,0x20);
  if(I386TaskSelf!=task) failures++;
}
U0 Worker(I64 id)
{
  CI386Task *task=I386TaskSelf;
  CI386Except *selected;
  U8 *site,*throw_frame;
  I64 i,value=0x1234567800000000+id,ch;
  for(i=0;i<4;i++) {
    ch=0x100000000+id*16+i;
    try { throw(ch); failures++; }
    catch {
      selected=task->except_top;
      site=task->except_callers[0]; throw_frame=task->except_rbp;
      if(!site || !I386FrameValid(throw_frame,task->stack_base,task->stack_size))
        failures++;
      if(task->except_ch!=ch || task->memory->allocations!=1) failures++;
      task->catch_except=TRUE;
      I386SchedYield(&scheduler);
      if(I386TaskSelf!=task || task->except_top!=selected || !task->catch_except ||
          task->except_ch!=ch || task->except_callers[0]!=site ||
          task->except_rbp!=throw_frame || value!=0x1234567800000000+id+i*3) failures++;
      value++;
    }
    if(task->except_top || task->memory->used) failures++;
    try {
      try { throw(ch+0x200000000); failures++; }
      catch {
        selected=task->except_top;
        if(task->memory->allocations!=2) failures++;
        I386SchedYield(&scheduler);
        if(I386TaskSelf!=task || task->except_top!=selected || task->catch_except ||
            task->except_ch!=ch+0x200000000) failures++;
        value++;
      }
      failures++;
    } catch {
      selected=task->except_top;
      task->catch_except=TRUE;
      if(task->memory->allocations!=1) failures++;
      I386SchedYield(&scheduler);
      if(I386TaskSelf!=task || task->except_top!=selected || !task->catch_except ||
          task->except_ch!=ch+0x200000000) failures++;
      value++;
    }
    if(value!=0x1234567800000000+id+(i+1)*3 || task->except_top ||
        task->memory->used || !I386HeapValid(task->memory)) failures++;
    progress[id]++;
  }
}
U0 Report(CI386Task *task,I64 ch)
{
  I64 id,i;
  U8 *frame=GetRBP;
  if((task->except_rbp+0)(U64)!=*frame(U32 *)) failures++;
  for(i=0;i<I386_EXCEPT_CALLERS;i++)
    if(task->except_callers[i]!=Caller(i+2)) failures++;
  if(task!=I386TaskSelf || task->except_ch!=ch) failures++;
  for(id=0;id<2;id++) if(task==&workers[id]->task) reports[id]++;
}
U0 Fatal(CI386Task *task,I64 status,I64 ch)
{
  failures++;
  while(1) {}
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
#include "/Kernel/I386/ExceptRuntime.HC"
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Task.HC"
#include "/Kernel/I386/Segments.HC"

#include "/Kernel/I386/Debug.HC"
