#include "/Kernel/I386/AtaTask.HH"
#include "/Kernel/I386/Cpu.HH"
U0 I386AtaTaskPoll(U8 *context)
{//The protocol calls at the start of a wait and every 64 unsuccessful polls.
  CI386AtaChannel *channel=context;
  CI386Scheduler *scheduler=channel->scheduler;
  if(scheduler->current==scheduler->root) return;
  SetRFlags(GetRFlags|0x200);
  I386SchedYield(scheduler);
  I386IrqSave;
}
Bool I386AtaTaskOwned(CI386AtaChannel *channel,CI386Ata *disk,I64 lba,U8 *buffer,I64 polls,I64 operation)
{
  CI386AtaPoll poll;
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  I64 number;
  if(!channel || !disk || polls<1 || polls>100000 || operation<0 || operation>3) goto request_done;
  if(operation && (disk->io!=channel->io || disk->control!=channel->control)) goto request_done;
  if(channel->signature!=0x41434831 || channel->poisoned || !channel->scheduler ||
      !channel->owner || channel->owner!=channel->scheduler->current || !channel->owner->io_locks) goto request_done;
  poll.context=channel; poll.step=&I386AtaTaskPoll; poll.touched=FALSE;
  number=0; if(channel->io==0x170) number=1;
  switch(operation) {
    case 0: result=I386AtaIdentifyPolled(disk,number,lba,polls,&poll); break;
    case 1: result=I386AtaTransfer(disk,lba,buffer,polls,FALSE,&poll); break;
    case 2: result=I386AtaTransfer(disk,lba,buffer,polls,TRUE,&poll); break;
    case 3: result=I386AtaFlushPolled(disk,polls,&poll); break;
  }
  //A failed touched transaction may still be active. Fail closed until reboot;
  //future reset/re-identification must quiesce both drives before clearing poison.
  if(!result && poll.touched) channel->poisoned=TRUE;
request_done:
  I386IrqRestore(flags); return result;
}
Bool I386AtaTaskRequest(CI386AtaChannel *channel,CI386Ata *disk,I64 lba,U8 *buffer,I64 polls,I64 operation)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(!channel || !disk || polls<1 || polls>100000 || operation<0 || operation>3 ||
      (operation && (disk->io!=channel->io || disk->control!=channel->control))) goto request_done;
  if(!I386AtaChannelAcquire(channel)) goto request_done;
  result=I386AtaTaskOwned(channel,disk,lba,buffer,polls,operation);
  if(!I386AtaChannelRelease(channel)) result=FALSE;
request_done:
  I386IrqRestore(flags); return result;
}
Bool I386AtaTaskIdentify(CI386AtaChannel *channel,CI386Ata *disk,I64 drive,I64 polls=100000)
{
  return I386AtaTaskRequest(channel,disk,drive,0,polls,0);
}
Bool I386AtaTaskRead(CI386AtaChannel *channel,CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000)
{
  return I386AtaTaskRequest(channel,disk,lba,buffer,polls,1);
}
Bool I386AtaTaskWrite(CI386AtaChannel *channel,CI386Ata *disk,I64 lba,U8 *buffer,I64 polls=100000)
{
  return I386AtaTaskRequest(channel,disk,lba,buffer,polls,2);
}
Bool I386AtaTaskFlush(CI386AtaChannel *channel,CI386Ata *disk,I64 polls=100000)
{
  return I386AtaTaskRequest(channel,disk,0,0,polls,3);
}
