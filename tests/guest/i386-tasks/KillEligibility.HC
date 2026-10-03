I64 kill_deadline;
U32 kill_flags,kill_progress;
U0 KillEligibilityWorker(I64 unused)
{
  if(I386TaskSelf!=&tasks[1] || tasks[1].task_flags!=kill_flags ||
      tasks[1].wake_jiffy!=kill_deadline || GetRFlags&0x200) errors++;
  kill_progress++;
}
I64 KillEligibilityTest()
{
  CI386Heap heap;
  U8 *stack;
  I64 i,j;
  if(!I386HeapInit(&heap,0x60000,32768)) return 170;
  for(j=1;j<=3;j++) {
    if(!(stack=I386HeapAlloc(&heap,8208))) return 171;
    for(i=0;i<8208;i++) stack[i]=0xA5;
    kill_deadline=test_jiffies+100000;
    kill_flags=1<<31|1<<TASKf_KILL_TASK;
    if(j&1) kill_flags|=1<<TASKf_SUSPENDED;
    if(j&2) kill_flags|=1<<TASKf_AWAITING_MSG;
    tasks[1].task_flags=kill_flags; tasks[1].wake_jiffy=kill_deadline;
    kill_progress=0;
    if(!I386ContextInit(&tasks[1].context,stack+8,8192,&KillEligibilityWorker,0,
        &ScheduledExit,0x18,0x20) || !I386SchedAdd(&scheduler,&tasks[1])) return 172;
    //KILL overrides public eligibility, but must never bypass a private wait.
    tasks[1].blocked=TRUE;
    if(!I386SchedYield(&scheduler) || kill_progress || tasks[1].finished) return 173;
    tasks[1].blocked=FALSE;
    if(!I386SchedYield(&scheduler) || kill_progress!=1 || !tasks[1].finished ||
        errors || test_jiffies || GetRFlags&0x200 || !PublicRingCheck(1)) return 174;
    if(!I386SchedReap(&scheduler,&tasks[1])) return 175;
    for(i=0;i<8;i++) if(stack[i]!=0xA5 || stack[8200+i]!=0xA5) return 176;
    if(!I386HeapFree(&heap,stack) || heap.used || heap.allocations ||
        !I386HeapValid(&heap)) return 177;
  }
  tasks[1].task_flags=0; tasks[1].wake_jiffy=0;
  return OwnedTaskTest;
}
