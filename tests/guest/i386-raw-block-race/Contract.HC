public extern Bool I386RawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write);
CDrv *RBDrive;
U8 *RBBuffer;
I64 RBBlock,RBStage,RBResult;
Bool RBWrite;
U0 RBChild(U8 *unused)
{
  RBStage=1;
  RBResult=I386RawBlocks(RBDrive,RBBuffer,RBBlock,1,RBWrite);
  RBStage=2;
}
Bool RBWait(I64 stage)
{
  I64 end=cnts.jiffies+2000;
  while(RBStage<stage && cnts.jiffies<end)Yield;
  return RBStage>=stage;
}
Bool RawBlockRaceCase(I64 which)
{
  CBlkDev *bd=RBDrive->bd;
  CTask *child=NULL;
  I64 i,old_size=RBDrive->size,old_offset=RBDrive->drv_offset;
  I64 old_fs=RBDrive->fs_type,old_flags=bd->flags;
  Bool held=FALSE,ok=FALSE;
  RBStage=0;RBResult=FALSE;RBWrite=which==3;
  held=BlkDevLock(bd);
  child=Spawn(&RBChild,NULL,"Raw block waiter",-1,Fs);
  ok=held && child && RBWait(1);
  for(i=0;i<20;i++)Yield;
  ok=ok && RBStage==1;
  switch(which) {
    case 0: RBDrive->size=old_size-1;break;
    case 1: RBDrive->drv_offset=old_offset+1;break;
    case 2: RBDrive->fs_type=FSt_NULL;break;
    case 3: bd->flags=old_flags|BDF_READ_ONLY;bd->flags&=~BDF_READ_ONLY_OVERRIDE;break;
  }
  if(held) {BlkDevUnlock(bd);held=FALSE;}
  ok=ok && RBWait(2) && !RBResult;
  RBDrive->size=old_size;RBDrive->drv_offset=old_offset;
  RBDrive->fs_type=old_fs;bd->flags=old_flags;
  if(child)while(TaskValidate(child))Yield;
  return ok && I386RawBlocks(RBDrive,RBBuffer,RBBlock,1,FALSE);
}
Bool RawBlockRace()
{
  CDirEntry de;I64 i;Bool ok=TRUE;
  RBDrive=Fs->cur_dv;RBBuffer=MAlloc(512);
  if(!FileWrite("C:/raw-race.DATA",RBBuffer,512) ||
      !FileFind("C:/raw-race.DATA",&de,FUF_JUST_FILES)) {Free(RBBuffer);return FALSE;}
  RBBlock=de.clus;
  if(!I386RawBlocks(RBDrive,RBBuffer,RBBlock,1,FALSE))ok=FALSE;
  for(i=0;i<4;i++)if(!RawBlockRaceCase(i))ok=FALSE;
  Free(de.full_name);Free(RBBuffer);return ok;
}
