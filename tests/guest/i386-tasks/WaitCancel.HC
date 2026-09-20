CI386SleepQueue cancel_sleep;
CI386OwnedTask *wait_tasks[4];
U32 wait_mask,wait_done,wait_if;
U0 CancelSleepWorker(I64 id)
{
  Bool result;
  SetRFlags((GetRFlags&~0x200)|wait_if);
  result=I386SleepTicks(&cancel_sleep,2);
  if(result==((wait_mask & (1<<id))!=0) || (GetRFlags&0x200)!=wait_if) errors++;
  wait_done++;
}
U0 CancelJoinWorker(I64 id)
{
  Bool result;
  SetRFlags((GetRFlags&~0x200)|wait_if);
  if(!id) { I386SchedBlock(&scheduler); return; }
  result=I386SchedJoin(&scheduler,&wait_tasks[0]->task);
  if(result==((wait_mask & (1<<id))!=0) || I386TaskSelf->join_target ||
      I386TaskSelf->join_next || (GetRFlags&0x200)!=wait_if) errors++;
  wait_done++;
}
I64 WaitCancelTest()
{
  CI386Heap heap;
  CI386Sleeper *sleeper;
  CI386Task *node;
  I64 scenario,i,count;
  U32 saved=GetRFlags,flags;
  U8 *reuse;
  if(!I386HeapInit(&heap,0x60000,49152) || !I386SleepInit(&cancel_sleep,&scheduler)) return 170;
  for(scenario=0;scenario<5;scenario++) {
    wait_mask=1<<scenario;
    if(scenario==3) wait_mask=7;
    if(scenario==4) wait_mask=0;
    wait_done=0; count=0; wait_if=(scenario&1)*0x200;
    SetRFlags((saved&~0x200)|wait_if);
    for(i=0;i<3;i++) {
      wait_tasks[i]=I386TaskSpawn(&scheduler,&heap,8192,&CancelSleepWorker,i);
      if(!wait_tasks[i]) return 171;
    }
    if(!I386SchedYield(&scheduler) || wait_done ||
        I386SleepCancel(0,&tasks[0]) || I386SleepCancel(&cancel_sleep,0) ||
        I386SleepCancel(&cancel_sleep,&foreign_task) ||
        I386SleepCancel(&cancel_sleep,&tasks[0])) return 172;
    for(i=0;i<3;i++) if(wait_mask & (1<<i)) {
      count++;
      if((scenario&1) && !I386SchedWake(&scheduler,&wait_tasks[i]->task)) return 173;
      wait_tasks[i]->task.task_flags=1<<TASKf_SUSPENDED|0x80000000;
      wait_tasks[i]->task.wake_jiffy=0x100000001;
      if(!I386SleepCancel(&cancel_sleep,&wait_tasks[i]->task) ||
          I386SleepCancel(&cancel_sleep,&wait_tasks[i]->task) ||
          wait_tasks[i]->task.blocked || wait_tasks[i]->task.task_flags!=(1<<TASKf_SUSPENDED|0x80000000) ||
          wait_tasks[i]->task.wake_jiffy!=0x100000001 || (GetRFlags&0x200)!=wait_if) return 174;
    }
    sleeper=cancel_sleep.head;
    for(i=2;i>=0;i--) if(!(wait_mask & (1<<i))) {
      if(!sleeper || sleeper->task!=&wait_tasks[i]->task || !sleeper->queued || sleeper->remaining!=2) return 175;
      sleeper=sleeper->next;
    }
    if(sleeper) return 176;
    flags=I386IrqSave;
    if(!I386SleepTick(&cancel_sleep) || !I386SleepTick(&cancel_sleep) || cancel_sleep.head) return 177;
    I386IrqRestore(flags);
    for(i=0;i<3;i++) if(I386SleepCancel(&cancel_sleep,&wait_tasks[i]->task)) return 178;
    if(!I386SchedYield(&scheduler) || wait_done!=3-count || errors) return 179;
    for(i=0;i<3;i++) if(wait_mask & (1<<i)) {
      if(wait_tasks[i]->task.finished) return 180;
      wait_tasks[i]->task.task_flags=0; wait_tasks[i]->task.wake_jiffy=0;
    }
    if(!I386SchedYield(&scheduler) || wait_done!=3 || errors) return 181;
    for(i=0;i<3;i++) if(!I386TaskDestroy(wait_tasks[i])) return 182;
    if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 183;
  }
  for(scenario=0;scenario<5;scenario++) {
    wait_mask=1<<(scenario+1);
    if(scenario==3) wait_mask=14;
    if(scenario==4) wait_mask=0;
    wait_done=0; count=0; wait_if=(scenario&1)*0x200;
    SetRFlags((saved&~0x200)|wait_if);
    for(i=0;i<4;i++) {
      wait_tasks[i]=I386TaskSpawn(&scheduler,&heap,8192,&CancelJoinWorker,i);
      if(!wait_tasks[i]) return 184;
    }
    if(!I386SchedYield(&scheduler) || wait_done ||
        I386SchedCancelJoin(0,&tasks[0]) || I386SchedCancelJoin(&scheduler,0) ||
        I386SchedCancelJoin(&scheduler,&foreign_task) || I386SchedCancelJoin(&scheduler,&tasks[0])) return 185;
    for(i=1;i<4;i++) {
      if(wait_tasks[i]->task.join_target!=&wait_tasks[0]->task || !wait_tasks[i]->task.blocked) return 186;
      if(scenario==4 || (wait_mask & (1<<i))) {
        wait_tasks[i]->task.task_flags=1<<TASKf_SUSPENDED|0x80000000;
        wait_tasks[i]->task.wake_jiffy=0x100000001;
      }
      if(wait_mask & (1<<i)) {
        count++;
        if((scenario&1) && !I386SchedWake(&scheduler,&wait_tasks[i]->task)) return 187;
        if(!I386SchedCancelJoin(&scheduler,&wait_tasks[i]->task) ||
            I386SchedCancelJoin(&scheduler,&wait_tasks[i]->task) ||
            wait_tasks[i]->task.join_target || wait_tasks[i]->task.join_next || wait_tasks[i]->task.blocked ||
            wait_tasks[i]->task.task_flags!=(1<<TASKf_SUSPENDED|0x80000000) ||
            wait_tasks[i]->task.wake_jiffy!=0x100000001 || (GetRFlags&0x200)!=wait_if) return 188;
      }
    }
    node=wait_tasks[0]->task.join_head;
    for(i=3;i>0;i--) if(!(wait_mask & (1<<i))) {
      if(node!=&wait_tasks[i]->task) return 189;
      node=node->join_next;
    }
    if(node || !I386SchedWake(&scheduler,&wait_tasks[0]->task) || !I386SchedYield(&scheduler) ||
        !wait_tasks[0]->task.finished || errors) return 190;
    if(scenario==4) {
      if(wait_done || I386TaskDestroy(wait_tasks[0])) return 191;
      for(i=1;i<4;i++) {
        if(I386SchedCancelJoin(&scheduler,&wait_tasks[i]->task) ||
            wait_tasks[i]->task.join_target!=&wait_tasks[0]->task) return 192;
        wait_tasks[i]->task.task_flags=0; wait_tasks[i]->task.wake_jiffy=0;
      }
      if(!I386SchedYield(&scheduler) || wait_done!=3 || errors) return 193;
    } else if(wait_done!=3-count) return 194;
    //Cancelled join calls must not dereference a reaped/reused target on return.
    if(!I386TaskDestroy(wait_tasks[0]) || !(reuse=I386HeapAlloc(&heap,8192)) || reuse!=(wait_tasks[0]+0)(U8 *)) return 195;
    for(i=0;i<8192;i++) reuse[i]=0xA5;
    for(i=1;i<4;i++) if(wait_mask & (1<<i)) {
      if(wait_tasks[i]->task.finished) return 196;
      wait_tasks[i]->task.task_flags=0; wait_tasks[i]->task.wake_jiffy=0;
    }
    if(!I386SchedYield(&scheduler) || wait_done!=3 || errors) return 197;
    for(i=1;i<4;i++) if(!I386TaskDestroy(wait_tasks[i])) return 198;
    if(!I386HeapFree(&heap,reuse) || heap.used || heap.allocations || !I386HeapValid(&heap) ||
        (GetRFlags&0x200)!=wait_if) return 199;
  }
  SetRFlags(saved);
  return 0;
}
