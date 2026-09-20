U32 flag_phase,flag_events,flag_seen,flag_progress,flag_idles;
extern I64 WakeTimeTest();
U0 FlagIdle()
{//Observe the idle decision without enabling IRQs in this specific check.
  if(GetRFlags&0x200) errors++;
  flag_idles++;
}
U0 FlagIrq(CI386IrqFrame *frame)
{
  CI386Task *before=scheduler.current;
  if(!I386PicAccept(frame->irq)) { errors++; return; }
  if(frame->irq || GetRFlags&0x600 || !(frame->eflags&0x200) ||
      (Fs+0)(U8 *)!=before) errors++;
  flag_events++; flag_seen|=1<<flag_phase;
  if(flag_phase==1) {
    if(flag_events==1) tasks[0].task_flags&=~(1<<TASKf_SUSPENDED);
    else tasks[0].task_flags&=~(1<<TASKf_AWAITING_MSG);
  } else if(flag_phase==4 || flag_phase==5) {
    if(flag_phase==4 && before!=&tasks[0] || flag_phase==5 && before!=&tasks[1]) errors++;
    if(tasks[1].blocked && !I386SchedWake(&scheduler,&tasks[1])) errors++;
  } else if(flag_phase==6) tasks[1].task_flags&=~(1<<TASKf_AWAITING_MSG);
  else if(flag_phase==7) {
    if(!tasks[1].finished || tasks[1].next_task || tasks[1].last_task ||
        !PublicRingCheck(1)) errors++;
    tasks[0].task_flags&=~(1<<TASKf_SUSPENDED);
  } else errors++;
  if(scheduler.current!=before) errors++;
  I386PicEoi(frame->irq);
}
U0 FlagWorker(I64 unused)
{
  flag_progress=1;
  if(!I386SchedBlock(&scheduler)) errors++;
  flag_progress=2;
  flag_phase=5; flag_events=0;
  //Root is suspended. Block must detach before IRQ Wake reinserts this task;
  //selection can then return this same task without corrupting its context.
  if(!I386SchedBlock(&scheduler) || !flag_events || GetRFlags&0x200 ||
      scheduler.current!=&tasks[1] || tasks[1].blocked) errors++;
  flag_progress=3;
  flag_phase=6; flag_events=0;
  tasks[1].task_flags|=1<<TASKf_AWAITING_MSG;
  if(!I386SchedYield(&scheduler) || !flag_events || GetRFlags&0x200 ||
      tasks[1].task_flags || scheduler.current!=&tasks[1]) errors++;
  flag_progress=4;
  flag_phase=7; flag_events=0;
  //Finish must detach before idling for the suspended root to become eligible.
}
I64 FlagEligibilityTest()
{
  CI386Heap heap;
  U8 *stack;
  I64 i,round;
  timer_dispatch->handler=&FlagIrq;
  for(round=0;round<2;round++) {
    flag_phase=1; flag_events=0;
    tasks[0].task_flags=1<<31|1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG;
    I386PicMask(0xFFFE);
    if(round) SetRFlags(GetRFlags|0x200);
    if(!I386SchedYield(&scheduler)) return 121+round*10;
    if(flag_events<2) return 122+round*10;
    if(tasks[0].task_flags!=1<<31) return 123+round*10;
    if(scheduler.current!=&tasks[0]) return 124+round*10;
    if(!!(GetRFlags&0x200)!=round) return 125+round*10;
    I386IrqSave; I386PicMask(0xFFFF);
  }
  tasks[0].task_flags=0;
  if(!I386HeapInit(&heap,0x60000,32768) || !(stack=I386HeapAlloc(&heap,8208))) return 112;
  for(i=0;i<8208;i++) stack[i]=0xA5;
  tasks[1].task_flags=1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG;
  if(!I386ContextInit(&tasks[1].context,stack+8,8192,&FlagWorker,0,&ScheduledExit,0x18,0x20) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386SchedIdle(&scheduler,&FlagIdle) ||
      flag_idles!=1 || !I386SchedYield(&scheduler) || flag_progress) return 113;
  tasks[1].task_flags&=~(1<<TASKf_SUSPENDED);
  if(!I386SchedYield(&scheduler) || flag_progress) return 114;
  tasks[1].task_flags&=~(1<<TASKf_AWAITING_MSG);
  if(I386SchedIdle(&scheduler,&FlagIdle) || !I386SchedYield(&scheduler) ||
      flag_progress!=1 || !tasks[1].blocked) return 115;
  tasks[0].task_flags=1<<TASKf_SUSPENDED;
  flag_phase=4; flag_events=0;
  I386PicMask(0xFFFE);
  if(!I386SchedYield(&scheduler) || GetRFlags&0x200 || tasks[0].task_flags ||
      flag_progress!=4 || !tasks[1].finished || flag_seen!=0xF2 || errors) return 116;
  I386PicMask(0xFFFF);
  if(!I386SchedReap(&scheduler,&tasks[1]) || !PublicRingCheck(1)) return 117;
  for(i=0;i<8;i++) if(stack[i]!=0xA5 || stack[8200+i]!=0xA5) return 118;
  if(!I386HeapFree(&heap,stack) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 119;
  return WakeTimeTest;
}
