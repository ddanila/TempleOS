CI386MsgQueue flag_queues[4];
U32 flag_done;
U0 FlagOtherWait(I64 unused)
{
  scheduler.current->task_flags|=1<<TASKf_AWAITING_MSG;
  if(!I386SchedBlock(&scheduler)) errors++;
  flag_done++;
}
U0 FlagReader(I64 id)
{
  CI386Message message;
  I64 type;
  SetRFlags(GetRFlags|0x200);
  message.type=99;
  type=I386MsgRead(&flag_queues[id],&message,1<<2);
  if(scheduler.current->task_flags!=1<<31 || !(GetRFlags&0x200)) errors++;
  if(id) {
    if(type || message.type!=99 || !flag_queues[id].closed) errors++;
  } else {
    if(type!=2 || message.arg1!=42 || !flag_queues[id].closed ||
        I386MsgRead(&flag_queues[id],&message,1<<2)) errors++;
  }
  flag_done++;
}
I64 WaitFlagsTest()
{
  CI386MsgQueue *queue;
  CI386Message message;
  I64 id;
  for(id=0;id<2;id++) {
    queue=&flag_queues[id]; flag_done=0;
    tasks[1].task_flags=1<<31;
    if(!I386MsgInit(queue,&scheduler) ||
        !I386ContextInit(&tasks[1].context,0x52000,8192,&FlagReader,id,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[1])) return 40;
    //Exercise both unbound queues and attached inboxes.
    if(id && !I386MsgAttach(queue,&tasks[1])) return 41;
    if(id) {
      //Public flag waits also work without entering the private queue reader.
      tasks[1].task_flags|=1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG;
      if(queue->waiter || I386MsgSend(queue,0,0,0) ||
          tasks[1].task_flags!=(1<<31|1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG) ||
          !I386MsgSend(queue,3,0,0) ||
          tasks[1].task_flags!=(1<<31|1<<TASKf_SUSPENDED)) return 53;
      tasks[1].task_flags&=~(1<<TASKf_SUSPENDED);
    }
    if(!I386SchedYield(&scheduler) || !tasks[1].blocked || queue->waiter!=&tasks[1] ||
        tasks[1].task_flags!=(1<<31|1<<TASKf_AWAITING_MSG)) return 42;
    if(I386MsgSend(queue,0,0,0) || I386MsgRead(queue,&message) ||
        tasks[1].task_flags!=(1<<31|1<<TASKf_AWAITING_MSG)) return 43;
    if(!I386SchedWake(&scheduler,&tasks[1]) || !I386SchedYield(&scheduler) ||
        tasks[1].blocked || flag_done || queue->waiter!=&tasks[1] ||
        tasks[1].task_flags!=(1<<31|1<<TASKf_AWAITING_MSG)) return 44;
    tasks[1].task_flags|=1<<TASKf_SUSPENDED;
    if(id) {
      if(!I386MsgClose(queue)) return 45;
    } else if(!I386MsgSend(queue,3,0,0)) return 46;
    if(tasks[1].task_flags!=(1<<31|1<<TASKf_SUSPENDED) ||
        !I386SchedYield(&scheduler) || flag_done) return 47;
    tasks[1].task_flags&=~(1<<TASKf_SUSPENDED);
    if(!id) {
      //An unmatched message wakes the reader, which discards it and waits again.
      if(!I386SchedYield(&scheduler) || flag_done || !tasks[1].blocked || queue->count ||
          tasks[1].task_flags!=(1<<31|1<<TASKf_AWAITING_MSG)) return 48;
      if(!I386MsgSend(queue,2,42,0) || tasks[1].task_flags!=1<<31 ||
          tasks[1].blocked || !I386MsgClose(queue)) return 49;
    }
    if(!I386SchedYield(&scheduler) || flag_done!=1 || errors || !tasks[1].finished ||
        queue->waiter || queue->count || tasks[1].task_flags!=1<<31 || GetRFlags&0x200) return 50;
    if(id && !I386MsgDetach(queue)) return 51;
    if(!I386SchedReap(&scheduler,&tasks[1])) return 52;
    tasks[1].task_flags=0;
  }
  queue=&flag_queues[2];
  tasks[1].task_flags=1<<31|1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG;
  if(!I386MsgInit(queue,&scheduler) ||
      !I386ContextInit(&tasks[1].context,0x52000,8192,&EmptyWorker,0,&EndTask) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386MsgAttach(queue,&tasks[1]) ||
      queue->waiter || !I386MsgClose(queue) ||
      tasks[1].task_flags!=(1<<31|1<<TASKf_SUSPENDED) ||
      I386MsgSend(queue,2,0,0) || !I386SchedYield(&scheduler) || tasks[1].finished) return 54;
  tasks[1].task_flags&=~(1<<TASKf_SUSPENDED);
  if(!I386SchedYield(&scheduler) || !tasks[1].finished ||
      !I386MsgDetach(queue) || !I386SchedReap(&scheduler,&tasks[1])) return 55;
  tasks[1].task_flags=0;
  queue=&flag_queues[3]; flag_done=0; tasks[1].task_flags=1<<31;
  if(!I386MsgInit(queue,&scheduler) ||
      !I386ContextInit(&tasks[1].context,0x52000,8192,&FlagOtherWait,0,&EndTask) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386MsgAttach(queue,&tasks[1]) ||
      !I386SchedYield(&scheduler) || !tasks[1].blocked || queue->waiter ||
      !I386MsgSend(queue,2,0,0) || tasks[1].task_flags!=1<<31 ||
      !tasks[1].blocked || !I386MsgClose(queue) || !tasks[1].blocked ||
      !I386SchedYield(&scheduler) || flag_done || queue->count!=1) return 56;
  if(!I386SchedWake(&scheduler,&tasks[1]) || !I386SchedYield(&scheduler) ||
      flag_done!=1 || errors || !I386MsgDetach(queue) ||
      !I386SchedReap(&scheduler,&tasks[1])) return 57;
  tasks[1].task_flags=0;
  return 0;
}
