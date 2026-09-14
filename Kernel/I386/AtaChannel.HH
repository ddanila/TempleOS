#ifndef I386_ATA_CHANNEL_INCLUDED
#define I386_ATA_CHANNEL_INCLUDED
#include "/Kernel/I386/Scheduler.HH"
extern class CI386AtaWaiter;
class CI386AtaChannel {
  CI386Scheduler *scheduler;
  CI386Task *owner;
  CI386AtaWaiter *head,*tail;
  U32 signature,poisoned;
  U16 io,control;
};
//One stable gate per physical channel, shared by both drives. Initially zeroed.
public extern Bool I386AtaChannelInit(CI386AtaChannel *channel,CI386Scheduler *scheduler,I64 number);
//Synchronous FIFO acquisition; root may acquire an idle channel but never blocks.
//Task context only. No recursive acquisition, cancellation or hardware access here.
public extern Bool I386AtaChannelAcquire(CI386AtaChannel *channel);
public extern Bool I386AtaChannelRelease(CI386AtaChannel *channel);
//Only an idle gate can be closed. Caller must also establish hardware quiescence.
public extern Bool I386AtaChannelClose(CI386AtaChannel *channel);
#endif
