#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/ExceptNative.HH"
#include "/Kernel/I386/Debug.HH"
#include "/Kernel/I386/Gdt.HH"
#include "/Kernel/I386/TaskPlatform.HH"
#include "/Kernel/I386/Interrupt.HH"
#include "/Kernel/I386/Timer.HH"
#include "/Kernel/I386/Sleep.HH"
import U0 i386_idle();
_intern 0x17 CI386Cpu *CpuSelf();
import U0 i386_segments_reload(U16 fs,U16 gs);
CI386Scheduler scheduler;
CI386Task root;
CI386Cpu cpu;
U8 gdt_storage[56],runtime_idt[2048];
CI386Timer timer,rejected_timer;
CI386SleepQueue sleep_queue;
U32 spurious_wakes;
extern U0 SleepFor(I64 ticks);
U32 irq_tasks[3];
extern U0 OnTimer(CI386IrqFrame *frame);
extern U0 OnFault(CI386ExceptionFrame *frame);
extern U0 Unexpected();
extern U0 WaitTick();
CI386Heap heap;
CI386OwnedTask *workers[2];
U32 failures,progress[2],reports[2];
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
extern I64 Run();
extern U0 Worker(I64 id);
extern U0 Report(CI386Task *task,I64 ch);
extern U0 Fatal(CI386Task *task,I64 status,I64 ch);
extern I64 TimerScaleTest();
I64 Main(I64 unused0,I64 unused1)
{
  U8 saved[6],readback[6],saved_idt[6],*table=gdt_storage+8;
  CI386InterruptServices irq_services;
  U16 old_fs,old_gs;
  U8 master_mask,slave_mask;
  I64 i,result;
  asm {
    MOV AX,FS
    MOV U16 &old_fs[EBP],AX
    MOV AX,GS
    MOV U16 &old_gs[EBP],AX
  }
  for(i=0;i<56;i++) gdt_storage[i]=0xA5;
  if(I386GdtInit(table,0,sizeof(root),&cpu,sizeof(cpu)) ||
      I386GdtInit(table,&root,0,&cpu,sizeof(cpu)) ||
      I386GdtInit(table,&root,0x100001,&cpu,sizeof(cpu)) ||
      I386GdtInit(table,&root,sizeof(root),0xFFFFFFFC,8) ||
      I386GdtInit(0xFFFFFFF0,&root,sizeof(root),&cpu,sizeof(cpu))) return 20;
  for(i=0;i<56;i++) if(gdt_storage[i]!=0xA5) return 21;
  if(!I386GdtRead(saved) || I386GdtRead(0) || I386GdtRead(0xFFFFFFFC) ||
      I386GdtLoad(0,5) || I386GdtLoad(table,2) || I386GdtLoad(table,8193) ||
      I386GdtLoad(0xFFFFFFF8,3)) return 22;
  if(!I386GdtInit(table,&root,sizeof(root),&cpu,sizeof(cpu))) return 23;
  if(table(U64 *)[0] || table(U64 *)[1]!=0x00CF9A000000FFFF ||
      table(U64 *)[2]!=0x00CF92000000FFFF) return 24;
  for(i=0;i<8;i++) if(gdt_storage[i]!=0xA5 || gdt_storage[48+i]!=0xA5) return 25;
  asm {
    IN AL,0x21
    MOV U8 &master_mask[EBP],AL
    IN AL,0xA1
    MOV U8 &slave_mask[EBP],AL
    MOV AL,0xFF
    OUT 0x21,AL
    OUT 0xA1,AL
  }
  SetRFlags(GetRFlags|0x200);
  result=I386GdtLoad(table,5);
  SetRFlags(GetRFlags&~0x200);
  asm {
    MOV AL,U8 &master_mask[EBP]
    OUT 0x21,AL
    MOV AL,U8 &slave_mask[EBP]
    OUT 0xA1,AL
  }
  if(result || !I386GdtRead(readback)) return 26;
  for(i=0;i<6;i++) if(saved[i]!=readback[i]) return 27;
  if(I386ExceptInstallNative(0,&Fatal) || I386ExceptInstallNative(&Report,0) ||
      !I386ExceptInstallNative(&Report,&Fatal) ||
      I386ExceptInstallNative(&Report,&Fatal) ||
      !I386HeapInit(&heap,0x40000,32768)) return 28;
  if(I386TaskPlatformInit(0,&root,&cpu,table,0x88000,32768,&heap) ||
      I386TaskPlatformInit(&scheduler,&root,&cpu,table,0x88001,32768,&heap) ||
      I386TaskPlatformInit(&scheduler,&root,&cpu,table,0x88000,255,&heap) ||
      I386TaskPlatformInit(&scheduler,&root,&cpu,table,0x40000,32768,&heap) ||
      I386TaskPlatformInit(&scheduler,&root,&cpu,table,0x88000,32768,0)) return 37;
  if(scheduler.root || root.owner || cpu.scheduler ||
      !I386GdtRead(readback)) return 38;
  for(i=0;i<6;i++) if(saved[i]!=readback[i]) return 39;
  if(!I386TaskPlatformInit(&scheduler,&root,&cpu,table,0x88000,32768,&heap) ||
      I386TaskPlatformInit(&scheduler,&root,&cpu,table,0x88000,32768,&heap)) return 40;
  if(!root.stk || &root.stk->stk_base!=0x88018 || root.stk->stk_size!=32744 ||
      root.stk->next_stk || root.stk->stk_ptr || root.memory!=&heap ||
      cpu.addr!=&cpu || cpu.scheduler!=&scheduler || CpuSelf!=&cpu || !Caller(0)) return 41;
  if(!I386GdtRead(readback) || readback[0]!=39 || readback[1] ||
      (readback+2)(U32 *)[0]!=(table+0)(U64) || I386TaskSelf!=&root) result=29;
  else {
    if(!I386IdtRead(saved_idt)) return 42;
    I386PicInit;
    irq_services.irq=&OnTimer; irq_services.exception=&OnFault;
    if(!I386InterruptInstall(runtime_idt,256,&Unexpected,&irq_services)) return 43;
    result=TimerScaleTest;
    if(result) return result;
    if(I386TimerInit(0,11932) || I386TimerInit(&timer,1) ||
        I386TimerInit(&timer,65537) || I386TimerStep(&timer) || I386TimerTicks(&timer)) return 44;
    if(!I386TimerInit(&timer,11932) || I386TimerInit(&timer,11932)) return 45;
    timer.ticks=0xFFFFFFFFFFFFFFFF;
    if(!I386TimerStep(&timer) || I386TimerTicks(&timer)) return 46;
    if(I386SleepInit(0,&scheduler) || !I386SleepInit(&sleep_queue,&scheduler) ||
        I386SleepInit(&sleep_queue,&scheduler)) return 49;
    timer.ticks=0xFFFFFFF0;
    I386PicMask(0xFFFE);
    result=Run;
    I386PicMask(0xFFFF);
    if(!I386IdtLoad((saved_idt+2)(U32 *)[0],
        (saved_idt[0]+(saved_idt[1]<<8)+1)/8)) return 47;
  }
  if(GetRFlags&0x200) return 33;
  if(saved[0]!=23 || saved[1]) return 34;
  if(!(saved+2)(U32 *)[0]) return 35;
  i=(saved[0]+(saved[1]<<8)+1)/8;
  if(i!=3) return 36;
  if(!I386GdtLoad((saved+2)(U32 *)[0],i)) return 30;
  i386_segments_reload(old_fs,old_gs);
  if(!I386GdtRead(readback)) return 31;
  for(i=0;i<6;i++) if(saved[i]!=readback[i]) return 32;
  return result;
}

I64 Run()
{
  I64 cycle,i,round;
  U64 previous,snapshot;
  CI386Sleeper probe;
  WaitTick;
  SetRFlags(GetRFlags|0x200);
  if(I386TimerStep(&timer) || I386TimerInit(&rejected_timer,11932) ||
      I386SleepTick(&sleep_queue)) failures++;
  previous=I386TimerTicks(&timer);
  while(previous<=0x100000001) {
    snapshot=I386TimerTicks(&timer);
    if(snapshot<previous || !(GetRFlags&0x200)) failures++;
    previous=snapshot;
  }
  if(!(GetRFlags&0x200) || rejected_timer.ready || rejected_timer.ticks) failures++;
  SetRFlags(GetRFlags&~0x200);
  try { throw(0x1234567800000001,TRUE); failures++; }
  catch {
    if(I386TaskSelf!=&root || root.except_ch!=0x1234567800000001 ||
        !root.except_callers[0] || !root.except_top || root.memory!=&heap) failures++;
    root.catch_except=TRUE;
  }
  if(failures || root.except_top || heap.used || heap.allocations) return 3;
  if(I386SleepTicks(0,1) || I386SleepTicks(&sleep_queue,-1) ||
      I386SleepTicks(&sleep_queue,1) || !I386SleepTicks(&sleep_queue,0) ||
      sleep_queue.head || (GetRFlags&0x200)) return 50;
  probe.task=&root; probe.remaining=0x100000001; probe.queued=1; probe.next=0;
  sleep_queue.head=&probe;
  if(!I386SleepTick(&sleep_queue) || probe.remaining!=0x100000000 ||
      !I386SleepTick(&sleep_queue) || probe.remaining!=0xFFFFFFFF || !probe.queued) return 53;
  probe.remaining=1;
  if(!I386SleepTick(&sleep_queue) || probe.queued || sleep_queue.head || root.blocked) return 54;
  for(cycle=0;cycle<2;cycle++) {
    for(i=0;i<2;i++) {
      progress[i]=0; reports[i]=0;
      workers[i]=I386TaskSpawn(&scheduler,&heap,8192,&Worker,i,0x18,0x20,4096);
      if(!workers[i]) return 4;
    }
    for(round=0;round<512;round++) {
      if(spurious_wakes==cycle && sleep_queue.head && sleep_queue.head->remaining>1) {
        if(!I386SchedWake(&scheduler,sleep_queue.head->task)) return 51;
        spurious_wakes++;
      }
      if(root.next==&root) {
        if(!I386SchedIdle(&scheduler,&i386_idle)) return 52;
      } else if(!I386SchedYield(&scheduler)) return 5;
      if(I386TaskSelf!=&root) return 5;
      if(workers[0]->task.finished && workers[1]->task.finished) break;
    }
    for(i=0;i<2;i++) {
      if(!workers[i]->task.finished || progress[i]!=4 || reports[i]!=8 ||
          workers[i]->task.except_top || workers[i]->local_heap.used ||
          !I386TaskDestroy(workers[i])) return 6;
    }
    if(failures || heap.used || heap.allocations || !I386HeapValid(&heap) ||
        sleep_queue.head || spurious_wakes!=cycle+1) return 7;
    if(!irq_tasks[0] || !irq_tasks[1] || !irq_tasks[2] ||
        I386TimerTicks(&timer)<=0x100000000) return 48;
  }
  return 0;
}
U0 Worker(I64 id)
{
  CI386Task *task=I386TaskSelf;
  CI386Except *selected;
  U8 *site,*throw_frame;
  I64 i,value=0x1234567800000000+id,ch;
  WaitTick;
  for(i=0;i<4;i++) {
    ch=0x100000000+id*16+i;
    try { throw(ch); failures++; }
    catch {
      selected=task->except_top;
      site=task->except_callers[0]; throw_frame=task->except_rbp;
      if(!site || !I386FrameValid(throw_frame,(&task->stk->stk_base)(U8 *),task->stk->stk_size))
        failures++;
      if(task->except_ch!=ch || task->memory->allocations!=1) failures++;
      task->catch_except=TRUE;
      I386SchedYield(&scheduler);
      SleepFor(id+2);
      if(I386TaskSelf!=task || CpuSelf!=&cpu || task->except_top!=selected || !task->catch_except ||
          task->except_ch!=ch || task->except_callers[0]!=site ||
          task->except_rbp!=throw_frame || value!=0x1234567800000000+id+i*3) failures++;
      value++;
    }
    if(task->except_top || task->memory->used) failures++;
    try {
      try { throw(ch+0x200000000); failures++; }
      catch {
        selected=task->except_top;
        if(task->memory->allocations!=2) failures++;
        I386SchedYield(&scheduler);
        SleepFor(id+2);
        if(I386TaskSelf!=task || CpuSelf!=&cpu || task->except_top!=selected || task->catch_except ||
            task->except_ch!=ch+0x200000000) failures++;
        value++;
      }
      failures++;
    } catch {
      selected=task->except_top;
      task->catch_except=TRUE;
      if(task->memory->allocations!=1) failures++;
      I386SchedYield(&scheduler);
      SleepFor(id+2);
      if(I386TaskSelf!=task || CpuSelf!=&cpu || task->except_top!=selected || !task->catch_except ||
          task->except_ch!=ch+0x200000000) failures++;
      value++;
    }
    if(value!=0x1234567800000000+id+(i+1)*3 || task->except_top ||
        task->memory->used || !I386HeapValid(task->memory)) failures++;
    progress[id]++;
  }
}
U0 Report(CI386Task *task,I64 ch)
{
  I64 id,i;
  U8 *frame=GetRBP;
  if((task->except_rbp+0)(U64)!=*frame(U32 *)) failures++;
  for(i=0;i<I386_EXCEPT_CALLERS;i++)
    if(task->except_callers[i]!=Caller(i+2)) failures++;
  if(task!=I386TaskSelf || task->except_ch!=ch) failures++;
  for(id=0;id<2;id++) if(task==&workers[id]->task) reports[id]++;
}
U0 Fatal(CI386Task *task,I64 status,I64 ch)
{
  failures++;
  while(1) {}
}
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
#include "/Kernel/I386/ExceptRuntime.HC"
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Task.HC"
#include "/Kernel/I386/Segments.HC"

#include "/Kernel/I386/Debug.HC"

#include "/Kernel/I386/Gdt.HC"

#include "/Kernel/I386/TaskPlatform.HC"

#include "/Kernel/I386/ExceptNative.HC"

U0 WaitTick()
{
  U64 before=I386TimerTicks(&timer);
  if(GetRFlags&0x200) failures++;
  while(I386TimerTicks(&timer)==before) i386_idle;
  if(GetRFlags&0x200) failures++;
}
U0 OnTimer(CI386IrqFrame *frame)
{
  CI386Task *task=I386TaskSelf;
  if(!I386PicAccept(frame->irq)) return;
  if(frame->irq || task!=scheduler.current || CpuSelf!=&cpu ||
      (GetRFlags&0x600) || (frame->fs&65535)!=0x18 || (frame->gs&65535)!=0x20 ||
      !I386TimerStep(&timer)) failures++;
  if(!I386SleepTick(&sleep_queue)) failures++;
  if(task==&root) irq_tasks[0]++;
  else if(workers[0] && task==&workers[0]->task) irq_tasks[1]++;
  else if(workers[1] && task==&workers[1]->task) irq_tasks[2]++;
  else failures++;
  I386PicEoi(frame->irq);
}
U0 OnFault(CI386ExceptionFrame *frame)
{
  failures++;
  Unexpected;
}
U0 Unexpected()
{
  asm { CLI }
  while(1) { asm { HLT } }
}
#include "/Kernel/I386/Idt.HC"
#include "/Kernel/I386/Interrupt.HC"
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/Timer.HC"

U0 SleepFor(I64 ticks)
{
  U32 flags=GetRFlags,expected=0;
  U64 before=I386TimerTicks(&timer);
  if(ticks==3) { expected=0x200; SetRFlags(GetRFlags|0x200); }
  if(!I386SleepTicks(&sleep_queue,0) || !I386SleepTicks(&sleep_queue,ticks) ||
      I386TimerTicks(&timer)-before<ticks || (GetRFlags&0x200)!=expected) failures++;
  I386IrqRestore(flags);
}

#include "/Kernel/I386/Sleep.HC"

#include "T:/TimerScale.HC"
