//Publish only the BIOS/stage/kernel reservation after files have been installed
//through RedSea. Caller owns both ATA channels with interrupts disabled.
//Leave every target filesystem sector unchanged.
Bool I386InstallBootArea(CI386Ata *source,CI386Ata *target)
{
  U8 sector[512];
  I64 lba,i;
  if(!source || !target || source->signature!=0x41543332 ||
      target->signature!=0x41543332 || !target->flush ||
      source->sectors!=32768 || target->sectors!=32768 ||
      (source->io==target->io && source->drive==target->drive) ||
      !I386AtaTransfer(target,0,sector,100000,FALSE,0)) return FALSE;
  for(i=0;i<512;i++) if(sector[i]) return FALSE;
  for(lba=1;lba<2048;lba++) {
    if(!I386AtaTransfer(source,lba,sector,100000,FALSE,0) ||
        !I386AtaTransfer(target,lba,sector,100000,TRUE,0)) return FALSE;
  }
  if(!I386AtaFlushPolled(target,100000,0) ||
      !I386AtaTransfer(source,0,sector,100000,FALSE,0) ||
      !I386AtaTransfer(target,0,sector,100000,TRUE,0) ||
      !I386AtaFlushPolled(target,100000,0)) return FALSE;
  return TRUE;
}
