#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define I386_TASK_NATIVE_BUILD 1
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
class CTaskTestControl {
  U8 *irq; U0 (*idle)(); I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs); U8 *task_descriptor,*cpu_descriptor;
};
CTaskTestControl *control;
U0 (*swap)(CI386Context *old,CI386Context *next);
CI386Scheduler scheduler;
CI386Task root;
CI386Cpu cpu;
_intern 0x17 CI386Cpu *Gs();
U32 stage,errors,fail_destroy,kill_flags;
I64 kill_wake;
Bool FileCloneStub(CI386Task *source,CI386Task *target,CI386Heap *heap) { return FALSE; }
Bool FileDestroyFault(CI386Task *task)
{
  if(fail_destroy) { fail_destroy--; return FALSE; }
  task->file_state=0; task->file_clone=0; task->file_destroy=0;
  return TRUE;
}
extern U0 Worker(I64 arg);
extern U0 Creator(I64 arg);
CI386OwnedTask *orphan;
extern Bool TaskRuntimeTaskDiscard(CI386OwnedTask *owned);
extern U0 BindTask(CI386Task *task);
extern I64 RetainedTest(CI386Heap *heap);
extern I64 InitAndRun();
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/SchedulerCore.HC"
I64 Main(I64 a,I64 b)
{
  control=a; swap=b;
  return (*control->segments)(&InitAndRun);
}
I64 InitAndRun()
{
  CI386Heap heap;
  if(!I386HeapInit(&heap,0x60000,32768) ||
      !I386SchedInit(&scheduler,&root,swap)) return 1;
  cpu.addr=&cpu; cpu.scheduler=&scheduler;
  if(!I386DataSegment(control->cpu_descriptor,&cpu,sizeof(CI386Cpu)) ||
      !I386SchedSetBind(&scheduler,&BindTask)) return 2;
  return RetainedTest(&heap);
}
U0 BindTask(CI386Task *task)
{
  if(GetRFlags&0x200 || scheduler.current!=task || task->addr!=task ||
      !I386DataSegment(control->task_descriptor,task,sizeof(CI386Task))) errors++;
  (*control->reload)(0x18,0x20);
  if(I386TaskSelf!=task || (Gs+0)(U8 *)!=&cpu) errors++;
}
Bool CoreYield() { return I386SchedYield(&scheduler); }
U0 Worker(I64 arg)
{
  CI386Task *task=I386TaskSelf;
  U8 *p;
  if(arg!=0x123456780000002A || !task || task==&root ||
      task->owner!=&scheduler || scheduler.current!=task) { errors++; return; }
  if(kill_flags && (task->task_flags!=kill_flags || task->wake_jiffy!=kill_wake)) errors++;
  p=I386HeapAlloc(task->memory,128,TRUE);
  if(!p) { errors++; return; }
  p[0]=0xA7; stage=1;
  CoreYield;
  if(I386TaskSelf!=task || p[0]!=0xA7) errors++;
  if(kill_flags && (task->task_flags!=kill_flags || task->wake_jiffy!=kill_wake)) errors++;
  stage=2;
  //Owned teardown must reclaim the deliberately live private allocation.
}
#include "/Kernel/I386/TaskRuntimeCore.HC"
I64 RetainedTest(CI386Heap *heap)
{
  I64 cycle,j;
  CI386OwnedTask *pending;
  for(cycle=0;cycle<20;cycle++) {
    stage=0;
    pending=TaskRuntimeTaskCreateFrom(&scheduler,heap,&root,8192,
        &Worker,0x123456780000002A,0x18,0x20,4096);
    if(!pending || pending->task.next_task!=&pending->task ||
        pending->task.last_task!=&pending->task || pending->task.owner!=&scheduler ||
        pending->task.next || pending->task.last) return 3;
    for(j=0;j<20;j++) if(!CoreYield || stage || errors ||
        root.next_task!=&root || root.last_task!=&root) return 4;
    if(!TaskRuntimeSchedActivate(&scheduler,&pending->task) ||
        !CoreYield || stage!=1 || pending->task.finished ||
        !CoreYield || stage!=2 || errors || !pending->task.finished ||
        !TaskRuntimeTaskDestroy(pending)) return 5;
    if(heap->used || heap->allocations || !I386HeapValid(heap) ||
        root.next_task!=&root || root.last_task!=&root ||
        root.next!=&root || root.last!=&root || root.lifetime_refs) return 6;
  }
  //Retained HolyC eligibility must agree with the native boot scheduler.
  kill_flags=1<<31|1<<TASKf_KILL_TASK|1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG;
  kill_wake=0x100000001;
  for(cycle=0;cycle<20;cycle++) {
    stage=0;
    pending=TaskRuntimeTaskCreateFrom(&scheduler,heap,&root,8192,
        &Worker,0x123456780000002A,0x18,0x20,4096);
    if(!pending) return 12;
    pending->task.task_flags=kill_flags; pending->task.wake_jiffy=kill_wake;
    if(!TaskRuntimeSchedActivate(&scheduler,&pending->task) ||
        !TaskRuntimeSchedYield(&scheduler) || stage!=1 || pending->task.finished ||
        !TaskRuntimeSchedYield(&scheduler) || stage!=2 || errors ||
        !pending->task.finished || !TaskRuntimeTaskDestroy(pending)) return 13;
    if(heap->used || heap->allocations || !I386HeapValid(heap) ||
        root.next_task!=&root || root.last_task!=&root || root.lifetime_refs) return 14;
  }
  kill_flags=0; kill_wake=0;
  if(TaskRuntimeTaskDiscard(0)) return 7;
  for(cycle=0;cycle<20;cycle++) {
    stage=0;
    pending=TaskRuntimeTaskCreateFrom(&scheduler,heap,&root,8192,
        &Worker,0x123456780000002A,0x18,0x20,4096);
    if(!pending || !TaskRuntimeTaskDiscard(pending) || stage || errors ||
        heap->used || heap->allocations || !I386HeapValid(heap) ||
        root.next_task!=&root || root.last_task!=&root) return 8;
  }
  pending=TaskRuntimeTaskCreateFrom(&scheduler,heap,&root,8192,
      &Creator,(heap+0)(U64),0x18,0x20,0,TRUE);
  if(!pending || TaskRuntimeTaskDiscard(pending) || !CoreYield ||
      !pending->task.finished || !orphan || pending->task.lifetime_refs!=1 ||
      TaskRuntimeTaskDestroy(pending)) return 9;
  for(j=0;j<20;j++) if(!CoreYield || stage || errors ||
      pending->task.lifetime_refs!=1) return 10;
  orphan->task.file_state=&stage;
  orphan->task.file_clone=&FileCloneStub; orphan->task.file_destroy=&FileDestroyFault;
  fail_destroy=1;
  if(TaskRuntimeTaskDiscard(orphan) || !orphan->task.finished ||
      orphan->task.next_task || orphan->task.last_task ||
      pending->task.lifetime_refs!=1 || TaskRuntimeTaskDestroy(pending) ||
      TaskRuntimeSchedActivate(&scheduler,&orphan->task)) return 12;
  if(!TaskRuntimeTaskDestroy(orphan) || pending->task.lifetime_refs ||
      !TaskRuntimeTaskDestroy(pending) || heap->used || heap->allocations ||
      !I386HeapValid(heap) || root.next_task!=&root || root.last_task!=&root ||
      root.next!=&root || root.last!=&root) return 11;
  return 0;
}
U0 Creator(I64 arg)
{
  orphan=TaskRuntimeTaskCreateFrom(&scheduler,arg,&root,8192,
      &Worker,0x123456780000002A,0x18,0x20,4096);
}
