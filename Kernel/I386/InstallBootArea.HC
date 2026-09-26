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
//Mounted-drive entry point. Borrow task volume ownership, lock the IDE channels,
//then publish from a quiescent source into a previously unbootable target.
Bool I386TaskInstallBoot(U8 *source,U8 *target)
{
  CI386TaskFiles *state;
  CI386Task *task=I386TaskSelf;
  CI386FileVolumes *volumes;
  CFilePathContext paths;
  CI386RedSea *from,*to;
  I64 first,second;
  U32 flags=I386IrqSave;
  Bool result=FALSE,first_owned=FALSE,second_owned=FALSE;
  if(!source || !target || source[1]!=':' || target[1]!=':' ||
      source[2]!='/' || target[2]!='/' || source[3] || target[3] ||
      source[0]<'A' || source[0]>'Z' || target[0]<'A' || target[0]>'Z' ||
      source[0]==target[0]) goto install_boot_done;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(!state) goto install_boot_done;
  from=volumes->letter[source[0]-'A']; to=volumes->letter[target[0]-'A'];
  if(!task->owner || !I386RedSeaValid(from) || !I386RedSeaValid(to) ||
      !from->io || !to->io) goto install_boot_release;
  first=0; second=1;
  if(from->disk->io==0x170 && to->disk->io==0x170) first=1;
  else if(from->disk->io!=0x1F0 && from->disk->io!=0x170 ||
          to->disk->io!=0x1F0 && to->disk->io!=0x170) goto install_boot_release;
  if(!I386AtaChannelAcquire(&file_channels[first])) goto install_boot_release;
  first_owned=TRUE;
  if(from->disk->io!=to->disk->io) {
    if(!I386AtaChannelAcquire(&file_channels[second])) goto install_boot_release;
    second_owned=TRUE;
  }
  result=I386InstallBootArea(from->disk,to->disk);
install_boot_release:
  if(second_owned && !I386AtaChannelRelease(&file_channels[second])) result=FALSE;
  if(first_owned && !I386AtaChannelRelease(&file_channels[first])) result=FALSE;
  if(!I386TaskFilesRelease(state)) result=FALSE;
install_boot_done:
  I386IrqRestore(flags);
  return result;
}
