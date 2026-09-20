I64 deadline_begin;
U32 deadline_phase,deadline_events,deadline_progress,deadline_wakes;
U0 DeadlineIrq(CI386IrqFrame *frame)
{
  if(!I386PicAccept(frame->irq)) { errors++; return; }
  if(frame->irq || GetRFlags&0x600 || !(frame->eflags&0x200)) errors++;
  test_jiffies++; deadline_events++;
  if(deadline_phase==2) {
    if(test_jiffies>=deadline_begin+4) tasks[1].task_flags&=~(1<<TASKf_SUSPENDED);
    if(tasks[1].blocked) {
      if(!I386SchedWake(&scheduler,&tasks[1])) errors++;
      deadline_wakes++;
    }
  }
  if(deadline_phase==3 && (!tasks[1].finished || tasks[1].next_task ||
      tasks[1].last_task || !PublicRingCheck(1))) errors++;
  I386PicEoi(frame->irq);
}
U0 DeadlineWorker(I64 unused)
{
  if(test_jiffies!=deadline_begin+4 || tasks[1].wake_jiffy!=deadline_begin+3 ||
      tasks[1].task_flags || GetRFlags&0x200) errors++;
  deadline_progress=1;
  tasks[1].wake_jiffy=test_jiffies+3;
  if(!I386SchedBlock(&scheduler) || test_jiffies!=tasks[1].wake_jiffy ||
      !deadline_wakes || GetRFlags&0x200) errors++;
  deadline_progress=2; deadline_phase=3;
}
I64 WakeTimeTest()
{
  CI386Heap heap;
  U8 *stack;
  I64 i;
  timer_dispatch->handler=&DeadlineIrq;
  test_jiffies=0xFFFFFFFE; tasks[0].wake_jiffy=0x100000001;
  deadline_phase=1; deadline_events=0;
  I386PicMask(0xFFFE);
  if(!I386SchedYield(&scheduler) || deadline_events!=3 || test_jiffies!=0x100000001 ||
      tasks[0].wake_jiffy!=test_jiffies || GetRFlags&0x200) return 142;
  I386PicMask(0xFFFF);
  tasks[0].wake_jiffy=-1;
  if(!I386SchedYield(&scheduler) || deadline_events!=3 ||
      I386SchedSetClock(&scheduler,&test_jiffies)) return 143;
  if(!I386HeapInit(&heap,0x60000,32768) || !(stack=I386HeapAlloc(&heap,8208))) return 144;
  for(i=0;i<8208;i++) stack[i]=0xA5;
  deadline_begin=test_jiffies; deadline_events=0; deadline_phase=2;
  tasks[1].wake_jiffy=deadline_begin+3; tasks[1].task_flags=1<<TASKf_SUSPENDED;
  if(!I386ContextInit(&tasks[1].context,stack+8,8192,&DeadlineWorker,0,&ScheduledExit,0x18,0x20) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386SchedIdle(&scheduler,&FlagIdle)) return 145;
  tasks[0].wake_jiffy=deadline_begin+8;
  I386PicMask(0xFFFE);
  if(!I386SchedYield(&scheduler) || test_jiffies!=deadline_begin+8 ||
      deadline_events!=8 || deadline_progress!=2 || !tasks[1].finished || errors ||
      tasks[0].wake_jiffy!=test_jiffies || GetRFlags&0x200) return 146;
  I386PicMask(0xFFFF);
  if(!I386SchedReap(&scheduler,&tasks[1])) return 147;
  for(i=0;i<8;i++) if(stack[i]!=0xA5 || stack[8200+i]!=0xA5) return 148;
  if(!I386HeapFree(&heap,stack) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 149;
  tasks[0].wake_jiffy=0; tasks[1].wake_jiffy=0; test_jiffies=0;
  return OwnedTaskTest;
}
