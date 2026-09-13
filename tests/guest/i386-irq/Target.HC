#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Irq.HH"
#include "/Kernel/I386/Rtc.HH"
#include "/Kernel/I386/Exception.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/HeapIrq.HH"
#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/KbcQueue.HH"
extern U0 OnHeapIrq(CI386IrqFrame *frame);
extern I64 HeapInterruptTest();
extern U0 I386PicInit();
extern U0 I386PicMask(U16 mask);
extern U16 I386PicMaskGet();
extern Bool I386PicAccept(I64 irq);
extern Bool I386PicEoi(I64 irq);
extern Bool I386PitStart(I64 divisor);
extern U16 I386PitRead();
extern U0 OnIrq(CI386IrqFrame *frame);
extern U0 OnException(CI386ExceptionFrame *frame);
class CExceptionControl { U0 (*handler)(CI386ExceptionFrame *frame); };
class CIrqTestControl {
  U0 (*handler)(CI386IrqFrame *frame); U32 ticks; U32 (*flags)();
  I64 (*faults)(); CExceptionControl *exception;
  U32 vector,error,ip,resume;
};
CIrqTestControl *control;
I64 ticks,spurious,errors,expected_irq,exceptions;
CI386RtcState rtc;
CI386Heap shared_heap;
U32 heap_ticks;
U8 *irq_allocation;
CI386KbcQueue keyboard_queue;
I64 Main(I64 a,I64 b)
{
  I64 (*wait)(I64 count);
  I64 first,i,result,old_a,old_b,outer,inner;
  U8 config,data,status;
  wait=b;
  control=a; control->handler=&OnIrq;
  ticks=0xFFFFFFF0; spurious=0; errors=0;
  expected_irq=0;
  I386PicInit;
  if ((GetRFlags>>32) || (GetRFlags&0x200)) return 14;
  SetRFlags(GetRFlags|0x200|0xFFFFFFFF00000000);
  outer=I386IrqSave;
  inner=I386IrqSave;
  if (!(outer&0x200) || (inner&0x200) || (GetRFlags&0x200)) return 15;
  I386IrqRestore(inner);
  if (GetRFlags&0x200) return 16;
  I386IrqRestore(outer);
  if (!(GetRFlags&0x200)) return 17;
  I386IrqRestore(inner);
  SetRFlags(GetRFlags|0x400);
  first=GetRFlags;
  SetRFlags(GetRFlags&~0x400);
  if ((first&0x600)!=0x400 || (GetRFlags&0x600)) return 18;
  control->exception->handler=&OnException;
  if ((*control->faults)() || errors || exceptions!=3) return 13;
  if (I386PicMaskGet!=0xFFFF || I386PicAccept(-1) || I386PicAccept(16) ||
      I386PicEoi(-1) || I386PicEoi(16)) return 1;
  if (I386PitStart(0) || I386PitStart(1) || I386PitStart(65537) ||
      !I386PitStart(65536) || !I386PitStart(11932)) return 2;
  first=I386PitRead;
  for (i=0;i<10000;i++) if (I386PitRead!=first) break;
  if (i==10000 || I386PitRead>11932) return 3;
  I386PicMask(0xFFFE);
  if (I386PicMaskGet!=0xFFFE) return 4;
  result=(*wait)(32);
  I386PicMask(0xFFFF);
  if (result || errors || spurious!=2 || control->ticks<32 ||
      ticks!=0xFFFFFFF0+control->ticks || ticks<0x100000000) return 5;
  first=ticks; spurious=0;
  I386PicInit;
  if (!I386PitStart(65536)) return 6;
  I386PicMask(0xFFFE);
  result=(*wait)(4);
  I386PicMask(0xFFFF);
  if (result || errors || spurious!=2 || control->ticks<4 ||
      ticks!=first+control->ticks) return 7;
  old_a=I386RtcRead(0x0A)&0x7F; old_b=I386RtcRead(0x0B);
  if (I386RtcStart(0,10) || I386RtcStop(0) || I386RtcStop(&rtc) ||
      I386RtcStart(&rtc,-1) || I386RtcStart(&rtc,2) ||
      I386RtcStart(&rtc,16) || rtc.active ||
      (I386RtcRead(0x0A)&0x7F)!=old_a || I386RtcRead(0x0B)!=old_b) return 8;
  for (i=0;i<2;i++) {
    first=ticks; spurious=0; expected_irq=8;
    if (!I386RtcStart(&rtc,10+i) || I386RtcStart(&rtc,6) ||
        rtc.status_a!=old_a || rtc.status_b!=old_b ||
        (I386RtcRead(0x0A)&0x7F)!=(0x2A+i) ||
        I386RtcRead(0x0B)!=((old_b&~0x70)|0x40)) return 9;
    I386PicMask(0xFEFB);
    if (I386PicMaskGet!=0xFEFB) return 10;
    result=(*wait)(8);
    I386PicMask(0xFFFF);
    if (!I386RtcStop(&rtc) || rtc.active || I386RtcStop(&rtc) ||
        (I386RtcRead(0x0A)&0x7F)!=old_a || I386RtcRead(0x0B)!=old_b) return 11;
    if (result || errors || spurious!=2 || control->ticks<8 ||
        ticks!=first+control->ticks) return 12;
  }
  data=0x55; status=0xAA;
  I386KbcQueueInit(&keyboard_queue);
  SetRFlags(GetRFlags|0x200);
  for (i=0;i<64;i++)
    if (!I386KbcQueuePut(&keyboard_queue,i,i^0xE1)) return 31;
  if (I386KbcQueuePut(&keyboard_queue,99,1) || keyboard_queue.dropped!=1 ||
      !(GetRFlags&0x200)) return 32;
  keyboard_queue.dropped=0xFFFFFFFF;
  if (I386KbcQueuePut(&keyboard_queue,99,1) || keyboard_queue.dropped!=0xFFFFFFFF ||
      I386KbcQueueGet(&keyboard_queue,0,&status) ||
      I386KbcQueueGet(&keyboard_queue,&data,0) ||
      I386KbcQueueGet(&keyboard_queue,&data,&data) || keyboard_queue.count!=64) return 38;
  for (i=0;i<32;i++)
    if (!I386KbcQueueGet(&keyboard_queue,&data,&status) || data!=i || status!=(i^0xE1)) return 33;
  for (i=64;i<96;i++)
    if (!I386KbcQueuePut(&keyboard_queue,i,i^0xE1)) return 34;
  for (i=32;i<96;i++)
    if (!I386KbcQueueGet(&keyboard_queue,&data,&status) || data!=i || status!=(i^0xE1)) return 35;
  data=0x55; status=0xAA;
  if (I386KbcQueueGet(&keyboard_queue,&data,&status) || data!=0x55 || status!=0xAA ||
      I386KbcQueuePut(0,1,1) || I386KbcQueueGet(0,&data,&status) ||
      !(GetRFlags&0x200)) return 36;
  SetRFlags(GetRFlags&~0x200);
  I386KbcQueueInit(&keyboard_queue);
  if (I386KbcWrite(FALSE,0xEE,0) || I386KbcWrite(FALSE,0xEE,-1) ||
      I386KbcWrite(FALSE,0xEE,100001) || I386KbcDrain(0) ||
      I386KbcRead(0,&status) || I386KbcRead(&data,0) || I386KbcRead(&data,&data) ||
      I386KbcReadWait(&data,&status,0) || data!=0x55 || status!=0xAA) return 24;
  if (!I386KbcDrain || !I386KbcWrite(TRUE,0x20) ||
      !I386KbcReadWait(&config,&status) || (status&0xE0)) return 25;
  if (!I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,(config|1)&~0x10)) return 26;
  I386PicInit;
  expected_irq=1;
  for (i=0;i<4;i++) {
    first=ticks; spurious=0;
    if (!I386KbcWrite(FALSE,0xEE)) return 27;
    I386PicMask(0xFFFD);
    result=(*wait)(1);
    I386PicMask(0xFFFF);
    if (result || errors || spurious!=2 || control->ticks!=1 || ticks!=first+1) return 28;
    if (!I386KbcQueueGet(&keyboard_queue,&data,&status) || data!=0xEE ||
        (status&0xE0) || keyboard_queue.count || keyboard_queue.dropped ||
        (GetRFlags&0x200)) return 37;
  }
  if (!I386KbcWrite(TRUE,0x60) || !I386KbcWrite(FALSE,config) ||
      !I386KbcWrite(TRUE,0x20) || !I386KbcReadWait(&data,&status) ||
      (status&0xE0) || data!=config) return 29;
  data=0x55; status=0xAA;
  if (I386KbcReadWait(&data,&status,2) || data!=0x55 || status!=0xAA) return 30;
  return HeapInterruptTest;
}
I64 HeapInterruptTest()
{
  U8 *slots[8],*p,*guard=0x3FFF8;
  I64 i,j,round,slot,sizes[8],tag;
  for (i=0;i<8208;i++) guard[i]=0xA5;
  for (i=0;i<8;i++) slots[i]=0;
  if (!I386HeapIrqInit(&shared_heap,0x40000,8192) ||
      (GetRFlags&0x200) || !I386HeapIrqValid(&shared_heap)) return 19;
  control->handler=&OnHeapIrq;
  if (!I386PitStart(1193)) return 20;
  I386PicMask(0xFFFE);
  SetRFlags(GetRFlags|0x200);
  for (round=0;round<100000;round++) {
    slot=round%8;
    p=slots[slot];
    if (p) {
      tag=slot+1;
      for (j=0;j<sizes[slot];j++) if (p[j]!=tag) errors++;
      if (!I386HeapIrqFree(&shared_heap,p)) errors++;
    }
    sizes[slot]=(round*17)%129;
    p=I386HeapIrqAlloc(&shared_heap,sizes[slot],TRUE);
    slots[slot]=p;
    if (!p) errors++;
    else {
      if (I386HeapIrqSize(&shared_heap,p)!=sizes[slot]) errors++;
      for (j=0;j<sizes[slot];j++) {
        if (p[j]) errors++;
        p[j]=slot+1;
      }
    }
    if (!I386HeapIrqValid(&shared_heap) || !(GetRFlags&0x200) ||
        I386HeapIrqAlloc(&shared_heap,-1) ||
        I386HeapIrqFree(&shared_heap,0x40000) ||
        I386HeapIrqSize(&shared_heap,0x40000)!=-1 || !(GetRFlags&0x200)) errors++;
    if (round>=255 && heap_ticks>=16) break;
  }
  I386IrqSave;
  I386PicMask(0xFFFF);
  for (i=0;i<8;i++) if (slots[i]) {
    for (j=0;j<sizes[i];j++) if (slots[i][j]!=i+1) errors++;
    if (!I386HeapIrqFree(&shared_heap,slots[i])) errors++;
  }
  if (irq_allocation) {
    for (j=0;j<64;j++) if (irq_allocation[j]!=0xB6) errors++;
    if (!I386HeapIrqFree(&shared_heap,irq_allocation)) errors++;
  }
  irq_allocation=0;
  if (errors || heap_ticks<16 || shared_heap.used || shared_heap.allocations ||
      !I386HeapIrqValid(&shared_heap) || (GetRFlags&0x200)) return 21;
  p=I386HeapIrqAlloc(&shared_heap,8176);
  if (!p || I386HeapIrqAlloc(&shared_heap,1) ||
      !I386HeapIrqFree(&shared_heap,p) || (GetRFlags&0x200)) return 22;
  for (i=0;i<8;i++) if (guard[i]!=0xA5 || guard[8200+i]!=0xA5) return 23;
  return 0;
}
U0 OnHeapIrq(CI386IrqFrame *frame)
{
  I64 i;
  if (!I386PicAccept(frame->irq)) { errors++; return; }
  if (frame->irq || (frame->eflags&0x600)!=0x200 || (GetRFlags&0x600)) errors++;
  if (irq_allocation) {
    for (i=0;i<64;i++) if (irq_allocation[i]!=0xB6) errors++;
    if (I386HeapIrqSize(&shared_heap,irq_allocation)!=64 ||
        !I386HeapIrqFree(&shared_heap,irq_allocation)) errors++;
    irq_allocation=0;
  } else {
    irq_allocation=I386HeapIrqAlloc(&shared_heap,64,TRUE);
    if (!irq_allocation) errors++;
    else for (i=0;i<64;i++) {
      if (irq_allocation[i]) errors++;
      irq_allocation[i]=0xB6;
    }
  }
  if (!I386HeapIrqValid(&shared_heap) || (GetRFlags&0x200)) errors++;
  heap_ticks++;
  I386PicEoi(frame->irq);
}
U0 OnException(CI386ExceptionFrame *frame)
{
  if (frame->vector!=control->vector || frame->error!=control->error ||
      frame->eip!=control->ip || (frame->cs&65535)!=8 ||
      (frame->eflags&0x600)!=0x400 || (frame->ds&65535)!=16 ||
      (frame->es&65535)!=16 || (frame->fs&65535) || (frame->gs&65535) ||
      frame->saved_esp!=(frame+0)(U64)+48) errors++;
  if (frame->eax!=0x18 || frame->ebx!=0x22334455 || frame->ecx || frame->edx ||
      frame->esi!=0x55667788 || frame->edi!=0x66778899 ||
      frame->ebp!=0x778899AA || ((*control->flags)()&0x600)) errors++;
  exceptions++;
  frame->eip=control->resume;
  frame->eax=0x1234ABCD;
}
U0 OnIrq(CI386IrqFrame *frame)
{
  U8 data,status;
  if (!I386PicAccept(frame->irq)) { spurious++; return; }
  if (frame->irq==8 && (I386RtcAck&0xC0)!=0xC0) errors++;
  if (frame->irq==1) {
    if (!I386KbcRead(&data,&status) || data!=0xEE || (status&0xE0)) errors++;
    else if (!I386KbcQueuePut(&keyboard_queue,data,status)) errors++;
  }
  if (frame->irq!=expected_irq || (frame->cs&65535)!=8 || (frame->eflags&0x600)!=0x600 ||
      (frame->ds&65535)!=16 || (frame->es&65535)!=16 ||
      (frame->fs&65535) || (frame->gs&65535) ||
      frame->saved_esp!=(frame+0)(U64)+48) errors++;
  if (frame->eax!=0x11223344 || frame->ebx!=0x22334455 || frame->ecx!=0x33445566 ||
      frame->edx!=0x44556677 || frame->esi!=0x55667788 || frame->edi!=0x66778899 ||
      frame->ebp!=0x778899AA) errors++;
  if ((GetRFlags|(*control->flags)())&0x600) errors++;
  ticks++; control->ticks++;
  I386PicEoi(frame->irq);
}
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/Rtc.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/HeapIrq.HC"
#include "/Kernel/I386/Kbc.HC"
#include "/Kernel/I386/KbcQueue.HC"
