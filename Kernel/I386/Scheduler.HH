#ifndef I386_SCHEDULER_INCLUDED
#define I386_SCHEDULER_INCLUDED
#include "/Kernel/I386/Context.HH"
extern class CI386Scheduler;
class CI386Task
{
  CI386Context context;
  CI386Task *next,*last;
  CI386Scheduler *owner;
  U32 finished,blocked;
};
class CI386Scheduler
{
  CI386Task *root,*current;
  U0 (*swap)(CI386Context *old,CI386Context *next);
};
public extern Bool I386SchedInit(CI386Scheduler *s,CI386Task *root,
  U0 (*swap)(CI386Context *old,CI386Context *next));
public extern Bool I386SchedAdd(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedYield(CI386Scheduler *s);
public extern Bool I386SchedFinish(CI386Scheduler *s);
public extern Bool I386SchedReap(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedBlock(CI386Scheduler *s);
public extern Bool I386SchedWake(CI386Scheduler *s,CI386Task *task);
public extern Bool I386SchedIdle(CI386Scheduler *s,U0 (*idle)());
#endif
