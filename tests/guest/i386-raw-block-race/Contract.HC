public extern Bool I386RawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write);
CDrv *RBDrive;
U8 *RBBuffer;
I64 RBBlock,RBStage,RBResult;
U0 RBChild(U8 *unused)
{
  RBStage=1;
  RBResult=I386RawBlocks(RBDrive,RBBuffer,RBBlock,1,FALSE);
  RBStage=2;
}
Bool RBWait(I64 stage)
{
  I64 end=cnts.jiffies+2000;
  while(RBStage<stage && cnts.jiffies<end)Yield;
  return RBStage>=stage;
}
Bool RawBlockRace()
{
  CDirEntry de;CTask *child=NULL;I64 i,old_size;
  Bool held=FALSE,ok=FALSE;
  RBDrive=Fs->cur_dv;RBBuffer=MAlloc(512);
  if(!FileWrite("C:/raw-race.DATA",RBBuffer,512) ||
      !FileFind("C:/raw-race.DATA",&de,FUF_JUST_FILES))goto race_done;
  RBBlock=de.clus;RBStage=0;RBResult=FALSE;
  old_size=RBDrive->size;
  held=BlkDevLock(RBDrive->bd);
  child=Spawn(&RBChild,NULL,"Raw block waiter",-1,Fs);
  ok=held && child && RBWait(1);
  for(i=0;i<20;i++)Yield;
  ok=ok && RBStage==1;
  RBDrive->size=old_size-1;
  if(held) {BlkDevUnlock(RBDrive->bd);held=FALSE;}
  ok=ok && RBWait(2) && !RBResult;
  RBDrive->size=old_size;
  if(child)while(TaskValidate(child))Yield;
  ok=ok && I386RawBlocks(RBDrive,RBBuffer,RBBlock,1,FALSE);
  Free(de.full_name);
race_done:
  if(held)BlkDevUnlock(RBDrive->bd);
  Free(RBBuffer);return ok;
}
