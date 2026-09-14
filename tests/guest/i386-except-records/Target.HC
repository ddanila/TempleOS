#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Except.HH"
CI386Scheduler scheduler;
CI386Task tasks[2];
CI386Heap heaps[2];
I64 Main(I64 a,I64 b)
{
  CI386Task *task=&tasks[0],*other=&tasks[1];
  CI386ExceptCapture capture;
  CI386Except *first,*second;
  U8 *full;
  U32 flags=GetRFlags,frames[8];
  I64 i;
  if(!I386HeapInit(&heaps[0],0x40000,4096) ||
      !I386HeapInit(&heaps[1],0x42000,4096)) return 1;
  scheduler.current=task; scheduler.root=other;
  task->owner=&scheduler; other->owner=&scheduler;
  task->stack_base=frames; task->stack_size=sizeof(frames);
  other->stack_base=frames; other->stack_size=sizeof(frames);
  capture.ebp=&frames[4]; capture.esp=frames;
  capture.ebx=0x12345678; capture.esi=0x9ABCDEF0; capture.edi=0x87654321;
  capture.eflags=2; capture.catch_start=&Main; capture.untry_start=&Main;
  if(I386ExceptPush(0,&heaps[0],&capture) ||
      I386ExceptPush(task,&heaps[0],0) ||
      I386ExceptPush(other,&heaps[0],&capture) || I386ExceptPop(task) ||
      !I386ExceptClear(task)) return 2;
  if(capture.ebp&3) return 46;
  if(!capture.ebp || !task->stack_base) return 47;
  if(task->stack_size!=32) return 48;
  if(capture.ebp!=(frames+0)(U64)+16) return 49;
  if(!I386FrameValid(capture.ebp,task->stack_base,task->stack_size)) return 40;
  if(capture.esp&3) return 41;
  if(capture.esp<(task->stack_base+0)(U64)) return 42;
  if(capture.esp>capture.ebp) return 43;
  if(!capture.catch_start || !capture.untry_start) return 44;
  if(task->owner!=&scheduler || task->owner->current!=task || task->finished) return 45;
  first=I386ExceptPush(task,&heaps[0],&capture);
  if(!first) return 31;
  if(first!=task->except_top) return 32;
  if(first->previous) return 33;
  if(first->task!=task) return 34;
  if(first->heap!=&heaps[0]) return 35;
  if(heaps[0].allocations!=1) return 36;
  for(i=0;i<8;i++) if((&first->capture)(U32 *)[i]!=(&capture)(U32 *)[i]) return 4;
  second=I386ExceptPush(task,&heaps[1],&capture);
  if(!second || second->previous!=first || task->except_top!=second ||
      !I386ExceptPop(task) || task->except_top!=first || heaps[1].allocations) return 5;
  full=I386HeapAlloc(&heaps[1],4080);
  if(!full || I386ExceptPush(task,&heaps[1],&capture) ||
      task->except_top!=first || !I386HeapFree(&heaps[1],full)) return 6;
  capture.esp++;
  if(I386ExceptPush(task,&heaps[0],&capture)) return 7;
  capture.esp=frames; capture.ebp=frames+7;
  if(I386ExceptPush(task,&heaps[0],&capture)) return 8;
  capture.ebp=&frames[4]; capture.esp=capture.ebp+4;
  if(I386ExceptPush(task,&heaps[0],&capture)) return 9;
  capture.esp=frames; capture.catch_start=0;
  if(I386ExceptPush(task,&heaps[0],&capture)) return 10;
  capture.catch_start=&Main; capture.untry_start=0;
  if(I386ExceptPush(task,&heaps[0],&capture)) return 11;
  capture.untry_start=&Main;
  if(task->except_top!=first || heaps[0].allocations!=1) return 12;
  first->signature=0;
  if(I386ExceptPop(task) || I386ExceptClear(task) || task->except_top!=first) return 13;
  first->signature=I386_EXCEPT_MAGIC; first->task=other;
  if(I386ExceptPop(task) || task->except_top!=first) return 14;
  first->task=task;
  scheduler.current=other;
  if(I386ExceptPop(task) || I386ExceptClear(task)) return 15;
  second=I386ExceptPush(other,&heaps[1],&capture);
  if(!second || second->previous || task->except_top!=first ||
      !I386ExceptClear(other) || other->except_top) return 16;
  //A detached finished task cannot be reaped until its records are drained.
  task->finished=1;
  if(I386SchedReap(&scheduler,task) || task->except_top!=first ||
      I386ExceptPush(task,&heaps[0],&capture)) return 17;
  if(!I386ExceptClear(task) || !I386SchedReap(&scheduler,task) ||
      task->owner || task->stack_base || task->stack_size) return 18;
  if(heaps[0].used || heaps[1].used || heaps[0].allocations ||
      heaps[1].allocations || !I386HeapValid(&heaps[0]) ||
      !I386HeapValid(&heaps[1])) return 19;
  full=I386HeapAlloc(&heaps[0],4080);
  if(!full || !I386HeapFree(&heaps[0],full)) return 20;
  if((GetRFlags^flags)&0x200) return 21;
  return 0;
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Except.HC"
