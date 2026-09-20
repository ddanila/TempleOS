U32 break_done,break_if;
U0 BreakWorker(I64 scenario)
{
  CI386Task *task=I386TaskSelf;
  I64 guard;
  SetRFlags((GetRFlags&~0x200)|break_if);
  if(scenario==1 && (!I386TaskBreakLock(task) || I386TaskBreakLock(task))) failures++;
  if(scenario==2) task->task_flags|=1<<TASKf_BREAK_TO_SHIFT_ESC;
  try {
    if(I386SleepTicks(&sleep_queue,1000000) || task->wait || task->io_locks ||
        !(task->task_flags&(1<<TASKf_PENDING_BREAK)) || (GetRFlags&0x200)!=break_if) failures++;
    //An empty wait slot does not permit jumping past outstanding ownership.
    for(guard=0;guard<7;guard++) {
      if(guard==0) task->io_locks=1;
      if(guard==1) task->lifetime_refs=1;
      if(guard==2) task->compiler_busy=1;
      if(guard==3) task->active_controls=1;
      if(guard==4) task->compiler_cleanup_failed=1;
      if(guard==5) task->task_flags|=1<<TASKf_BREAK_TO_SHIFT_ESC;
      if(guard==6 && !I386TaskBreakLock(task)) failures++;
      if(I386TaskBreakPoll || !(task->task_flags&(1<<TASKf_PENDING_BREAK)) ||
          (GetRFlags&0x200)!=break_if) failures++;
      task->io_locks=0; task->lifetime_refs=0; task->compiler_busy=0;
      task->active_controls=0; task->compiler_cleanup_failed=0;
      task->task_flags&=~(1<<TASKf_BREAK_TO_SHIFT_ESC);
      if(guard==6 && !I386TaskBreakUnlock(task)) failures++;
    }
    I386TaskBreakPoll;
    failures++;
  } catch {
    if(task->except_ch!='Break' || task->wait || task->io_locks || task->lifetime_refs ||
        task->task_flags&(1<<TASKf_PENDING_BREAK|1<<TASKf_BREAK_LOCKED) ||
        (GetRFlags&0x200)!=break_if) failures++;
    task->catch_except=TRUE;
  }
  if(task->except_top || task->memory->used || I386TaskBreakPoll) failures++;
  break_done++;
}
I64 BreakTest()
{
  CI386Task foreign;
  CI386Task *task;
  I64 scenario;
  U32 saved=GetRFlags;
  foreign.owner=0;
  if(I386TaskBreakRequest(0) || I386TaskBreakLock(0) || I386TaskBreakUnlock(0) ||
      I386TaskBreakRequest(&foreign)) return 60;
  for(scenario=0;scenario<3;scenario++) {
    break_done=0; break_if=(scenario&1)*0x200;
    workers[0]=I386TaskSpawn(&scheduler,&heap,8192,&BreakWorker,scenario,0x18,0x20,4096);
    if(!workers[0]) return 61;
    task=&workers[0]->task;
    if(!I386SchedYield(&scheduler) || !task->blocked || !task->wait ||
        task->wait->kind!=I386_WAIT_SLEEP || !sleep_queue.head) return 62;
    task->wake_jiffy=0x100000001;
    if(!I386TaskBreakRequest(task) || !(task->task_flags&(1<<TASKf_PENDING_BREAK)) ||
        (GetRFlags&0x200)!=(saved&0x200)) return 63;
    if(scenario) {
      if(!task->blocked || task->wait->cancelled || !sleep_queue.head ||
          task->wake_jiffy!=0x100000001) return 64;
      if(scenario==1 && !I386TaskBreakUnlock(task)) return 65;
      if(scenario==2) {
        task->task_flags&=~(1<<TASKf_BREAK_TO_SHIFT_ESC);
        if(!I386TaskBreakRequest(task)) return 66;
      }
    }
    if(task->blocked || !task->wait || !task->wait->cancelled || sleep_queue.head ||
        task->wake_jiffy || !I386TaskBreakRequest(task) || I386TaskBreakUnlock(task) ||
        !I386SchedYield(&scheduler) || break_done!=1 || failures || !task->finished) return 67;
    if(I386TaskBreakRequest(task) || I386TaskBreakLock(task) || I386TaskBreakUnlock(task) ||
        !I386TaskDestroy(workers[0]) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 68;
  }
  return 0;
}
