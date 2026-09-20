#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Message.HH"
#include "/Kernel/I386/Inbox.HH"
#include "/Kernel/I386/Focus.HH"
#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/KbcInput.HH"
#include "/Kernel/I386/KeyboardSetup.HH"
#include "/Kernel/I386/KeyboardEvent.HH"
#include "/Kernel/I386/Irq.HH"
extern U0 I386PicInit();
extern U0 I386PicMask(U16 mask);
extern Bool I386PicAccept(I64 irq);
extern Bool I386PicEoi(I64 irq);
class CDispatch { U0 (*handler)(CI386IrqFrame *frame); };
class CControl { CDispatch *irq; U0 (*idle)(); };
CI386Scheduler scheduler;
CI386Task tasks[3];
CI386MsgQueue messages;
CI386MsgQueue orphan;
CI386MsgQueue root_inbox;
CI386KbcInput input;
CControl *control;
U32 produced,consumed,errors;
extern U0 Broker(I64 unused);
extern U0 Consumer(I64 unused);
extern U0 EndTask();
extern U0 OnKeyboard(CI386IrqFrame *frame);
extern I64 QueueTest();
extern I64 WaitFlagsTest();
extern I64 CancelReadTest();
extern U0 EmptyWorker(I64 unused);
extern I64 InboxTest();
extern U0 InboxSelfWorker(I64 arg);
I64 Main(I64 a,I64 b)
{
  U0 (*swap)(CI386Context *old,CI386Context *next);
  I64 i,result;
  U8 *p;
  CI386Message message;
  control=a; swap=b; I386PicInit;
  if (!I386SchedInit(&scheduler,&tasks[0],swap)) return 1;
  result=QueueTest;
  if (result) return result;
  result=WaitFlagsTest;
  if(result) return result;
  result=CancelReadTest;
  if(result) return result;
  if (!I386MsgInit(&messages,&scheduler) || !I386KbcInputInit(&input,&scheduler) ||
      !I386KeyboardSetup) return 2;
  control->irq->handler=&OnKeyboard;
  I386PicInit;
  if (!I386ContextInit(&tasks[1].context,0x52000,8192,&Broker,0,&EndTask) ||
      !I386ContextInit(&tasks[2].context,0x54000,8192,&Consumer,0,&EndTask) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386SchedAdd(&scheduler,&tasks[2])) return 3;
  if (!I386MsgAttach(&messages,&tasks[2]) || I386MsgAttach(&messages,&tasks[2]) ||
      I386MsgDetach(&messages) || I386TaskMsgSend(&tasks[1],2,0,0) ||
      !I386TaskMsgSend(&tasks[2],1,0,0)) return 20;
  if (!I386MsgInit(&root_inbox,&scheduler) || !I386MsgAttach(&root_inbox,&tasks[0]) ||
      !I386FocusSet(&scheduler,&tasks[0]) || !I386FocusMsgSend(&scheduler,5,6,7) ||
      I386MsgRead(&root_inbox,&message)!=5 || message.arg1!=6 || message.arg2!=7 ||
      !I386FocusSet(&scheduler,0) || I386FocusMsgSend(&scheduler,5,6,7) ||
      !I386FocusSet(&scheduler,&tasks[2]) || !I386FocusSet(&scheduler,&tasks[2]) ||
      I386FocusSet(&scheduler,&tasks[1]) || scheduler.focus!=&tasks[2] ||
      !I386MsgClose(&root_inbox) || !I386MsgDetach(&root_inbox)) return 22;
  message.type=99;
  if (I386MsgRead(&messages,&message,~1,FALSE) || message.type!=99 || messages.count!=1 ||
      !I386SchedYield(&scheduler) || !tasks[1].blocked || !tasks[2].blocked ||
      !(tasks[2].task_flags & 1<<TASKf_AWAITING_MSG)) return 3;
  //An unrelated wake does not satisfy the consumer's message predicate.
  if (!I386SchedWake(&scheduler,&tasks[2]) || !I386SchedYield(&scheduler) ||
      tasks[2].blocked || consumed ||
      !(tasks[2].task_flags & 1<<TASKf_AWAITING_MSG)) return 4;
  for (i=0;i<9;i++) {
    p="KEY "; while (*p) OutU8(0xE9,*p++);
    OutU8(0xE9,'0'+i); OutU8(0xE9,10);
    while (consumed==i && !tasks[2].finished) {
      I386PicMask(0xFFFD);
      I386SchedIdle(&scheduler,control->idle);
      I386PicMask(0xFFFF);
      if (!I386SchedYield(&scheduler) || (GetRFlags&0x200)) return 5;
    }
    if (consumed!=i+1 || errors) return 6;
  }
  if (!tasks[2].blocked || messages.waiter!=&tasks[2] || messages.count ||
      !I386SchedYield(&scheduler)) return 8;
  if (produced!=9 || !tasks[1].finished || !tasks[2].finished ||
      messages.count || messages.waiter || !messages.closed || input.waiter ||
      I386SchedReap(&scheduler,&tasks[2]) || I386TaskMsgSend(&tasks[2],2,0,0) ||
      !I386MsgDetach(&messages) || tasks[2].messages || messages.recipient ||
      I386MsgDetach(&messages) ||
      I386FocusMsgSend(&scheduler,2,0,0) || I386SchedReap(&scheduler,&tasks[2]) ||
      I386FocusSet(&scheduler,&tasks[2]) || !I386FocusSet(&scheduler,0) ||
      !I386SchedReap(&scheduler,&tasks[1]) || !I386SchedReap(&scheduler,&tasks[2])) return 7;
  //A task that returns without closing its inbox still cannot be reaped or receive sends.
  if (!I386ContextInit(&tasks[1].context,0x52000,8192,&EmptyWorker,0,&EndTask) ||
      !I386SchedAdd(&scheduler,&tasks[1]) || !I386MsgInit(&orphan,&scheduler) ||
      !I386MsgAttach(&orphan,&tasks[1]) || !I386TaskMsgSend(&tasks[1],5,6,7) ||
      !I386SchedYield(&scheduler) || !tasks[1].finished || orphan.closed || orphan.count!=1 ||
      I386MsgSend(&orphan,5,6,7) || I386SchedReap(&scheduler,&tasks[1]) ||
      !I386MsgClose(&orphan) || !I386MsgDetach(&orphan) || orphan.count ||
      !I386SchedReap(&scheduler,&tasks[1])) return 21;
  return InboxTest;
}
U0 EmptyWorker(I64 unused) {}
I64 InboxTest()
{
  CI386Heap heap;
  CI386OwnedInbox *inbox;
  U8 *all;
  I64 i;
  if (!I386HeapInit(&heap,0x40000,8192)) return 30;
  for (i=0;i<3;i++) {
    if (!I386ContextInit(&tasks[1].context,0x52000,8192,&EmptyWorker,0,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[1])) return 31;
    all=I386HeapAlloc(&heap,8176);
    if (!all || I386InboxAlloc(&tasks[1],&heap) || tasks[1].messages ||
        heap.allocations!=1 || !I386HeapFree(&heap,all)) return 32;
    inbox=I386InboxAlloc(&tasks[1],&heap);
    if (!inbox || tasks[1].messages!=&inbox->queue || I386InboxAlloc(&tasks[1],&heap) ||
        heap.allocations!=1 || I386InboxFree(inbox) || inbox->queue.closed ||
        !I386TaskMsgSend(&tasks[1],2,0x123456789ABCDEF0,0xFEDCBA9876543210)) return 33;
    if (i==2 && !I386ContextInit(&tasks[1].context,0x52000,8192,&InboxSelfWorker,
        (inbox+0)(U64),&EndTask)) return 36;
    if (!I386SchedYield(&scheduler) || !tasks[1].finished) return 34;
    if (i<2 && (I386SchedReap(&scheduler,&tasks[1]) || !I386InboxFree(inbox))) return 37;
    if (tasks[1].messages || errors ||
        heap.allocations || heap.used || !I386HeapValid(&heap) ||
        !I386SchedReap(&scheduler,&tasks[1]) || (GetRFlags&0x200)) return 34;
  }
  if (I386InboxAlloc(0,&heap) || I386InboxAlloc(&tasks[1],&heap) || I386InboxFree(0)) return 35;
  return 0;
}
U0 InboxSelfWorker(I64 arg)
{
  SetRFlags(GetRFlags|0x200);
  if (!I386InboxFree(arg) || !(GetRFlags&0x200) || scheduler.current->messages) errors++;
}
U0 Broker(I64 unused)
{
  CI386KeyboardState state;
  CI386KeyEvent event;
  U8 data,status;
  I64 result;
  I386KeyboardReset(&state); SetRFlags(GetRFlags|0x200);
  while (produced<9) {
    if (!I386KbcInputRead(&input,&data,&status)) { errors++; break; }
    result=I386KeyboardFeed(&state,data,status,&event);
    if (result<0) { errors++; break; }
    if (result) {
      if (!I386FocusMsgSend(&scheduler,event.type,event.ch,event.scan) || !(GetRFlags&0x200)) {
        errors++; break;
      }
      produced++;
    }
  }
  if (produced==9) I386SchedYield(&scheduler);
  if (!I386MsgClose(&messages)) errors++;
}
U0 Consumer(I64 unused)
{
  CI386Message message;
  U32 expected[9];
  I64 type;
  expected[0]=0x1E; expected[1]=0x11E; expected[2]=0x1C; expected[3]=0x11C;
  expected[4]=0xC8; expected[5]=0x1C8; expected[6]=0xB7; expected[7]=0x1B7; expected[8]=0x61;
  SetRFlags(GetRFlags|0x200);
  while (type=I386MsgRead(scheduler.current->messages,&message,(1<<2)|(1<<3))) {
    if (consumed>=9 || type!=message.type || type!=2+((expected[consumed]>>8)&1) ||
        (message.arg2>>32)!=expected[consumed] || !(GetRFlags&0x200) ||
        scheduler.current->task_flags & 1<<TASKf_AWAITING_MSG) { errors++; return; }
    if (consumed<2) { if (message.arg1!='a') errors++; }
    else if (consumed<4) { if (message.arg1!=10) errors++; }
    else if (message.arg1) errors++;
    consumed++;
  }
  if (!messages.closed || consumed!=9 || !(GetRFlags&0x200) ||
      scheduler.current->task_flags & 1<<TASKf_AWAITING_MSG) errors++;
}
U0 EndTask() { I386SchedFinish(&scheduler); while (TRUE) {} }
U0 OnKeyboard(CI386IrqFrame *frame)
{
  U8 data,status;
  if (!I386PicAccept(frame->irq)) return;
  if (frame->irq!=1 || scheduler.current!=&tasks[0] || (GetRFlags&0x600) ||
      !I386KbcRead(&data,&status) || !I386KbcInputPut(&input,data,status)) errors++;
  I386PicEoi(frame->irq);
}
I64 QueueTest()
{
  CI386MsgQueue q;
  CI386Message message;
  I64 i;
  //Only the association field must initially be zero for this local record.
  q.scheduler=0;
  if (I386MsgInit(0,&scheduler) || I386MsgInit(&q,0) ||
      !I386MsgInit(&q,&scheduler) || I386MsgInit(&q,&scheduler)) return 10;
  if (I386MsgSend(&q,-1,0,0) || I386MsgSend(&q,0,0,0) || I386MsgSend(&q,64,0,0)) return 19;
  SetRFlags(GetRFlags|0x200);
  for (i=0;i<16;i++) if (!I386MsgSend(&q,2,0x1234567800000000+i,~i)) return 11;
  if (I386MsgSend(&q,2,1,2) || I386MsgSend(&q,0,1,2) || I386MsgSend(&q,64,1,2) ||
      !(GetRFlags&0x200)) return 12;
  for (i=0;i<8;i++)
    if (I386MsgRead(&q,&message)!=2 || message.arg1!=0x1234567800000000+i || message.arg2!=~i)
      return 13;
  for (i=16;i<24;i++) if (!I386MsgSend(&q,2,0x1234567800000000+i,~i)) return 14;
  for (i=8;i<24;i++)
    if (I386MsgRead(&q,&message)!=2 || message.arg1!=0x1234567800000000+i || message.arg2!=~i)
      return 15;
  if (!I386MsgSend(&q,2,1,2) || !I386MsgSend(&q,63,3,4) ||
      I386MsgRead(&q,&message,1<<63)!=63 || message.arg1!=3 || q.count) return 16;
  message.type=99; message.arg1=98; message.arg2=97;
  if (I386MsgRead(&q,&message,0) || I386MsgRead(&q,0) || I386MsgRead(&q,&message,~1,FALSE) ||
      message.type!=99 || message.arg1!=98 || message.arg2!=97 || !(GetRFlags&0x200)) return 17;
  if (!I386MsgSend(&q,3,5,6) || !I386MsgClose(&q) || I386MsgClose(&q) ||
      I386MsgSend(&q,2,1,2) || I386MsgRead(&q,&message)!=3 || message.arg2!=6 ||
      I386MsgRead(&q,&message)) return 18;
  SetRFlags(GetRFlags&~0x200);
  return 0;
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Message.HC"
#include "/Kernel/I386/WaitCancel.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Inbox.HC"
#include "/Kernel/I386/Focus.HC"
#include "/Kernel/I386/KbcQueue.HC"
#include "/Kernel/I386/KbcInput.HC"
#include "/Kernel/I386/KbcInputRead.HC"
#include "/Kernel/I386/KbcInputCancel.HC"
#include "/Kernel/I386/Kbc.HC"
#include "/Kernel/I386/KeyboardSetup.HC"
#include "/Kernel/I386/ScanSet1.HC"
#include "/Kernel/I386/ScanState.HC"
#include "/Kernel/I386/ScanChar.HC"
#include "/Kernel/I386/KeyboardEvent.HC"
#include "/Kernel/I386/PicPit.HC"
#include "T:/WaitFlags.HC"

#include "T:/CancelRead.HC"
