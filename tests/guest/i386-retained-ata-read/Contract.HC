extern Bool I386RawBlocks(CDrv *drive,U8 *buffer,I64 block,I64 count,Bool write);
U0 RetainedATAReadContract()
{
  CDrv *dv=Let2Drv('C');
  CBlkDev *bd=dv->bd;
  U8 expected[512],actual[514];
  I64 i,r;
  Bool unlock;
  if(bd->type!=BDT_ATA||bd->blk_size!=512)throw('ATARead',TRUE);
  if(!I386RawBlocks(dv,expected,dv->drv_offset,1,FALSE))throw('ATARead',TRUE);
  MemSet(actual,0x5A,514);
  unlock=DrvLock(dv);
  r=blkdev.read_cnt;
  ATAReadBlks(bd,actual+1,dv->drv_offset,1);
  if(blkdev.read_cnt!=r+1)throw('ATARead',TRUE);
  if(actual[0]!=0x5A||actual[513]!=0x5A)throw('ATARead',TRUE);
  for(i=0;i<512;i++)if(actual[i+1]!=expected[i])throw('ATARead',TRUE);
  //A nested lock must remain owned by the caller after the original read.
  if(DrvLock(dv))throw('ATARead',TRUE);
  if(unlock)DrvUnlock(dv);
}
RetainedATAReadContract;
