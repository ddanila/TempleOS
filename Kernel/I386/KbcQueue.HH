#ifndef I386_KBC_QUEUE_INCLUDED
#define I386_KBC_QUEUE_INCLUDED
class CI386KbcQueue {
  U32 head,count,dropped;
  U16 bytes[64];
};
public extern U0 I386KbcQueueInit(CI386KbcQueue *queue);
public extern Bool I386KbcQueuePut(CI386KbcQueue *queue,U8 data,U8 status);
public extern Bool I386KbcQueueGet(CI386KbcQueue *queue,U8 *data,U8 *status);
#endif
