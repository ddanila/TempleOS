#ifndef I386_SLEEP_INCLUDED
#define I386_SLEEP_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
#include "/Kernel/I386/Cpu.HH"
class CI386Sleeper
{
  CI386Sleeper *next;
  CI386Task *task;
  U64 remaining;
  U32 queued;
};
class CI386SleepQueue
{
  CI386Scheduler *scheduler;
  CI386Sleeper *head;
};
public extern Bool I386SleepInit(CI386SleepQueue *queue,CI386Scheduler *s);
//Task context only. Zero returns immediately; root cannot block. Preserves IF.
public extern Bool I386SleepTicks(CI386SleepQueue *queue,I64 ticks);
//Once per serviced timer tick, IF clear. Wakes due tasks without switching.
public extern Bool I386SleepTick(CI386SleepQueue *queue);
#endif
