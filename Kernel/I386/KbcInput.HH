#ifndef I386_KBC_INPUT_INCLUDED
#define I386_KBC_INPUT_INCLUDED
#include "/Kernel/I386/KbcQueue.HH"
#include "/Kernel/I386/Scheduler.HH"
class CI386KbcInput {
  CI386KbcQueue queue;
  CI386Scheduler *scheduler;
  CI386Task *waiter;
};
public extern Bool I386KbcInputInit(CI386KbcInput *input,CI386Scheduler *scheduler);
public extern Bool I386KbcInputPut(CI386KbcInput *input,U8 data,U8 status);
public extern Bool I386KbcInputRead(CI386KbcInput *input,U8 *data,U8 *status,Bool wait=TRUE);
#endif
