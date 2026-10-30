//Mounted RedSea ATA sector transport for future original block services.
//The caller is responsible for any higher-level cache coherence and metadata.
Bool I386TaskRawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state=0;
  CFilePathContext paths;
  CI386FileVolumes *volumes=0;
  CI386RedSea *volume=0,view;
  I64 i,letter=-1;
  Bool opened=FALSE,result=FALSE,touched=FALSE;
  if(!drive || count<0 || count>0x7FFFFF || block<0 ||
      count && (!buffer || (buffer+0)(U64)>0x100000000-count*512))goto raw_done;
  state=I386TaskFilesBorrow(I386TaskSelf,&paths,&volumes);
  if(!state)goto raw_done;
  for(i=0;i<26;i++)
    if(I386TaskFilesDrive(volumes,'A'+i)==drive) {letter='A'+i;break;}
  if(letter<0 || !(volume=I386FileVolume(volumes,letter,&view)) ||
      volume->public_drive!=drive || !volume->io || block<volume->start ||
      count>volume->sectors || block-volume->start>volume->sectors-count)
    goto raw_release;
  if(write && drive->bd->flags&BDF_READ_ONLY && !(drive->bd->flags&BDF_READ_ONLY_OVERRIDE))goto raw_release;
  if(!count) {result=TRUE;goto raw_release;}
  if(!I386RedSeaBegin(volume))goto raw_release;
  opened=TRUE;
  //A queued acquisition may resume after a drive remap or device deletion.
  if(I386TaskFilesDrive(volumes,letter)!=drive || drive->dv_signature!=DRV_SIGNATURE_VAL ||
      !drive->bd || drive->bd->bd_signature!=BD_SIGNATURE_VAL ||
      drive->bd!=volume->disk->public_device || drive->fs_type!=FSt_REDSEA ||
      drive->drv_offset!=volume->start || drive->size!=volume->sectors ||
      write && drive->bd->flags&BDF_READ_ONLY && !(drive->bd->flags&BDF_READ_ONLY_OVERRIDE))
    goto raw_release;
  result=TRUE;
  for(i=0;i<count;i++) {
    if(write) {
      touched=TRUE;
      if(!I386RedSeaSectorWrite(volume,block+i,buffer+i*512)) {result=FALSE;break;}
    } else if(!I386RedSeaSectorRead(volume,block+i,buffer+i*512)) {result=FALSE;break;}
  }
  if(touched && !I386RedSeaFlush(volume))result=FALSE;
raw_release:
  if(opened && !I386FileVolumeEnd(volumes,volume))result=FALSE;
  if(state && !I386TaskFilesRelease(state))result=FALSE;
raw_done:
  I386IrqRestore(flags);return result;
}
