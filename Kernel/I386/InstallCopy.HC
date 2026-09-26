//Copy a quiescent boot disk to a blank installation target. Caller owns ATA
//channels with interrupts disabled. Publish LBA 0 only after the rest is durable.
//Return 1 on publication, 0 on a test interruption, -1 on I/O or preflight failure.
I64 I386InstallCopy(CI386Ata *source,CI386Ata *target,I64 stop_after)
{
  U8 sector[512];
  I64 lba,i;
  if(!source || !target || source->signature!=0x41543332 ||
      target->signature!=0x41543332 || !target->flush ||
      source->sectors!=target->sectors || source->sectors!=32768 ||
      stop_after<0 || stop_after>source->sectors ||
      (source->io==target->io && source->drive==target->drive) ||
      !I386AtaTransfer(target,0,sector,100000,FALSE,0)) return -1;
  for(i=0;i<512;i++) if(sector[i]) return -1;
  for(lba=1;lba<source->sectors;lba++) {
    if(!I386AtaTransfer(source,lba,sector,100000,FALSE,0) ||
        !I386AtaTransfer(target,lba,sector,100000,TRUE,0)) return -1;
    if(lba==stop_after) {
      if(!I386AtaFlushPolled(target,100000,0)) return -1;
      return 0;
    }
  }
  if(!I386AtaFlushPolled(target,100000,0)) return -1;
  if(stop_after==source->sectors) return 0;
  if(!I386AtaTransfer(source,0,sector,100000,FALSE,0) ||
      !I386AtaTransfer(target,0,sector,100000,TRUE,0) ||
      !I386AtaFlushPolled(target,100000,0)) return -1;
  return 1;
}
