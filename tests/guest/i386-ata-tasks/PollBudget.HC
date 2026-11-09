//The actual callback/scheduler execute with a deterministic clock and a swap
//observer. No ATA protocol is mocked; this isolates scheduling admission only.
CI386Scheduler budget_scheduler;
CI386Task budget_root,budget_worker;
CI386AtaChannel budget_channel;
I64 budget_clock,budget_work_ticks=3;
U32 budget_swaps,budget_errors;
extern U0 I386AtaTaskPoll(U8 *context);
U0 BudgetSwap(CI386Context *old,CI386Context *next)
{
  if(old!=&budget_worker.context || next!=&budget_root.context || GetRFlags&0x200)budget_errors++;
  budget_swaps++;budget_clock+=budget_work_ticks;
}
I64 PollBudgetTest()
{
  I64 i;
  budget_root.owner=budget_worker.owner=&budget_scheduler;
  budget_root.wake_jiffy=budget_worker.wake_jiffy=-1000;
  budget_root.next_task=&budget_worker;budget_worker.next_task=&budget_root;
  budget_scheduler.root=&budget_root;budget_scheduler.current=&budget_root;
  budget_scheduler.swap=&BudgetSwap;budget_scheduler.jiffies=&budget_clock;
  if(!I386AtaChannelInit(&budget_channel,&budget_scheduler,0))return 201;
  I386AtaTaskPoll(&budget_channel);
  if(budget_swaps || budget_channel.poll_yield_valid || GetRFlags&0x200)return 202;
  budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=1 || !budget_channel.poll_yield_valid ||
      budget_channel.poll_yield_jiffy!=budget_clock || GetRFlags&0x200)return 203;
  for(i=0;i<8;i++) {
    budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  }
  if(budget_swaps!=1 || budget_errors || GetRFlags&0x200)return 204;
  budget_clock+=15;budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=1)return 205;
  budget_clock++;budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=2 || budget_channel.poll_yield_jiffy!=budget_clock)return 205;
  budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=2)return 206;
  budget_clock=-7;budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=3 || budget_channel.poll_yield_jiffy!=budget_clock)return 207;
  budget_scheduler.jiffies=0;
  for(i=0;i<2;i++) {
    budget_scheduler.current=&budget_worker;I386AtaTaskPoll(&budget_channel);
  }
  if(budget_swaps!=5 || budget_channel.poll_yield_valid || GetRFlags&0x200)return 208;
  budget_scheduler.jiffies=&budget_clock;budget_scheduler.current=&budget_worker;
  I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=6 || budget_channel.poll_yield_jiffy!=budget_clock)return 209;
  budget_scheduler.current=&budget_worker;
  if(!I386AtaChannelAcquire(&budget_channel) || !I386AtaChannelRelease(&budget_channel))return 210;
  I386AtaTaskPoll(&budget_channel);
  if(budget_swaps!=6 || !I386AtaChannelClose(&budget_channel) ||
      budget_channel.poll_yield_valid || budget_channel.poll_yield_jiffy)return 211;
  if(!I386AtaChannelInit(&budget_channel,&budget_scheduler,1) ||
      !I386AtaChannelClose(&budget_channel) || budget_errors || GetRFlags&0x200)return 212;
  return 0;
}
