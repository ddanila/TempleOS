#ifndef I386_TASK_BREAK_INCLUDED
#define I386_TASK_BREAK_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
//Internal cooperative checkpoints; these are not the public Break/Yield ABI.
public extern Bool I386TaskBreakLock(CI386Task *task);
public extern Bool I386TaskBreakRequest(CI386Task *task);
public extern Bool I386TaskBreakUnlock(CI386Task *task);
//Call only after caller-owned temporary state has been released. Throws 'Break'
//on the current task; returns FALSE while absent, locked or unsafe to deliver.
public extern Bool I386TaskBreakPoll();
#endif
