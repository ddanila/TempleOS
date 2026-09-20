#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Context.HH"
#include "/Kernel/I386/Heap.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Frame.HH"
#include "/Kernel/I386/Debug.HH"
extern I64 OwnedTaskTest();
extern I64 JoinTest();
extern I64 AtaChannelTest();
extern U0 JoinWorker(I64 id);
CI386OwnedTask *join_tasks[3];
CI386Task foreign_task;
U32 join_stage,join_returns;
extern U0 OwnedWorker(I64 arg);
extern U0 OwnedCleanup(CI386Task *task);
U32 cleanup_progress[2];
CI386OwnedTask *owned_tasks[2];
U8 *private_blocks[2];
U32 owned_progress[2];
#include "/Kernel/I386/Irq.HH"
extern U0 I386PicInit();
extern U0 I386PicMask(U16 mask);
extern Bool I386PicAccept(I64 irq);
extern Bool I386PicEoi(I64 irq);
extern Bool I386PitStart(I64 divisor);
extern I64 TimerWakeTest();
extern U0 TimerWorker(I64 arg);
extern U0 OnTimer(CI386IrqFrame *frame);
class CTimerDispatch { U0 (*handler)(CI386IrqFrame *frame); };
class CTaskTestControl {
  CTimerDispatch *irq; U0 (*idle)(); I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs); U8 *task_descriptor,*cpu_descriptor;
};
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
extern U0 BindTask(CI386Task *task);
CI386Cpu bound_cpu;
class CSegmentTask { CSegmentTask *addr; U32 tag; I64 wide; U8 *ptr; U8 bytes[4]; };
class CSegmentCpu { CSegmentCpu *addr; U32 tag; CSegmentTask *task; };
_intern 0x15 CSegmentTask *Fs();
_intern 0x17 CSegmentCpu *Gs();
extern I64 SegmentCheck();
CTimerDispatch *timer_dispatch;
CTaskTestControl *test_control;
U0 (*idle)();
U32 events,consumed,wakes,wait_rounds;
extern I64 SchedulerTest();
extern U0 ScheduledWorker(I64 id);
extern U0 ScheduledExit();
CI386Scheduler scheduler;
CI386Task tasks[3];
U32 scheduled_progress[3],wake_order;
extern U0 Worker(I64 arg);
extern U0 TaskExit();
CI386Context contexts[3];
U0 (*swap)(CI386Context *old,CI386Context *next);
U32 current,progress[3],context_done[3],errors;
I64 totals[3];
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;
  U8 *stacks[3],*p;
  I64 i,j,round;
  swap=b; test_control=a; timer_dispatch=test_control->irq; idle=test_control->idle;
  if ((*test_control->segments)(&SegmentCheck)) return 36;
  if (!I386HeapInit(&heap,0x40000,32768)) return 1;
  for (i=1;i<=2;i++) {
    p=I386HeapAlloc(&heap,8208,TRUE); stacks[i]=p;
    if (!p) return 2;
    for (j=0;j<8208;j++) p[j]=0xA5;
    contexts[i].esp=0x12345678;
    if (I386ContextInit(&contexts[i],p+8,255,&Worker,i,&TaskExit) ||
        I386ContextInit(&contexts[i],p+9,8192,&Worker,i,&TaskExit) ||
        I386ContextInit(&contexts[i],p+8,8191,&Worker,i,&TaskExit) ||
        I386ContextInit(&contexts[i],p+8,8192,0,i,&TaskExit) ||
        I386ContextInit(&contexts[i],p+8,8192,&Worker,i,0) ||
        I386ContextInit(p+8,p+8,8192,&Worker,i,&TaskExit) ||
        I386ContextInit(0,p+8,8192,&Worker,i,&TaskExit) ||
        contexts[i].esp!=0x12345678) return 3;
    for (j=0;j<8208;j++) if (p[j]!=0xA5) return 4;
    if (!I386ContextInit(&contexts[i],p+8,8192,&Worker,0x1234567800000000+i,&TaskExit)) return 5;
  }
  //Saving and restoring the same context must also balance the argument stack.
  (*swap)(&contexts[0],&contexts[0]);
  for (round=0;round<65;round++) for (i=1;i<=2;i++) {
    current=i;
    (*swap)(&contexts[0],&contexts[i]);
    current=0;
    if (GetRFlags&0x600 || errors) return 6;
    if (round<64) {
      if (progress[i]!=round+1 || context_done[i] || totals[i]!=(round+1)*(0x100000000+i)) return 7;
    } else if (!context_done[i] || progress[i]!=64) return 8;
  }
  for (i=1;i<=2;i++) {
    p=stacks[i];
    for (j=0;j<8;j++) if (p[j]!=0xA5 || p[8200+j]!=0xA5) return 9;
    contexts[i].esp=0;
    if (!I386HeapFree(&heap,p)) return 10;
  }
  if (heap.used || heap.allocations || !I386HeapValid(&heap)) return 11;
  p=I386HeapAlloc(&heap,32752);
  if (!p || !I386HeapFree(&heap,p)) return 12;
  return (*test_control->segments)(&SchedulerTest);
}
U0 Worker(I64 arg)
{
  I64 id=arg&255,round,j,total=0;
  U32 local[32];
  if (id<1 || id>2 || arg!=0x1234567800000000+id) { errors++; return; }
  for (j=0;j<32;j++) local[j]=id*100+j;
  for (round=0;round<64;round++) {
    if (current!=id || (GetRFlags&0x600)) errors++;
    total+=0x100000000+id;
    totals[id]=total; progress[id]=round+1;
    (*swap)(&contexts[id],&contexts[0]);
    if (total!=(round+1)*(0x100000000+id) || current!=id) errors++;
    for (j=0;j<32;j++) if (local[j]!=id*100+j) errors++;
  }
}
U0 TaskExit()
{
  I64 id=current;
  context_done[id]=1;
  (*swap)(&contexts[id],&contexts[0]);
  //The scheduler must never resume a finished context.
  while (1) errors++;
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"

Bool PublicRingCheck(I64 count,Bool reverse=FALSE)
{//Check attachment order or an explicitly reordered public list.
  CTask *node=&tasks[0];
  I64 i,index;
  for(i=0;i<count;i++) {
    index=i;
    if(reverse && i) index=count-i;
    if(node!=&tasks[index] || !node->next_task || !node->last_task ||
        node->next_task->last_task!=node || node->last_task->next_task!=node) return FALSE;
    node=node->next_task;
  }
  return node==&tasks[0];
}
I64 SchedulerTest()
{
  CI386Heap heap;
  U8 *stacks[3],*p,descriptor_before[8];
  I64 i,j,round,expected;
  tasks[0].next_task=&tasks[1];
  if(I386SchedInit(&scheduler,&tasks[0],swap) || scheduler.root || tasks[0].owner ||
      tasks[0].addr || tasks[0].next_task!=&tasks[1]) return 105;
  tasks[0].next_task=0; tasks[0].last_task=&tasks[1];
  if(I386SchedInit(&scheduler,&tasks[0],swap) || scheduler.root || tasks[0].owner ||
      tasks[0].addr || tasks[0].last_task!=&tasks[1]) return 106;
  tasks[0].last_task=0;
  if (!I386HeapInit(&heap,0x40000,32768) ||
      I386SchedInit(0,&tasks[0],swap) || I386SchedInit(&scheduler,0,swap) ||
      I386SchedInit(&scheduler,&tasks[0],0) ||
      !I386SchedInit(&scheduler,&tasks[0],swap) ||
      I386SchedInit(&scheduler,&tasks[0],swap) ||
      !I386SchedYield(&scheduler) || I386SchedFinish(&scheduler) ||
      I386SchedAdd(&scheduler,&tasks[0]) || I386SchedReap(&scheduler,&tasks[0])) return 13;
  if(!PublicRingCheck(1)) return 101;
  for (i=0;i<8;i++) descriptor_before[i]=test_control->cpu_descriptor[i];
  if (I386DataSegment(0,&bound_cpu,8) ||
      I386DataSegment(test_control->cpu_descriptor,&bound_cpu,0) ||
      I386DataSegment(test_control->cpu_descriptor,&bound_cpu,0x100001) ||
      I386DataSegment(test_control->cpu_descriptor,0xFFFFFFF8,16)) return 38;
  for (i=0;i<8;i++) if (descriptor_before[i]!=test_control->cpu_descriptor[i]) return 39;
  bound_cpu.addr=&bound_cpu; bound_cpu.scheduler=&scheduler;
  if (!I386DataSegment(test_control->cpu_descriptor,&bound_cpu,sizeof(CI386Cpu)) ||
      I386SchedSetBind(0,&BindTask) || I386SchedSetBind(&scheduler,0) ||
      !I386SchedSetBind(&scheduler,&BindTask) || I386SchedSetBind(&scheduler,&BindTask) ||
      (Fs+0)(U8 *)!=&tasks[0] || (Gs+0)(U8 *)!=&bound_cpu) return 37;
  //Retire and reuse the same records and heap storage twice.
  if (I386SchedBlock(0) || I386SchedBlock(&scheduler) ||
      I386SchedWake(0,&tasks[0]) || I386SchedWake(&scheduler,0) ||
      I386SchedWake(&scheduler,&tasks[0])) return 24;
  for (round=0;round<2;round++) {
    wake_order=0;
    for (i=1;i<=2;i++) {
      scheduled_progress[i]=0;
      p=I386HeapAlloc(&heap,8232); stacks[i]=p;
      if (!p) return 14;
      for (j=0;j<8232;j++) p[j]=0xA5;
      tasks[i].stk=p+32-offset(CTaskStk.stk_base);
      tasks[i].stk->next_stk=0; tasks[i].stk->stk_ptr=0; tasks[i].stk->stk_size=8192;
      if (I386SchedAdd(&scheduler,&tasks[i]) ||
          !I386ContextInit(&tasks[i].context,p+32,8192,&ScheduledWorker,i,&ScheduledExit,0x18,0x20)) return 15;
      tasks[i].next_task=&tasks[0];
      if(I386SchedAdd(&scheduler,&tasks[i]) || tasks[i].owner || tasks[i].next || tasks[i].last ||
          tasks[i].next_task!=&tasks[0] || !PublicRingCheck(i)) return 107;
      tasks[i].next_task=0; tasks[i].last_task=&tasks[0];
      if(I386SchedAdd(&scheduler,&tasks[i]) || tasks[i].owner || tasks[i].next || tasks[i].last ||
          tasks[i].last_task!=&tasks[0] || !PublicRingCheck(i)) return 108;
      tasks[i].last_task=0;
      if(!I386SchedAdd(&scheduler,&tasks[i]) || I386SchedAdd(&scheduler,&tasks[i]) ||
          I386SchedReap(&scheduler,&tasks[i])) return 15;
      if(!PublicRingCheck(i+1)) return 102;
    }
    if (!I386SchedYield(&scheduler) || scheduler.current!=&tasks[0] || (Fs+0)(U8 *)!=&tasks[0] || (Gs+0)(U8 *)!=&bound_cpu ||
        tasks[0].next!=&tasks[0] || tasks[0].last!=&tasks[0]) return 25;
    if(!PublicRingCheck(3)) return 103;
    for (i=1;i<=2;i++) if (!tasks[i].blocked || tasks[i].finished ||
        tasks[i].next || tasks[i].last || scheduled_progress[i] ||
        I386SchedReap(&scheduler,&tasks[i])) return 26;
    if(round) {
      //Reorder blocked tasks through the public links only. Private wake order
      //is identical in both rounds; dispatch must follow the public list.
      tasks[0].next_task=&tasks[2]; tasks[0].last_task=&tasks[1];
      tasks[2].next_task=&tasks[1]; tasks[2].last_task=&tasks[0];
      tasks[1].next_task=&tasks[0]; tasks[1].last_task=&tasks[2];
      if(!PublicRingCheck(3,TRUE)) return 110;
    }
    expected=12;
    if(round) expected=21;
    if (!I386SchedYield(&scheduler) || wake_order ||
        !I386SchedWake(&scheduler,&tasks[2]) || I386SchedWake(&scheduler,&tasks[2]) ||
        !I386SchedWake(&scheduler,&tasks[1]) || I386SchedWake(&scheduler,&tasks[1])) return 27;
    if(!PublicRingCheck(3,round)) return 104;
    for (j=0;j<65;j++) {
      if (!I386SchedYield(&scheduler) || scheduler.current!=&tasks[0] || (Fs+0)(U8 *)!=&tasks[0] || (Gs+0)(U8 *)!=&bound_cpu ||
          (GetRFlags&0x600) || errors || wake_order!=expected) return 16;
      for (i=1;i<=2;i++) {
        if (j<64) {
          if (scheduled_progress[i]!=j+1 || tasks[i].finished) return 17;
        } else if (!tasks[i].finished || tasks[i].next || tasks[i].last ||
            tasks[i].next_task || tasks[i].last_task) return 18;
      }
    }
    if (!PublicRingCheck(1) || tasks[0].next!=&tasks[0] || tasks[0].last!=&tasks[0] ||
        !I386SchedYield(&scheduler)) return 19;
    for (i=1;i<=2;i++) {
      tasks[i].next_task=&tasks[0];
      if(I386SchedReap(&scheduler,&tasks[i]) || !tasks[i].finished || tasks[i].owner!=&scheduler ||
          tasks[i].next_task!=&tasks[0] || !PublicRingCheck(1)) return 109;
      tasks[i].next_task=0;
      if (I386SchedAdd(&scheduler,&tasks[i]) || I386SchedWake(&scheduler,&tasks[i]) ||
          !I386SchedReap(&scheduler,&tasks[i]) || tasks[i].context.esp ||
          tasks[i].owner || tasks[i].stk ||
          I386SchedReap(&scheduler,&tasks[i])) return 20;
      p=stacks[i];
      for (j=0;j<8;j++) if (p[j]!=0xA5 || p[8224+j]!=0xA5) return 21;
      if (!I386HeapFree(&heap,p)) return 22;
    }
    if (heap.used || heap.allocations || !I386HeapValid(&heap)) return 23;
  }
  return TimerWakeTest;
}
U0 ScheduledWorker(I64 id)
{
  I64 round,local=0;
  if (!I386SchedBlock(&scheduler) || (scheduler.current!=&tasks[id] || (Fs+0)(U8 *)!=&tasks[id] || (Gs+0)(U8 *)!=&bound_cpu) ||
      tasks[id].blocked || local || (GetRFlags&0x600)) errors++;
  wake_order=wake_order*10+id;
  for (round=0;round<64;round++) {
    if ((scheduler.current!=&tasks[id] || (Fs+0)(U8 *)!=&tasks[id] || (Gs+0)(U8 *)!=&bound_cpu)) errors++;
    local+=0x100000000+id;
    scheduled_progress[id]=round+1;
    if (!I386SchedYield(&scheduler) || local!=(round+1)*(0x100000000+id) ||
        (scheduler.current!=&tasks[id] || (Fs+0)(U8 *)!=&tasks[id] || (Gs+0)(U8 *)!=&bound_cpu)) errors++;
  }
}
U0 ScheduledExit()
{
  I386SchedFinish(&scheduler);
  while (1) errors++;
}
#include "/Kernel/I386/Scheduler.HC"

I64 TimerWakeTest()
{
  CI386Heap heap;
  U8 *stack;
  I64 i,loops,idles=0;
  if (!I386HeapInit(&heap,0x40000,32768)) return 28;
  stack=I386HeapAlloc(&heap,8208);
  if (!stack) return 29;
  for (i=0;i<8208;i++) stack[i]=0xA5;
  I386PicInit;
  timer_dispatch->handler=&OnTimer;
  if (!I386PitStart(1193) ||
      !I386ContextInit(&tasks[1].context,stack+8,8192,&TimerWorker,0x1234567800000001,&ScheduledExit,0x18,0x20) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386SchedYield(&scheduler) ||
      !tasks[1].blocked || events || wait_rounds) return 30;
  if (I386SchedIdle(0,idle) || I386SchedIdle(&scheduler,0) || (GetRFlags&0x200)) return 34;
  I386PicMask(0xFFFE);
  if (!I386SchedIdle(&scheduler,idle) || (GetRFlags&0x200) || !wakes ||
      tasks[1].blocked || I386SchedIdle(&scheduler,idle)) return 35;
  idles++;
  SetRFlags(GetRFlags|0x200);
  for (loops=0;loops<1000000;loops++) {
    if (I386SchedIdle(&scheduler,idle)) idles++;
    if (!I386SchedYield(&scheduler) || !(GetRFlags&0x200)) errors++;
    if (tasks[1].finished) break;
  }
  I386IrqSave;
  I386PicMask(0xFFFF);
  if (errors || idles<1 || !tasks[1].finished || wait_rounds!=16 || events<16 || !wakes ||
      !I386SchedReap(&scheduler,&tasks[1])) return 31;
  for (i=0;i<8;i++) if (stack[i]!=0xA5 || stack[8200+i]!=0xA5) return 32;
  if (!I386HeapFree(&heap,stack) || heap.used || heap.allocations ||
      !I386HeapValid(&heap)) return 33;
  return OwnedTaskTest;
}
U0 TimerWorker(I64 arg)
{
  I64 flags,round,local=arg;
  if (I386SchedIdle(&scheduler,idle)) errors++;
  SetRFlags(GetRFlags|0x200);
  for (round=0;round<16;round++) {
    flags=I386IrqSave;
    while (events==consumed) if (!I386SchedBlock(&scheduler)) errors++;
    consumed=events;
    I386IrqRestore(flags);
    if (!(GetRFlags&0x200) || scheduler.current!=&tasks[1] || (Fs+0)(U8 *)!=&tasks[1] || (Gs+0)(U8 *)!=&bound_cpu ||
        local!=0x1234567800000001) errors++;
    wait_rounds++;
  }
}
U0 OnTimer(CI386IrqFrame *frame)
{
  CI386Task *before=scheduler.current;
  if ((Fs+0)(U8 *)!=before || (Gs+0)(U8 *)!=&bound_cpu) errors++;
  if (!I386PicAccept(frame->irq)) { errors++; return; }
  if (frame->irq || (GetRFlags&0x600) || (frame->eflags&0x600)!=0x200) errors++;
  events++;
  if (tasks[1].blocked) {
    if(!PublicRingCheck(2)) errors++;
    if (!I386SchedWake(&scheduler,&tasks[1])) errors++;
    else wakes++;
  }
  if (scheduler.current!=before || (GetRFlags&0x200)) errors++;
  I386PicEoi(frame->irq);
}
#include "/Kernel/I386/PicPit.HC"

I64 SegmentCheck()
{
  CSegmentTask *task=0x50000;
  CSegmentCpu *cpu=0x50100;
  task->addr=task; task->tag=0x12345678; task->wide=0x123456789ABCDEF0;
  task->ptr=&task->bytes[0]; task->bytes[0]=42;
  cpu->addr=cpu; cpu->tag=0x87654321; cpu->task=task;
  if (Fs!=task || Gs!=cpu || Fs->addr!=task || Gs->addr!=cpu ||
      Gs->task!=Fs || Fs->tag!=0x12345678 || Gs->tag!=0x87654321 ||
      Fs->wide!=0x123456789ABCDEF0 || *Fs->ptr!=42) return 1;
  Fs->wide+=0x100000001;
  Gs->task->tag=93;
  Fs->bytes[1]=71;
  if (task->wide!=0x123456799ABCDEF1 || task->tag!=93 || task->bytes[1]!=71 ||
      (Fs+0)(U64)!=0x50000 || (Gs+0)(U64)!=0x50100) return 2;
  return 0;
}

U0 BindTask(CI386Task *task)
{
  if (GetRFlags&0x200 || task->addr!=task || scheduler.current!=task ||
      !I386DataSegment(test_control->task_descriptor,task,sizeof(CI386Task))) errors++;
  (*test_control->reload)(0x18,0x20);
  if ((Fs+0)(U8 *)!=task || (Gs+0)(U8 *)!=&bound_cpu) errors++;
}
#include "/Kernel/I386/Segments.HC"

I64 OwnedTaskTest()
{
  CI386Heap heap;
  I64 cycle,i,j;
  U8 *p;
  if(Caller(0) || Caller(-1) || Caller(0x7FFFFFFFFFFFFFFF)) return 62;
  if (!I386HeapInit(&heap,0x40000,32768) || I386TaskDestroy(0) ||
      I386TaskSpawn(0,&heap,8192,&OwnedWorker,0) ||
      I386TaskSpawn(&scheduler,0,8192,&OwnedWorker,0) ||
      I386TaskSpawn(&scheduler,&heap,8192,0,0) ||
      I386TaskSpawn(&scheduler,&heap,-1,&OwnedWorker,0) ||
      I386TaskSpawn(&scheduler,&heap,255,&OwnedWorker,0) ||
      I386TaskSpawn(&scheduler,&heap,257,&OwnedWorker,0) ||
      I386TaskSpawn(&scheduler,&heap,0x100000000,&OwnedWorker,0) || heap.used) return 40;
  if (I386TaskAlloc(1) || !I386TaskFree(0) ||
      I386TaskSpawn(&scheduler,&heap,8192,&OwnedWorker,0,0x18,0x20,-1) ||
      I386TaskSpawn(&scheduler,&heap,8192,&OwnedWorker,0,0x18,0x20,16) ||
      I386TaskSpawn(&scheduler,&heap,8192,&OwnedWorker,0,0x18,0x20,4097) ||
      I386TaskSpawn(&scheduler,&heap,8192,&OwnedWorker,0,0x18,0x20,0xFFFFFFFF)) return 57;
  if (I386SchedSetCleanup(0,&OwnedCleanup) ||
      I386SchedSetCleanup(&scheduler,&OwnedCleanup)) return 60;
  for (cycle=0;cycle<2;cycle++) {
    for (i=0;i<2;i++) {
      owned_progress[i]=0; private_blocks[i]=0; cleanup_progress[i]=0;
      owned_tasks[i]=I386TaskSpawn(&scheduler,&heap,8192,&OwnedWorker,0x100000000+i,0x18,0x20,4096);
      if (!owned_tasks[i] || I386TaskDestroy(owned_tasks[i]) ||
          owned_tasks[i]->task.addr!=&owned_tasks[i]->task ||
          !owned_tasks[i]->task.stk || owned_tasks[i]->task.stk->next_stk ||
          owned_tasks[i]->task.stk->stk_ptr ||
          ((&owned_tasks[i]->task.stk->stk_base)(U64)&7) ||
          owned_tasks[i]->task.stk->stk_size!=8192 ||
          (&owned_tasks[i]->task.stk->stk_base)(U8 *)+8192!=owned_tasks[i]->local_heap.base) return 41;
    }
    if (heap.allocations!=2 || I386TaskSpawn(&scheduler,&heap,32768,&OwnedWorker,0) ||
        heap.allocations!=2 || !I386HeapValid(&heap)) return 42;
    for (j=0;j<10;j++) {
      if (!I386SchedYield(&scheduler) || I386TaskSelf!=&tasks[0] || errors) return 43;
      for (i=0;i<2;i++) {
        if (j<8) {
          if (owned_progress[i]!=j+1 || owned_tasks[i]->task.finished) return 44;
        } else if (j==8) {
          if (owned_tasks[i]->task.finished || !owned_tasks[i]->task.finishing ||
              cleanup_progress[i]!=1 || I386TaskDestroy(owned_tasks[i])) return 61;
        } else if (!owned_tasks[i]->task.finished || owned_progress[i]!=8 || cleanup_progress[i]!=2) return 45;
      }
    }
    for (i=0;i<2;i++) {
      if (owned_tasks[i]->task.memory!=&owned_tasks[i]->local_heap ||
          owned_tasks[i]->local_heap.allocations!=1 ||
          !I386HeapValid(&owned_tasks[i]->local_heap) || I386TaskFree(private_blocks[i])) return 58;
      for (j=0;j<512;j++) if (private_blocks[i][j]!=i+0x70) return 59;
      if (!I386TaskDestroy(owned_tasks[i])) return 46;
      private_blocks[i]=0;
      owned_tasks[i]=0;
    }
    if (heap.used || heap.allocations || !I386HeapValid(&heap) ||
        tasks[0].next!=&tasks[0] || tasks[0].last!=&tasks[0] || (GetRFlags&0x200)) return 47;
  }
  p=I386HeapAlloc(&heap,32752);
  if (!p || !I386HeapFree(&heap,p)) return 48;
  return JoinTest;
}
I64 CheckCurrentFrame()
{
  CI386Task *task=I386TaskSelf;
  CI386Frame *frame=GetRBP;
  U8 *expected;
  if(!task->stk || task->stk->stk_size!=8192 ||
      !I386FrameValid(frame,(&task->stk->stk_base)(U8 *),task->stk->stk_size)) return 1;
  expected=I386FrameReturn(frame,(&task->stk->stk_base)(U8 *),task->stk->stk_size);
  if(!expected || Caller(1)!=expected || Caller()!=expected || !Caller(0) ||
      Caller(-1) || Caller(0x7FFFFFFFFFFFFFFF)) return 2;
  if(task->memory && I386FrameValid(task->memory->base,(&task->stk->stk_base)(U8 *),task->stk->stk_size))
    return 3;
  return 0;
}

U0 OwnedWorker(I64 arg)
{
  I64 id=arg&255,round,j;
  U32 local[8];
  U8 *p,*q;
  if (id>1 || arg!=0x100000000+id) { errors++; return; }
  SetRFlags(GetRFlags|0x200);
  if (!I386SchedSetCleanup(&scheduler,&OwnedCleanup) ||
      !I386SchedSetCleanup(&scheduler,0) || I386TaskSelf->cleanup ||
      !I386SchedSetCleanup(&scheduler,&OwnedCleanup)) errors++;
  q=I386TaskAlloc(4080);
  if (!q || I386TaskAlloc(1) || !I386TaskFree(q)) { errors++; return; }
  p=I386TaskAlloc(512,TRUE); private_blocks[id]=p;
  if (!p) { errors++; return; }
  for (j=0;j<512;j++) { if (p[j]) errors++; p[j]=id+0x70; }
  q=I386TaskAlloc(31,TRUE);
  if (!q || !I386TaskFree(q)) errors++;
  for (j=0;j<8;j++) local[j]=id*100+j;
  for (round=0;round<8;round++) {
    if (I386TaskSelf!=&owned_tasks[id]->task || I386TaskSelf->owner!=&scheduler ||
        I386TaskDestroy(owned_tasks[id])) errors++;
    if(CheckCurrentFrame()) errors++;
    owned_progress[id]=round+1;
    if (!I386SchedYield(&scheduler)) errors++;
    if(CheckCurrentFrame()) errors++;
    for (j=0;j<8;j++) if (local[j]!=id*100+j) errors++;
    for (j=0;j<512;j++) if (p[j]!=id+0x70) errors++;
    if (private_blocks[1-id] && I386TaskFree(private_blocks[1-id])) errors++;
  }
}
#include "/Kernel/I386/Task.HC"

I64 JoinTest()
{
  CI386Heap heap;
  I64 i;
  if (!I386HeapInit(&heap,0x40000,32768) ||
      I386SchedJoin(0,&tasks[0]) || I386SchedJoin(&scheduler,0) ||
      I386SchedJoin(&scheduler,&tasks[0]) || I386SchedJoin(&scheduler,&foreign_task)) return 49;
  for (i=0;i<3;i++) {
    join_tasks[i]=I386TaskSpawn(&scheduler,&heap,8192,&JoinWorker,i);
    if (!join_tasks[i]) return 50;
  }
  if (I386SchedJoin(&scheduler,&join_tasks[0]->task) || !I386SchedYield(&scheduler) ||
      join_stage!=1 || join_returns || !join_tasks[1]->task.blocked ||
      !join_tasks[2]->task.blocked || !join_tasks[0]->task.join_head) return 51;
  //Wake a joiner before completion: it must recheck and block again.
  if (!I386SchedWake(&scheduler,&join_tasks[1]->task) || !I386SchedYield(&scheduler) ||
      join_stage!=2 || join_returns || !join_tasks[1]->task.blocked || errors) return 52;
  if (!I386SchedYield(&scheduler) || !join_tasks[0]->task.finished ||
      join_returns || !I386SchedJoin(&scheduler,&join_tasks[0]->task) ||
      I386TaskDestroy(join_tasks[0]) || I386SchedReap(&scheduler,&join_tasks[0]->task)) return 53;
  if (!I386SchedYield(&scheduler) || join_returns!=2 || errors ||
      join_tasks[0]->task.join_head) return 54;
  for (i=0;i<3;i++) if (!I386TaskDestroy(join_tasks[i])) return 55;
  if (heap.used || heap.allocations || !I386HeapValid(&heap) ||
      tasks[0].next!=&tasks[0] || (GetRFlags&0x200)) return 56;
  return AtaChannelTest;
}
U0 JoinWorker(I64 id)
{
  if (id==0) {
    join_stage=1;
    I386SchedYield(&scheduler);
    //Worker 1 depends on us; adding the reverse dependency would deadlock.
    if (I386SchedJoin(&scheduler,&join_tasks[1]->task)) errors++;
    join_stage=2;
    I386SchedYield(&scheduler);
  } else {
    if (I386SchedJoin(&scheduler,I386TaskSelf) || I386SchedJoin(&scheduler,&tasks[0]) ||
        !I386SchedJoin(&scheduler,&join_tasks[0]->task) ||
        !join_tasks[0]->task.finished || I386TaskSelf->join_target ||
        !I386SchedJoin(&scheduler,&join_tasks[0]->task)) errors++;
    join_returns++;
  }
}

U0 OwnedCleanup(CI386Task *task)
{
  I64 id;
  U8 *p;
  if (task==&owned_tasks[0]->task) id=0;
  else id=1;
  if (task!=I386TaskSelf || !(GetRFlags&0x200) || !task->finishing || task->finished ||
      I386SchedFinish(&scheduler) || I386SchedSetCleanup(&scheduler,0)) errors++;
  p=I386TaskAlloc(32,TRUE);
  if (!p) { errors++; return; }
  p[0]=0xA7;
  cleanup_progress[id]=1;
  if (!I386SchedYield(&scheduler) || !(GetRFlags&0x200) || p[0]!=0xA7 || task!=I386TaskSelf ||
      !I386TaskFree(p)) errors++;
  cleanup_progress[id]=2;
}

#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Debug.HC"

#include "/Kernel/I386/AtaChannel.HC"
#include "T:/AtaChannel.HC"
