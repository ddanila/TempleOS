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
//The caller supplies a validated flat image. LBA 0 remains blank until every
//other reserved sector has been written and flushed.
Bool I386InstallBootImageArea(CI386Ata *source,CI386Ata *target,U8 *image,I64 bytes)
{
  U8 sector[512];
  I64 lba,i,offset,entry;
  if(!source || !target || !image || bytes<8 || bytes>944*512-4096 ||
      image[0]!=0xE9 || image[5] || image[6] || image[7] ||
      (entry=5+(image+1)(I32 *)[0])<8 || entry>=bytes ||
      source->signature!=0x41543332 || target->signature!=0x41543332 ||
      !target->flush || source->sectors!=32768 || target->sectors!=32768 ||
      (source->io==target->io && source->drive==target->drive) ||
      !I386AtaTransfer(target,0,sector,100000,FALSE,0)) return FALSE;
  for(i=0;i<512;i++) if(sector[i]) return FALSE;
  for(lba=1;lba<2048;lba++) {
    if(lba>=9 && lba<=944) {
      offset=(lba-9)*512;
      for(i=0;i<512;i++) {
        if(offset+i<bytes) sector[i]=image[offset+i];
        else sector[i]=0;
      }
    } else if(!I386AtaTransfer(source,lba,sector,100000,FALSE,0)) return FALSE;
    if(!I386AtaTransfer(target,lba,sector,100000,TRUE,0)) return FALSE;
  }
  if(!I386AtaFlushPolled(target,100000,0) ||
      !I386AtaTransfer(source,0,sector,100000,FALSE,0) ||
      sector[510]!=0x55 || sector[511]!=0xAA ||
      !I386AtaTransfer(target,0,sector,100000,TRUE,0) ||
      !I386AtaFlushPolled(target,100000,0)) return FALSE;
  return TRUE;
}
//Mounted-drive entry point. Borrow task volume ownership, lock the IDE channels,
//then publish from a quiescent source into a previously unbootable target.
Bool I386TaskInstallBootPayload(U8 *source,U8 *target,U8 *image,I64 bytes)
{
  CI386TaskFiles *state;
  CI386Task *task=I386TaskSelf;
  CI386FileVolumes *volumes;
  CFilePathContext paths;
  CI386RedSea *from,*to;
  I64 first,second;
  U32 flags=I386IrqSave;
  Bool result=FALSE,first_owned=FALSE,second_owned=FALSE;
  if((image && !bytes || !image && bytes) || !source || !target ||
      source[1]!=':' || target[1]!=':' ||
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
  if(image) result=I386InstallBootImageArea(from->disk,to->disk,image,bytes);
  else result=I386InstallBootArea(from->disk,to->disk);
install_boot_release:
  if(second_owned && !I386AtaChannelRelease(&file_channels[second])) result=FALSE;
  if(first_owned && !I386AtaChannelRelease(&file_channels[first])) result=FALSE;
  if(!I386TaskFilesRelease(state)) result=FALSE;
install_boot_done:
  I386IrqRestore(flags);
  return result;
}
Bool I386TaskInstallBoot(U8 *source,U8 *target)
{ return I386TaskInstallBootPayload(source,target,0,0); }
Bool I386TaskInstallBootImage(U8 *source,U8 *target,U8 *image,I64 bytes)
{ return I386TaskInstallBootPayload(source,target,image,bytes); }
