#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Context.HH"
#include "/Kernel/I386/Heap.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Scheduler.HH"
extern I64 SchedulerTest();
extern U0 ScheduledWorker(I64 id);
extern U0 ScheduledExit();
CI386Scheduler scheduler;
CI386Task tasks[3];
U32 scheduled_progress[3];
extern U0 Worker(I64 arg);
extern U0 TaskExit();
CI386Context contexts[3];
U0 (*swap)(CI386Context *old,CI386Context *next);
U32 current,progress[3],done[3],errors;
I64 totals[3];
I64 Main(I64 a,I64 b)
{
  CI386Heap heap;
  U8 *stacks[3],*p;
  I64 i,j,round;
  swap=b;
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
      if (progress[i]!=round+1 || done[i] || totals[i]!=(round+1)*(0x100000000+i)) return 7;
    } else if (!done[i] || progress[i]!=64) return 8;
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
  return SchedulerTest;
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
  done[id]=1;
  (*swap)(&contexts[id],&contexts[0]);
  //The scheduler must never resume a finished context.
  while (1) errors++;
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"

I64 SchedulerTest()
{
  CI386Heap heap;
  U8 *stacks[3],*p;
  I64 i,j,round;
  if (!I386HeapInit(&heap,0x40000,32768) ||
      I386SchedInit(0,&tasks[0],swap) || I386SchedInit(&scheduler,0,swap) ||
      I386SchedInit(&scheduler,&tasks[0],0) ||
      !I386SchedInit(&scheduler,&tasks[0],swap) ||
      I386SchedInit(&scheduler,&tasks[0],swap) ||
      !I386SchedYield(&scheduler) || I386SchedFinish(&scheduler) ||
      I386SchedAdd(&scheduler,&tasks[0]) || I386SchedReap(&scheduler,&tasks[0])) return 13;
  //Retire and reuse the same records and heap storage twice.
  for (round=0;round<2;round++) {
    for (i=1;i<=2;i++) {
      scheduled_progress[i]=0;
      p=I386HeapAlloc(&heap,8208); stacks[i]=p;
      if (!p) return 14;
      for (j=0;j<8208;j++) p[j]=0xA5;
      if (I386SchedAdd(&scheduler,&tasks[i]) ||
          !I386ContextInit(&tasks[i].context,p+8,8192,&ScheduledWorker,i,&ScheduledExit) ||
          !I386SchedAdd(&scheduler,&tasks[i]) || I386SchedAdd(&scheduler,&tasks[i]) ||
          I386SchedReap(&scheduler,&tasks[i])) return 15;
    }
    for (j=0;j<65;j++) {
      if (!I386SchedYield(&scheduler) || scheduler.current!=&tasks[0] ||
          (GetRFlags&0x600) || errors) return 16;
      for (i=1;i<=2;i++) {
        if (j<64) {
          if (scheduled_progress[i]!=j+1 || tasks[i].finished) return 17;
        } else if (!tasks[i].finished || tasks[i].next || tasks[i].last) return 18;
      }
    }
    if (tasks[0].next!=&tasks[0] || tasks[0].last!=&tasks[0] ||
        !I386SchedYield(&scheduler)) return 19;
    for (i=1;i<=2;i++) {
      if (I386SchedAdd(&scheduler,&tasks[i]) ||
          !I386SchedReap(&scheduler,&tasks[i]) || tasks[i].context.esp ||
          tasks[i].owner || I386SchedReap(&scheduler,&tasks[i])) return 20;
      p=stacks[i];
      for (j=0;j<8;j++) if (p[j]!=0xA5 || p[8200+j]!=0xA5) return 21;
      if (!I386HeapFree(&heap,p)) return 22;
    }
    if (heap.used || heap.allocations || !I386HeapValid(&heap)) return 23;
  }
  return 0;
}
U0 ScheduledWorker(I64 id)
{
  I64 round,local=0;
  for (round=0;round<64;round++) {
    if (scheduler.current!=&tasks[id]) errors++;
    local+=0x100000000+id;
    scheduled_progress[id]=round+1;
    if (!I386SchedYield(&scheduler) || local!=(round+1)*(0x100000000+id) ||
        scheduler.current!=&tasks[id]) errors++;
  }
}
U0 ScheduledExit()
{
  I386SchedFinish(&scheduler);
  while (1) errors++;
}
#include "/Kernel/I386/Scheduler.HC"
