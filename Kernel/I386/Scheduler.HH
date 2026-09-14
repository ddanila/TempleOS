#ifndef I386_SCHEDULER_INCLUDED
#define I386_SCHEDULER_INCLUDED
#include "/Kernel/I386/Context.HH"
#include "/Kernel/I386/Heap.HH"
extern class CI386Scheduler;
extern class CI386MsgQueue;
extern class CI386Except;
#define I386_EXCEPT_CALLERS 8
class CI386Task
{
  CI386Task *addr;
  CI386Context context;
  CI386Task *next,*last;
  CI386Scheduler *owner;
  U32 finished,blocked;
  CI386Task *join_head,*join_next,*join_target;
  CI386Heap *memory;
  U0 (*cleanup)(CI386Task *task);
  U32 finishing;
  CI386MsgQueue *messages;
  U8 *stack_base;
  U32 stack_size;
  CI386Except *except_top;
  I64 except_ch;
  U32 catch_except;
  U8 *except_rbp,*except_callers[I386_EXCEPT_CALLERS];
};
class CI386Scheduler
{
  CI386Task *root,*current;
  U0 (*swap)(CI386Context *old,CI386Context *next);
  U0 (*bind)(CI386Task *task);
  CI386Task *focus;
};
class CI386Cpu { CI386Cpu *addr; CI386Scheduler *scheduler; };
public extern Bool I386SchedInit(CI386Scheduler *s,CI386Task *root,
  U0 (*swap)(CI386Context *old,CI386Context *next));
public extern Bool I386SchedAdd(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedYield(CI386Scheduler *s);
public extern Bool I386SchedFinish(CI386Scheduler *s);
public extern Bool I386SchedReap(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedBlock(CI386Scheduler *s);
public extern Bool I386SchedWake(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedIdle(CI386Scheduler *s,U0 (*idle)());
public extern Bool I386SchedSetBind(CI386Scheduler *s,U0 (*bind)(CI386Task *task));
public extern Bool I386SchedJoin(CI386Scheduler *s,CI386Task *target);
public extern Bool I386SchedSetCleanup(CI386Scheduler *s,U0 (*cleanup)(CI386Task *task));
#endif
