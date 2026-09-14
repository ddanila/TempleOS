#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/AtaTask.HH"
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
#include "/Kernel/I386/Irq.HH"
#include "/Kernel/I386/PicPit.HH"
#include "/Kernel/I386/Kbc.HH"
class CDispatch { U0 (*handler)(CI386IrqFrame *frame); };
class CControl {
  CDispatch *irq; U0 (*idle)(); I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs); U8 *task_descriptor,*cpu_descriptor;
};
CControl *control;
CI386Scheduler scheduler;
CI386Task root;
CI386Cpu cpu;
CI386Heap heap;
CI386AtaChannel channel,other;
CI386Ata disks[2];
CI386OwnedTask *workers[3];
U32 errors,completed,competitors,queued,observed,ticks,keys,irq_owned,failed,poll_steps,timer_owned,keys_owned,failed_queued;
extern Bool I386AtaWait(U16 io,U8 mask,U8 wanted,Bool errors,I64 polls,CI386AtaPoll *poll);
U0 PollProbe(U8 *context)
{
  if(context!=&poll_steps || (GetRFlags&0x200) || channel.owner!=&root) errors++;
  poll_steps++;
}
U0 (*swap)(CI386Context *old,CI386Context *next);
extern I64 DiskTest();
extern I64 FileSessionTest();
extern I64 TaskFilesTest();
extern Bool FileSessionReadFailure();
U0 Diagnostic(U32 value)
{
  I64 i; U8 digit;
  for(i=28;i>=0;i-=4) { digit=(value>>i)&15; if(digit<10) digit+='0'; else digit+='A'-10; OutU8(0xE9,digit); }
  OutU8(0xE9,32);
}
extern U0 Reader(I64 id);
extern U0 FailedReader(I64 id);
extern U0 Competitor(I64 unused);
extern U0 OnIrq(CI386IrqFrame *frame);
U0 Bind(CI386Task *task)
{
  if((GetRFlags&0x200) || !I386DataSegment(control->task_descriptor,task,sizeof(CI386Task))) errors++;
  (*control->reload)(0x18,0x20);
}
I64 Main(I64 a,I64 b)
{
  control=a; swap=b;
  return (*control->segments)(&DiskTest);
}
I64 DiskTest()
{
  U8 config,data,status,buffer[512];
  CI386AtaPoll poll;
  I64 i,round;
  cpu.addr=&cpu; cpu.scheduler=&scheduler;
  if(!I386SchedInit(&scheduler,&root,swap) ||
      !I386DataSegment(control->cpu_descriptor,&cpu,sizeof(CI386Cpu)) ||
      !I386SchedSetBind(&scheduler,&Bind) || !I386HeapInit(&heap,0x50000,32768) ||
      !I386AtaChannelInit(&channel,&scheduler,0) || !I386AtaChannelInit(&other,&scheduler,1)) return 1;
  if(!I386AtaTaskIdentify(&channel,&disks[0],0) || !I386AtaTaskIdentify(&channel,&disks[1],1) ||
      disks[0].sectors!=32768 || disks[1].sectors!=32768 || channel.owner || channel.poisoned ||
      root.io_locks || (GetRFlags&0x200)) return 2;
  if(I386AtaTaskRead(&other,&disks[0],512,buffer) || other.poisoned ||
      I386AtaTaskRead(&channel,&disks[0],-1,buffer) || I386AtaTaskRead(&channel,&disks[0],32768,buffer) ||
      I386AtaTaskRead(&channel,&disks[0],512,0) || I386AtaTaskRead(&channel,&disks[0],512,buffer,0) ||
      I386AtaTaskIdentify(&channel,&disks[0],2) || channel.poisoned || root.io_locks) return 3;
  poll.context=&poll_steps; poll.step=&PollProbe; poll.touched=FALSE;
  if(!I386AtaChannelAcquire(&channel) ||
      I386AtaWait(disks[1].io,0xFF,0x7F,TRUE,130,&poll) || poll_steps!=3 || poll.touched ||
      !I386AtaChannelRelease(&channel) || errors) return 16;
  disks[1].lba=FALSE;
  I386PicInit; control->irq->handler=&OnIrq;
  if(!I386KbcDrain || !I386KbcWrite(TRUE,0x20) || !I386KbcReadWait(&config,&status) ||
      !I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,(config|1)&~0x10) ||
      !I386KbcWrite(FALSE,0xEE)) return 4;
  if(!I386PitStart(1193)) return 5;
  for(i=0;i<2;i++) workers[i]=I386TaskSpawn(&scheduler,&heap,8192,&Reader,i);
  workers[2]=I386TaskSpawn(&scheduler,&heap,8192,&Competitor,0);
  for(i=0;i<3;i++) if(!workers[i]) return 6;
  I386PicMask(0xFFFC);
  for(round=0;round<10000;round++) {
    if(!I386SchedYield(&scheduler) || (GetRFlags&0x200)) return 7;
    if(channel.owner) {
      observed++;
      if(!channel.owner->io_locks || I386AtaTaskRead(&channel,&disks[0],512,buffer)) return 8;
      if(channel.head) queued++;
    }
    if(workers[0]->task.finished && workers[1]->task.finished && workers[2]->task.finished) break;
  }
  I386PicMask(0xFFFF);
  if(errors || completed!=2 || !observed || !queued || !competitors || !ticks || keys!=1 ||
      !timer_owned || keys_owned!=1 || channel.owner || channel.head || channel.poisoned || root.io_locks) {
    Diagnostic(errors); Diagnostic(completed); Diagnostic(observed); Diagnostic(queued);
    Diagnostic(competitors); Diagnostic(ticks); Diagnostic(keys); Diagnostic(irq_owned);
    Diagnostic(channel.poisoned); Diagnostic(timer_owned); Diagnostic(keys_owned); OutU8(0xE9,10); return 9;
  }
  for(i=0;i<3;i++) if(!I386TaskDestroy(workers[i])) return 10;
  if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 11;
  i=FileSessionTest; if(i) return i;
  i=TaskFilesTest; if(i) return i;
  //One device rejects an out-of-range command after its reported limit is forged.
  //The other drive's already queued request must fail without issuing a command.
  disks[0].sectors=32769;
  for(i=0;i<2;i++) {
    workers[i]=I386TaskSpawn(&scheduler,&heap,8192,&FailedReader,i);
    if(!workers[i]) return 12;
  }
  for(round=0;round<1000;round++) {
    I386SchedYield(&scheduler);
    if(channel.head) failed_queued++;
    if(workers[0]->task.finished && workers[1]->task.finished) break;
  }
  if(errors || failed!=2 || !failed_queued || !channel.poisoned || channel.owner || channel.head || channel.tail ||
      I386AtaTaskRead(&channel,&disks[1],512,buffer) || I386AtaTaskIdentify(&channel,&disks[0],0) ||
      I386AtaChannelClose(&channel) || I386AtaChannelInit(&channel,&scheduler,0)) return 13;
  for(i=0;i<2;i++) if(workers[i]->task.io_locks || !I386TaskDestroy(workers[i])) return 14;
  if(heap.used || heap.allocations || !I386HeapValid(&heap) || !I386AtaChannelClose(&other) ||
      !I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,config) || (GetRFlags&0x200)) return 15;
  return 0;
}
U0 Reader(I64 id)
{
  U8 buffer[514],expected;
  I64 i,round,lba;
  U32 wanted=0;
  if(id) { SetRFlags(GetRFlags|0x200); wanted=0x200; }
  buffer[0]=0xA5; buffer[513]=0x5A;
  for(round=0;round<32;round++) {
    lba=512+round*127;
    if(!I386AtaTaskRead(&channel,&disks[id],lba,buffer+1) ||
        (GetRFlags&0x200)!=wanted || I386TaskSelf->io_locks) { errors++; break; }
    for(i=0;i<512;i++) {
      expected=(i*37)^(i>>1)^((lba^(lba>>8))&255);
      if(id) expected^=0x5A;
      if(buffer[i+1]!=expected) errors++;
    }
  }
  for(i=0;i<512;i++) buffer[i+1]=(i*19)^id^0xA6;
  if(!I386AtaTaskWrite(&channel,&disks[id],5000+id,buffer+1) ||
      !I386AtaTaskFlush(&channel,&disks[id]) ||
      !I386AtaTaskRead(&channel,&disks[id],5000+id,buffer+1) ||
      (GetRFlags&0x200)!=wanted || I386TaskSelf->io_locks) errors++;
  for(i=0;i<512;i++) if(buffer[i+1]!=((i*19)^id^0xA6)(U8)) errors++;
  if(buffer[0]!=0xA5 || buffer[513]!=0x5A) errors++;
  completed++;
}
U0 FailedReader(I64 id)
{
  U8 buffer[512];
  I64 i,lba=32768;
  Bool succeeded;
  for(i=0;i<512;i++) buffer[i]=0xA5;
  if(id) { lba=512; SetRFlags(GetRFlags|0x200); }
  if(!id) succeeded=FileSessionReadFailure;
  else succeeded=I386AtaTaskRead(&channel,&disks[id],lba,buffer);
  if(succeeded || I386TaskSelf->io_locks ||
      (GetRFlags&0x200)!=(id*0x200)) errors++;
  for(i=0;i<512;i++) if(buffer[i]!=0xA5) errors++;
  failed++;
}
U0 Competitor(I64 unused)
{
  while(completed<2) { competitors++; I386SchedYield(&scheduler); }
}
U0 OnIrq(CI386IrqFrame *frame)
{
  U8 data,status;
  if(!I386PicAccept(frame->irq)) return;
  if(GetRFlags&0x200 || !(frame->eflags&0x200)) errors++;
  if(channel.owner && channel.owner->io_locks) {
    irq_owned++;
    if(frame->irq==0) timer_owned++;
    if(frame->irq==1) keys_owned++;
  }
  if(frame->irq==0) ticks++;
  else if(frame->irq==1) {
    if(!I386KbcRead(&data,&status) || data!=0xEE) errors++;
    keys++;
  } else errors++;
  I386PicEoi(frame->irq);
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Task.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/Kbc.HC"
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/AtaChannel.HC"
#include "/Kernel/I386/AtaTask.HC"

#include "T:/RedSea.HC"

#include "T:/TaskFiles.HC"
