#ifndef I386_MESSAGE_INCLUDED
#define I386_MESSAGE_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
class CI386Message { I64 type,arg1,arg2; };
class CI386MsgQueue {
  CI386Scheduler *scheduler;
  CI386Task *waiter;
  Bool *read_cancelled; //Borrowed stack flag, valid only while waiter is registered.
  CI386Task *recipient;
  U32 head,count,closed;
  CI386Message messages[16];
};
public extern Bool I386MsgInit(CI386MsgQueue *queue,CI386Scheduler *scheduler);
public extern Bool I386MsgSend(CI386MsgQueue *queue,I64 type,I64 arg1,I64 arg2);
public extern I64 I386MsgRead(CI386MsgQueue *queue,CI386Message *message,U64 mask=~1,Bool wait=TRUE);
//Cancel the pending read only; preserve messages and queue open/closed state.
//The reader returns zero with its output untouched. Preserves IF.
public extern Bool I386MsgCancelRead(CI386MsgQueue *queue,CI386Task *task);
public extern Bool I386MsgClose(CI386MsgQueue *queue);
public extern Bool I386MsgAttach(CI386MsgQueue *queue,CI386Task *task);
public extern Bool I386MsgDetach(CI386MsgQueue *queue);
public extern Bool I386TaskMsgSend(CI386Task *task,I64 type,I64 arg1,I64 arg2);
#endif
