//Copy a quiescent boot disk to a blank installation target. Caller owns ATA
//channels with interrupts disabled. Publish LBA 0 only after the rest is durable.
Bool I386InstallCopy(CI386Ata *source,CI386Ata *target)
{
  U8 sector[512];
  I64 lba,i;
  if(!source || !target || source->signature!=0x41543332 ||
      target->signature!=0x41543332 || !target->flush ||
      source->sectors!=target->sectors || source->sectors!=32768 ||
      (source->io==target->io && source->drive==target->drive) ||
      !I386AtaTransfer(target,0,sector,100000,FALSE,0)) return FALSE;
  for(i=0;i<512;i++) if(sector[i]) return FALSE;
  for(lba=1;lba<source->sectors;lba++) {
    if(!I386AtaTransfer(source,lba,sector,100000,FALSE,0) ||
        !I386AtaTransfer(target,lba,sector,100000,TRUE,0)) return FALSE;
  }
  if(!I386AtaFlushPolled(target,100000,0) ||
      !I386AtaTransfer(source,0,sector,100000,FALSE,0) ||
      !I386AtaTransfer(target,0,sector,100000,TRUE,0) ||
      !I386AtaFlushPolled(target,100000,0)) return FALSE;
  return TRUE;
}
