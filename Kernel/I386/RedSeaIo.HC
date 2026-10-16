#include "/Kernel/I386/RedSea.HH"
#ifdef I386_REDSEA_TASK_LOCKS
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/AtaChannel.HH"
#endif
Bool I386RedSeaBegin(CI386RedSea *volume)
{
  if(!I386RedSeaValid(volume)) return FALSE;
  if(!volume->io) return TRUE;
  if(!volume->io->begin) return FALSE;
  if(!(*volume->io->begin)(volume->io->context))return FALSE;
  //A queued operation may resume after quarantine, deletion or root relocation.
  if(volume->backing && volume->public_drive)volume->root=volume->public_drive->root_clus;
  if(!I386RedSeaValid(volume) ||
      volume->public_drive && volume->public_drive->dv_signature!=DRV_SIGNATURE_VAL) {
    (*volume->io->end)(volume->io->context);return FALSE;
  }
#ifdef I386_REDSEA_TASK_LOCKS
  CDrv *dv=volume->public_drive;
  CI386Task *task=I386TaskSelf;
  if(dv) {
    while(Bt(&dv->locked_flags,DVlf_LOCKED) && dv->owning_task!=task) {
      if(task->task_flags&(1<<TASKf_KILL_TASK)) {
        (*volume->io->end)(volume->io->context);return FALSE;
      }
      SetRFlags(GetRFlags|0x200);I386SchedYield(task->owner);I386IrqSave;
    }
    volume->public_drive_active=TRUE;
    volume->public_drive_unlock=!Bt(&dv->locked_flags,DVlf_LOCKED);
    if(volume->public_drive_unlock) {
      LBts(&dv->locked_flags,DVlf_LOCKED);dv->owning_task=task;
    }
  }
#endif
  return TRUE;
}
Bool I386RedSeaEnd(CI386RedSea *volume)
{
  if(!volume) return FALSE;
  if(!volume->io) return TRUE;
  if(!volume->io->end) return FALSE;
#ifdef I386_REDSEA_TASK_LOCKS
  CDrv *dv=volume->public_drive;
  CI386AtaChannel *channel=volume->io->context;
  Bool active=volume->public_drive_active,unlock=volume->public_drive_unlock,result;
  //The drive operation decides whether its device is released. Conditional
  //lookup retains both locks when the caller already owns the drive, even if
  //the transaction had to reacquire the device. Whole-file calls force release.
  if(active && dv)channel->public_unlock=unlock;
  result=(*volume->io->end)(volume->io->context);
  if(result && active && dv && unlock) {
    dv->owning_task=0;LBtr(&dv->locked_flags,DVlf_LOCKED);
    volume->public_drive_unlock=FALSE;
  }
  if(result)volume->public_drive_active=FALSE;
  return result;
#else
  return (*volume->io->end)(volume->io->context);
#endif
}
Bool I386RedSeaSectorRead(CI386RedSea *volume,I64 block,U8 *buffer)
{
  if(!volume) return FALSE;
  if(!volume->io) return I386AtaRead(volume->disk,block,buffer);
  if(!volume->io->read) return FALSE;
  return (*volume->io->read)(volume->io->context,volume->disk,block,buffer);
}
Bool I386RedSeaSectorWrite(CI386RedSea *volume,I64 block,U8 *buffer)
{
  if(!volume) return FALSE;
  if(!volume->io) return I386AtaWrite(volume->disk,block,buffer);
  if(!volume->io->write) return FALSE;
  return (*volume->io->write)(volume->io->context,volume->disk,block,buffer);
}
Bool I386RedSeaFlush(CI386RedSea *volume)
{
  if(!volume) return FALSE;
  if(!volume->io) return I386AtaFlush(volume->disk);
  if(!volume->io->flush) return FALSE;
  return (*volume->io->flush)(volume->io->context,volume->disk);
}
