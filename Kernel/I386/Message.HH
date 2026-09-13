#ifndef I386_MESSAGE_INCLUDED
#define I386_MESSAGE_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
class CI386Message { I64 type,arg1,arg2; };
class CI386MsgQueue {
  CI386Scheduler *scheduler;
  CI386Task *waiter;
  CI386Task *recipient;
  U32 head,count,closed;
  CI386Message messages[16];
};
public extern Bool I386MsgInit(CI386MsgQueue *queue,CI386Scheduler *scheduler);
public extern Bool I386MsgSend(CI386MsgQueue *queue,I64 type,I64 arg1,I64 arg2);
public extern I64 I386MsgRead(CI386MsgQueue *queue,CI386Message *message,U64 mask=~1,Bool wait=TRUE);
public extern Bool I386MsgClose(CI386MsgQueue *queue);
public extern Bool I386MsgAttach(CI386MsgQueue *queue,CI386Task *task);
public extern Bool I386MsgDetach(CI386MsgQueue *queue);
public extern Bool I386TaskMsgSend(CI386Task *task,I64 type,I64 arg1,I64 arg2);
#endif
