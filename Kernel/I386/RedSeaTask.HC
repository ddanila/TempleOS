#include "/Kernel/I386/RedSeaTask.HH"
#include "/Kernel/I386/Cpu.HH"
I64 i386_redsea_fail_operation,i386_redsea_fail_after,i386_redsea_fail_count;
Bool i386_redsea_fail_fired;
U0 I386RedSeaTaskFailArm(I64 operation,I64 fail_after)
{
  i386_redsea_fail_operation=operation;
  i386_redsea_fail_after=fail_after;
  i386_redsea_fail_count=0;
  i386_redsea_fail_fired=FALSE;
}
Bool I386RedSeaTaskFail(I64 operation)
{
  if(i386_redsea_fail_operation==operation && i386_redsea_fail_after>0 &&
     ++i386_redsea_fail_count==i386_redsea_fail_after) {
    i386_redsea_fail_fired=TRUE;
    return TRUE;
  }
  return FALSE;
}
Bool I386RedSeaTaskBegin(U8 *context) { return I386AtaChannelAcquire(context); }
Bool I386RedSeaTaskEnd(U8 *context) { return I386AtaChannelRelease(context); }
Bool I386RedSeaTaskRead(U8 *context,CI386Ata *disk,I64 block,U8 *buffer)
{
  return I386AtaTaskOwned(context,disk,block,buffer,100000,1);
}
Bool I386RedSeaTaskWrite(U8 *context,CI386Ata *disk,I64 block,U8 *buffer)
{
  if(I386RedSeaTaskFail(2)) return FALSE;
  return I386AtaTaskOwned(context,disk,block,buffer,100000,2);
}
Bool I386RedSeaTaskFlush(U8 *context,CI386Ata *disk)
{
  if(I386RedSeaTaskFail(3)) return FALSE;
  return I386AtaTaskOwned(context,disk,0,0,100000,3);
}
Bool I386RedSeaTaskIdle(CI386AtaChannel *channel)
{
  return !(GetRFlags&0x200) && channel && channel->signature==0x41434831 &&
    !channel->poisoned && !channel->owner && !channel->head && !channel->tail &&
    channel->scheduler && channel->scheduler->current==channel->scheduler->root;
}
Bool I386RedSeaTaskIoInit(CI386RedSeaIo *io,CI386AtaChannel *channel)
{
  if(!io || !I386RedSeaTaskIdle(channel) || io->context || io->begin || io->end ||
      io->read || io->write || io->flush) return FALSE;
  io->context=channel; io->begin=&I386RedSeaTaskBegin; io->end=&I386RedSeaTaskEnd;
  io->read=&I386RedSeaTaskRead; io->write=&I386RedSeaTaskWrite; io->flush=&I386RedSeaTaskFlush;
  return TRUE;
}
Bool I386RedSeaTaskBind(CI386RedSea *volume,CI386RedSeaIo *io)
{
  CI386AtaChannel *channel;
  if(!io || !I386RedSeaValid(volume) || volume->io || !(channel=io->context) ||
      !I386RedSeaTaskIdle(channel) || volume->disk->io!=channel->io || volume->disk->control!=channel->control ||
      io->begin!=&I386RedSeaTaskBegin || io->end!=&I386RedSeaTaskEnd ||
      io->read!=&I386RedSeaTaskRead || io->write!=&I386RedSeaTaskWrite || io->flush!=&I386RedSeaTaskFlush) return FALSE;
  volume->io=io; return TRUE;
}
